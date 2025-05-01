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

# Build the Flutter web app in release mode
# Removed the --web-renderer flag as it's not supported in your Flutter version
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
echo "/* /index.html 200" > public/_redirects

echo "Build process completed successfully!"