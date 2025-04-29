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
    echo "Dependencies installed successfully."

    # Add a check point before cloning
    echo "CHECKPOINT: Proceeding to clone Flutter..."

    # Clone the stable Flutter repository
    echo "Cloning Flutter stable repository..."
    git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /opt/flutter
    echo "Flutter cloned successfully."

    # Add Flutter to PATH for this script's execution
    export PATH="$PATH:/opt/flutter/bin"
    echo "Flutter added to PATH."
else
    echo "Flutter found in PATH."
fi

# Verify Flutter installation
echo "CHECKPOINT: Running flutter doctor..."
# Run flutter doctor to download Dart SDK etc.
# Accept licenses automatically if prompted (might not be needed but good practice)
yes | flutter doctor --android-licenses || true 
flutter doctor
echo "CHECKPOINT: flutter doctor finished."

# Get dependencies
echo "CHECKPOINT: Running flutter pub get..."
flutter pub get
echo "CHECKPOINT: flutter pub get finished."

# Generate localization files explicitly
echo "CHECKPOINT: Running flutter gen-l10n..."
flutter gen-l10n
echo "CHECKPOINT: flutter gen-l10n finished."

# Build the web application
echo "CHECKPOINT: Running flutter build web..."
# Ensure API_URL is defined for the build
flutter build web --release --dart-define=API_URL=/api
echo "CHECKPOINT: flutter build web finished."

echo "--- Frontend Build Script Finished ---"
# Vercel expects the output directory specified in vercel.json (build/web)
