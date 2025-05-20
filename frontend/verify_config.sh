#!/bin/bash

# This script verifies the project configuration before deployment

echo "Verifying AeraSync configuration..."
echo "=================================="

# Check l10n.yaml file
if [ -f "l10n.yaml" ]; then
    echo "✅ l10n.yaml exists"
    cat l10n.yaml
else
    echo "❌ l10n.yaml is missing"
    # Create the file if needed
    cat >l10n.yaml <<EOF
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
EOF
    echo "✅ Created l10n.yaml file"
fi

# Verify ARB files
if [ -d "lib/l10n" ]; then
    echo "✅ l10n directory exists"
    ls -la lib/l10n
else
    echo "❌ lib/l10n directory is missing"
    exit 1
fi

# Check for Flutter installation
if command -v flutter &>/dev/null; then
    echo "✅ Flutter is installed"
    flutter --version

    # Check Flutter configuration
    echo "Checking Flutter configuration..."
    flutter doctor -v
else
    echo "❌ Flutter is not installed"
    exit 1
fi

# Verify pubspec.yaml contains necessary dependencies
if grep -q "flutter_localizations" pubspec.yaml; then
    echo "✅ flutter_localizations found in pubspec.yaml"
else
    echo "❌ flutter_localizations missing from pubspec.yaml"
    exit 1
fi

if grep -q "generate: true" pubspec.yaml; then
    echo "✅ 'generate: true' found in pubspec.yaml"
else
    echo "❌ 'generate: true' missing from pubspec.yaml"
    exit 1
fi

echo "Configuration verification complete!"
echo "Run 'flutter gen-l10n' to generate localization files"
