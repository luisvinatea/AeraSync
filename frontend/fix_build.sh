#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Fixing AeraSync build issues..."
echo "=============================="

# Check if Flutter is in PATH
if ! command -v flutter &>/dev/null; then
    echo "Flutter not found in PATH, attempting to install..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$PWD/flutter/bin"
    flutter precache --web
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build

# Ensure proper l10n config
echo "Setting up localization configuration..."
cat >l10n.yaml <<EOF
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
EOF

# Ensure Flutter dependencies are up-to-date
echo "Updating dependencies..."
flutter pub get

# Generate localization files explicitly
echo "Generating localization files..."
flutter gen-l10n

# Build the app with optimizations
echo "Building web app with optimizations..."
flutter build web --release

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
cp -R assets/fonts/* public/fonts/ 2>/dev/null || echo "No custom fonts to copy"

echo "Build completed successfully!"

# Create redirect file for SPA routing
echo "Creating redirect file for SPA routing..."
echo "/* /index.html 200" >public/_redirects

# Copy custom fonts to public folder if needed
echo "Ensuring fonts are available..."
mkdir -p public/fonts
cp -R assets/fonts/* public/fonts/ 2>/dev/null || echo "No custom fonts to copy"

echo "Build completed successfully!"
