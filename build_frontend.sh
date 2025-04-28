#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Frontend Build Script ---"

# Check if Flutter is already installed/available in the PATH
if ! command -v flutter &>/dev/null; then
    echo "Flutter not found, installing..."
    # Using apt-get as Vercel build environment is likely Debian-based
    # Install necessary dependencies for Flutter SDK download and execution
    apt-get update && apt-get install -y --no-install-recommends curl git unzip xz-utils libglu1-mesa wget
    # Download specific Flutter version matching your project (adjust if needed)
    FLUTTER_VERSION="3.29.2"
    FLUTTER_CHANNEL="stable"
    FLUTTER_ARCH="linux-x64" # Assuming Vercel uses x64 Linux
    wget "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/${FLUTTER_ARCH}/flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
    tar xf "flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -C /opt/
    # Add Flutter to PATH for this script's execution
    export PATH="$PATH:/opt/flutter/bin"
    # Clean up downloaded archive
    rm "flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
else
    echo "Flutter found in PATH."
fi

# Verify Flutter installation
echo "Running flutter doctor..."
flutter doctor

# Get dependencies
echo "Running flutter pub get..."
flutter pub get

# Build the web application
echo "Running flutter build web..."
# Ensure API_URL is defined for the build
flutter build web --release --dart-define=API_URL=/api

echo "--- Frontend Build Script Finished ---"
# Vercel expects the output directory specified in vercel.json (build/web)
