#!/bin/bash
# Deployment script for AeraSync to GitHub Pages
set -e # Exit immediately if a command exits with a non-zero status

# Check Flutter version
echo "Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version --machine | grep -oP '"frameworkVersion": "\K[^"]+')
MINIMUM_VERSION="2.0.0"
if [[ $(echo -e "$FLUTTER_VERSION\n$MINIMUM_VERSION" | sort -V | head -n1) != "$MINIMUM_VERSION" ]]; then
  echo "Error: Flutter version $FLUTTER_VERSION is too old. Minimum required version is $MINIMUM_VERSION."
  echo "Please upgrade Flutter by running 'flutter upgrade'."
  exit 1
fi

# Change to project directory
cd /home/luisvinatea/Dev/Repos/AeraSync/AeraSync || { echo "Failed to change directory"; exit 1; }

# Verify required assets
echo "Verifying required assets..."
for asset in web/icons/aerasync64.webp web/icons/aerasync180.webp web/icons/aerasync512.webp web/icons/aerasync1024.webp web/icons/aerasync.webp web/manifest.json; do
  if [ ! -f "$asset" ]; then
    echo "Error: Required asset $asset is missing"
    exit 1
  fi
done

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean || { echo "Flutter clean failed"; exit 1; }

# Get dependencies
echo "Getting dependencies..."
flutter pub get || { echo "Flutter pub get failed"; exit 1; }

# Generate localization files
echo "Generating localization files..."
flutter gen-l10n || { echo "Localization generation failed"; exit 1; }

# Lint .arb files
echo "Linting .arb files..."
for file in lib/l10n/*.arb; do
  if [ ! -f "$file" ]; then
    echo "No .arb files found in lib/l10n/"
    exit 1
  fi
  # Check for trailing commas
  if grep -qE ',\s*}' "$file"; then
    echo "Error: Trailing comma found in $file"
    exit 1
  fi
  # Validate JSON syntax
  if ! python3 -m json.tool "$file" >/dev/null 2>&1; then
    echo "Error: Invalid JSON syntax in $file"
    exit 1
  fi
done

# Compare keys across .arb files to ensure consistency
echo "Checking consistency of localization keys..."
reference_file="lib/l10n/app_en.arb"
reference_keys=$(python3 -c "import json; print(sorted(json.load(open('$reference_file')).keys()))")
for file in lib/l10n/app_*.arb; do
  if [ "$file" != "$reference_file" ]; then
    file_keys=$(python3 -c "import json; print(sorted(json.load(open('$file')).keys()))")
    if [ "$reference_keys" != "$file_keys" ]; then
      echo "Error: Keys in $file do not match $reference_file"
      echo "Reference keys: $reference_keys"
      echo "File keys: $file_keys"
      exit 1
    fi
  fi
done

# Build web release with CanvasKit using --dart-define
echo "Building web release..."
flutter build web --dart-define=flutter.web.renderer=canvaskit --release --no-tree-shake-icons || { echo "Flutter build failed"; exit 1; }

# Copy to gh-pages directory
echo "Copying build to gh-pages..."
cp -r build/web/* ../AeraSync-gh-pages/ || { echo "Copy failed"; exit 1; }

# Commit and push changes
cd ../AeraSync-gh-pages || { echo "Failed to change to gh-pages directory"; exit 1; }

echo "Committing changes..."
git add . || { echo "Git add failed"; exit 1; }
# Allow empty commits in case there are no changes
if ! git diff --staged --quiet; then
  git commit -m "Update with latest changes" || { echo "Git commit failed"; exit 1; }
else
  echo "No changes to commit"
fi
git push origin gh-pages || { echo "Git push failed"; exit 1; }

# Provide deployment URL
REPO_NAME="AeraSync-gh-pages"
USER_NAME=$(git config user.name)
echo "✅ Deployment completed successfully"
echo "View your site at: https://$USER_NAME.github.io/$REPO_NAME/"