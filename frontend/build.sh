#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting build process..."

# Check if Flutter is in PATH
if ! command -v flutter &> /dev/null; then
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

# Configure web-renderer to use CanvasKit (more stable)
echo "Building Flutter web app with CanvasKit renderer..."
flutter build web --release --web-renderer canvaskit

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
echo "/* /index.html 200" > public/_redirects

# Ensure CORS headers are set for service worker
echo "Adding CORS headers to flutter_service_worker.js..."
cat > public/cors-headers.js << EOL
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
    cat public/cors-headers.js public/flutter_service_worker.js > public/temp_service_worker.js
    mv public/temp_service_worker.js public/flutter_service_worker.js
    rm public/cors-headers.js
fi

# Fix base href in index.html if needed
echo "Ensuring base href is set correctly..."
sed -i 's|<base href=".*">|<base href="/">|g' public/index.html

echo "Setting window.flutterWebRenderer in index.html..."
sed -i 's|window.flutterWebRenderer = ".*";|window.flutterWebRenderer = "canvaskit";|g' public/index.html 2>/dev/null || true

echo "Build process completed successfully!"