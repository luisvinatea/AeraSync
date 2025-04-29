#!/bin/bash

# Set locale to prevent potential issues
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

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

    # Clone the stable Flutter repository instead of downloading a specific archive
    echo "Cloning Flutter stable repository..."
    git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /opt/flutter

    # Add Flutter to PATH for this script's execution
    export PATH="$PATH:/opt/flutter/bin"
else
    echo "Flutter found in PATH."
fi

# Verify Flutter installation
# Run flutter doctor to download Dart SDK etc.
echo "Running flutter doctor..."
# Accept licenses automatically if prompted (might not be needed but good practice)
yes | flutter doctor --android-licenses || true 
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
