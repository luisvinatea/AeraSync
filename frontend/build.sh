#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Building AeraSync for web deployment..."
echo "-------------------------------------"
echo "Build optimizations enabled:"
echo "- Service worker generation"
echo "- CanvasKit renderer"
echo "- Tree-shaking icons optimized"

# Check if Flutter is in PATH
if ! command -v flutter &>/dev/null; then
  echo "Flutter not found in PATH, attempting to install..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:$PWD/flutter/bin"
  flutter precache --web
fi

echo "Flutter version:"
flutter --version

# Ensure Flutter dependencies are up-to-date
echo "Updating dependencies..."
flutter pub get

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build

# Build the app with optimizations
echo "Building web app with optimizations..."
flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ \
  --pwa-strategy offline-first

# Check if the build was successful
if [ ! -d "build/web" ]; then
  echo "Error: build/web directory not found. Build failed."
  exit 1
fi

# Copy appropriate web files to public directory
echo "Copying build files to public folder..."
mkdir -p public
cp -R build/web/* public/

# Create redirect file for SPA routing
echo "Creating redirect file for SPA routing..."
echo "/* /index.html 200" > public/_redirects

# Copy custom fonts to public folder if needed
echo "Ensuring fonts are available..."
mkdir -p public/fonts
cp -R web/fonts/* public/fonts/ 2>/dev/null || echo "No custom fonts to copy"

echo "Build complete! Files are ready in 'public' directory."
