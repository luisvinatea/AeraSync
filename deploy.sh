#!/bin/bash
# Simplified deploy.sh for local testing of AeraSync
set -e

echo "Running local build script from: $(pwd)"

# Check Flutter version
echo "Checking Flutter version..."
flutter --version

# Clean and get dependencies
echo "Cleaning previous builds..."
flutter clean
rm -f pubspec.lock
echo "Getting dependencies..."
flutter pub get

# Generate localization files
echo "Generating localization files..."
flutter gen-l10n

# Run tests
echo "Running tests..."
flutter test

# Build web
echo "Building web release..."
flutter build web --dart-define=flutter.web.renderer=canvaskit --release --base-href=/AeraSync/

echo "Build completed. Serve locally with: flutter run -d web-server --web-port 8080"