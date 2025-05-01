#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting build process..."

# Check if Flutter is in PATH
if ! command -v flutter &>/dev/null; then
  echo "Flutter not found in PATH, attempting to install..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:$PWD/flutter/bin"
  flutter precache --web
fi

echo "Flutter version:"
flutter --version

# First, ensure localization files are generated
echo "Generating localization files..."
flutter gen-l10n

# Build the Flutter web app (renderer is configured in index.html)
echo "Building Flutter web app..."
flutter build web --release

# Check if the build was successful
if [ ! -d "build/web" ]; then
  echo "Error: build/web directory not found. Build failed."
  exit 1
fi

# Copy build output to the public directory that Vercel expects
echo "Copying build files to public directory..."
mkdir -p public
cp -r build/web/* public/

# Create a Vercel-specific _redirects file for additional fallback
echo "Creating _redirects file..."
echo "/* /index.html 200" >public/_redirects

# Ensure Flutter initialization in index.html uses the correct API
echo "Ensuring Flutter initialization is properly configured..."
if grep -q "flutter.loader.load(" public/index.html; then
  echo "Fixing Flutter initialization API in index.html..."
  # Create a temporary file with correct initialization code
  cat >flutter-init-fix.js <<EOL
  <script>
    window.addEventListener('load', function() {
      // Initialize Flutter web with current API
      let targetDiv = document.querySelector('#flutter-target');
      let loadingScreen = document.getElementById('loading-screen');
      
      // Register Service Worker for PWA capabilities
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/flutter_service_worker.js')
          .then(function(registration) {
            console.log('Service Worker registered with scope: ', registration.scope);
          })
          .catch(function(error) {
            console.log('Service Worker registration failed: ', error);
          });
      }

      // Initialize Flutter app using the correct API
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine({
            renderer: "canvaskit",
            canvasKitBaseUrl: "/canvaskit/",
          }).then(function(appRunner) {
            appRunner.runApp();
            // Remove loading screen once Flutter app is ready
            if (loadingScreen) {
              loadingScreen.style.opacity = '0';
              setTimeout(function() {
                loadingScreen.style.display = 'none';
              }, 500);
            }
          });
        }
      });
    });
  </script>
EOL

  # Replace the old Flutter initialization with the new one
  sed -i '/flutter\.loader\.load(/,/<\/script>/d' public/index.html
  sed -i '/<body>/a <div id="loading-screen" role="status" aria-label="Loading AeraSync application">\n  <div class="wave-overlay"></div>\n  <div class="loading">\n    <picture>\n      <source srcset="/icons/aerasync.webp" type="image/webp">\n      <img src="/icons/aerasync.webp" alt="AeraSync Logo - A stylized wave representing water and aeration" class="app-logo" loading="lazy">\n    </picture>\n    <h1 lang="en">AeraSync</h1>\n    <div class="spinner" aria-hidden="true"></div>\n  </div>\n</div>\n\n<div id="flutter-target"></div>' public/index.html

  # Add the loading screen styles if not present
  if ! grep -q "#loading-screen" public/index.html; then
    sed -i '/<style>/a /* Ensure loading screen styles are defined inline */\n#loading-screen {\n  position: fixed;\n  top: 0;\n  left: 0;\n  width: 100%;\n  height: 100%;\n  background-color: #ffffff;\n  display: flex;\n  justify-content: center;\n  align-items: center;\n  z-index: 9999;\n  transition: opacity 0.5s ease-out;\n}\n.loading {\n  text-align: center;\n}\n.spinner {\n  border: 4px solid rgba(0, 0, 0, 0.1);\n  width: 36px;\n  height: 36px;\n  border-radius: 50%;\n  border-left-color: #1E40AF;\n  animation: spin 1s linear infinite;\n  margin: 0 auto;\n}\n@keyframes spin {\n  0% { transform: rotate(0deg); }\n  100% { transform: rotate(360deg); }\n}\n.wave-overlay {\n  position: absolute;\n  bottom: 0;\n  left: 0;\n  width: 100%;\n  height: 30%;\n  background: linear-gradient(0deg, rgba(96, 165, 250, 0.2) 0%, rgba(255, 255, 255, 0) 100%);\n}\n#flutter-target {\n  width: 100vw;\n  height: 100vh;\n  overflow: hidden;\n}\n.app-logo {\n  width: 200px;\n  height: auto;\n  margin-bottom: 20px;\n}' public/index.html
  fi

  # Add the new initialization script near the end of the body
  sed -i '/<\/body>/i <script src="flutter-init-fix.js"></script>' public/index.html
  cp flutter-init-fix.js public/
  rm flutter-init-fix.js
fi

# Ensure the Flutter buildConfig is set correctly in index.html
if ! grep -q "window._flutter" public/index.html || ! grep -q "canvasKitBaseUrl" public/index.html; then
  echo "Adding Flutter buildConfig..."
  sed -i '/<head>/a <!-- Preload Flutter scripts -->\n<script>\n// Required buildConfig for Flutter web initialization\nwindow._flutter = {\n  loader: {},\n  buildConfig: {\n    renderer: "canvaskit",\n    canvasKitBaseUrl: "/canvaskit/"\n  }\n};</script>' public/index.html
fi

# Fix base href in index.html if needed
echo "Ensuring base href is set correctly..."
sed -i 's|<base href=".*">|<base href="/">|g' public/index.html

echo "Build process completed successfully!"
