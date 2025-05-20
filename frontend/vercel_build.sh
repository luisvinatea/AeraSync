#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "AeraSync Vercel Build Script"
echo "=========================="

# Check if Flutter is in PATH
if ! command -v flutter &>/dev/null; then
    echo "Flutter not found in PATH, installing..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$PWD/flutter/bin"
    flutter precache --web
fi

echo "Flutter version:"
flutter --version

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build

# Ensure proper l10n config for Vercel
echo "Setting up Vercel-specific configuration..."
cat >l10n.yaml <<EOF
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
EOF

# Special handling for Vercel environment
echo "Checking for Vercel environment..."
if [ -n "$VERCEL" ] || [ -n "$VERCEL_ENV" ]; then
    echo "Running in Vercel environment, applying special fixes..."

    # Create local re-export for AppLocalizations
    cat >lib/l10n/app_localizations_export.dart <<EOF
// This file ensures AppLocalizations is available for import
// within the Vercel build environment
export 'package:flutter_gen/gen_l10n/app_localizations.dart';
EOF

    # Create a patch for all files that import app_localizations
    find lib -type f -name "*.dart" -exec grep -l "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" {} \; | xargs -I{} sed -i 's/import .package:flutter_gen\/gen_l10n\/app_localizations.dart.;/import ..\/l10n\/app_localizations_export.dart.;/g' {}
fi

# Ensure Flutter dependencies are up-to-date
echo "Updating dependencies..."
flutter pub get

# Generate localization files
echo "Generating localization files..."
flutter gen-l10n

# Make sure localizations were generated
if [ ! -f ".dart_tool/flutter_gen/gen_l10n/app_localizations.dart" ]; then
    echo "Error: Localization files not generated. Build will likely fail."
    exit 1
fi

# Build the web app
echo "Building web app for production..."
flutter build web --release

# Check if the build was successful
if [ ! -d "build/web" ]; then
    echo "Error: Build failed."
    exit 1
fi

# Copy to public directory for Vercel
echo "Preparing for deployment..."
mkdir -p public
cp -R build/web/* public/

echo "Build completed successfully!"
