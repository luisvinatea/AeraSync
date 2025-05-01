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

# Ensure CORS headers are set for service worker
echo "Adding CORS headers to flutter_service_worker.js..."
cat >public/cors-headers.js <<EOL
// Add CORS headers to ensure service worker loads properly
self.addEventListener('install', function(e) {
  self.skipWaiting();
});
self.addEventListener('activate', function(e) {
  self.clients.claim();
});
EOL

# Prepend the CORS headers to the service worker
if [ -f "public/flutter_service_worker.js" ]; then
  cat public/cors-headers.js public/flutter_service_worker.js >public/temp_service_worker.js
  mv public/temp_service_worker.js public/flutter_service_worker.js
  rm public/cors-headers.js
fi

# Ensure Flutter buildConfig is set correctly in index.html
echo "Ensuring Flutter initialization is properly configured..."
cat >flutter-init-script.js <<EOL
// Required buildConfig for Flutter web initialization
window._flutter = {
  loader: {},
  buildConfig: {
    renderer: "canvaskit",
    canvasKitBaseUrl: "/canvaskit/"
  }
};
EOL

# Insert the Flutter buildConfig script if not already present
if ! grep -q "window._flutter" public/index.html; then
  sed -i '/<link rel="preload" href="flutter.js"/i <!-- Preload Flutter scripts -->\n<script>\n// Required buildConfig for Flutter web initialization\nwindow._flutter = {\n  loader: {},\n  buildConfig: {\n    renderer: "canvaskit",\n    canvasKitBaseUrl: "/canvaskit/"\n  }\n};\n</script>' public/index.html
fi

# Add mobile-web-app-capable meta tag if not already present
if ! grep -q "mobile-web-app-capable" public/index.html; then
  sed -i '/<meta name="apple-mobile-web-app-capable"/a <meta name="mobile-web-app-capable" content="yes">' public/index.html
fi

# Fix base href in index.html if needed
echo "Ensuring base href is set correctly..."
sed -i 's|<base href=".*">|<base href="/">|g' public/index.html

echo "Build process completed successfully!"
