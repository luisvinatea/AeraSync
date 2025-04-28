#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Frontend Build Script ---"

# Check if Flutter is already installed/available in the PATH
if ! command -v flutter &> /dev/null
then
    echo "Flutter not found, installing..."
    # Use yum (Amazon Linux 2 package manager) instead of apt-get
    # Install necessary dependencies for Flutter SDK download and execution
    # Update yum cache and install dependencies
    yum update -y
    # Add --allowerasing to handle potential conflicts like curl vs curl-minimal
    yum install -y --allowerasing git tar xz unzip mesa-libGLU curl which

    # Download specific Flutter version matching your project (adjust if needed)
    FLUTTER_VERSION="3.29.2"
    FLUTTER_CHANNEL="stable"
    FLUTTER_ARCH="linux-x64" # Assuming Vercel uses x64 Linux
    # Use curl instead of wget
    curl -o "flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/${FLUTTER_ARCH}/flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
    
    # Create directory if it doesn't exist
    mkdir -p /opt/flutter
    # Extract to /opt/flutter, stripping the top-level directory
    tar xf "flutter_${FLUTTER_ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -C /opt/ --strip-components=1
    
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
