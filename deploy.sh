#!/bin/bash
# Deployment script for AeraSync to GitHub Pages
set -e # Exit immediately if a command exits with a non-zero status

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working directory is not clean. Please commit or stash changes before deploying."
  exit 1
fi

# Check Flutter and Dart versions
echo "Checking Flutter and Dart versions..."
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[\d\.]+')
DART_VERSION=$(flutter --version | grep -oP 'Dart \K[\d\.]+')
MINIMUM_FLUTTER_VERSION="3.13.0"
RECOMMENDED_FLUTTER_VERSION="3.22.2"
MINIMUM_DART_VERSION="3.3.0"
if [[ $(echo -e "$FLUTTER_VERSION\n$MINIMUM_FLUTTER_VERSION" | sort -V | head -n1) != "$MINIMUM_FLUTTER_VERSION" ]]; then
  echo "Flutter version $FLUTTER_VERSION is too old. Minimum required version is $MINIMUM_FLUTTER_VERSION."
  echo "Attempting to upgrade Flutter..."
  flutter channel stable
  flutter upgrade
  FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[\d\.]+')
  if [[ $(echo -e "$FLUTTER_VERSION\n$MINIMUM_FLUTTER_VERSION" | sort -V | head -n1) != "$MINIMUM_FLUTTER_VERSION" ]]; then
    echo "Error: Flutter upgrade failed. Please manually upgrade Flutter to version $MINIMUM_FLUTTER_VERSION or higher."
    exit 1
  fi
fi
if [[ "$FLUTTER_VERSION" == "3.29.2" ]]; then
  echo "Warning: Flutter 3.29.2 has known regressions (e.g., incorrect Dart SDK version, intl dependency issues)."
  echo "It is recommended to use Flutter $RECOMMENDED_FLUTTER_VERSION instead."
fi
if [[ $(echo -e "$DART_VERSION\n$MINIMUM_DART_VERSION" | sort -V | head -n1) != "$MINIMUM_DART_VERSION" ]]; then
  echo "Error: Dart version $DART_VERSION is too old. Minimum required version is $MINIMUM_DART_VERSION."
  echo "Please use a Flutter version that bundles a compatible Dart SDK (e.g., Flutter $RECOMMENDED_FLUTTER_VERSION)."
  exit 1
fi

# Adjust flutter_lints based on Dart version
echo "Checking Dart version for flutter_lints compatibility..."
if [[ $(echo -e "$DART_VERSION\n3.5.0" | sort -V | head -n1) != "3.5.0" ]]; then
  echo "Dart version $DART_VERSION is older than 3.5.0, adjusting flutter_lints to ^4.0.0..."
  # Backup pubspec.yaml
  cp pubspec.yaml pubspec.yaml.bak
  # Replace flutter_lints constraint
  sed -i '/flutter_lints: ^5.0.0/c\  flutter_lints: ^4.0.0' pubspec.yaml
else
  # Ensure flutter_lints is set to ^5.0.0 if Dart version is 3.5.0 or higher
  sed -i '/flutter_lints: ^4.0.0/c\  flutter_lints: ^5.0.0' pubspec.yaml
fi

# Change to project directory
cd "$(dirname "$0")" || { echo "Failed to change directory"; exit 1; }

# Verify required assets
echo "Verifying required assets..."
for asset in \
  web/icons/aerasync64.webp \
  web/icons/aerasync64.png \
  web/icons/aerasync180.webp \
  web/icons/aerasync180.png \
  web/icons/aerasync512.webp \
  web/icons/aerasync512.png \
  web/icons/aerasync1024.webp \
  web/icons/aerasync1024.png \
  web/icons/aerasync.webp \
  web/assets/wave.svg \
  web/manifest.json; do
  if [ ! -f "$asset" ]; then
    echo "Error: Required asset $asset is missing"
    exit 1
  fi
  # Verify asset type (basic integrity check)
  if [[ "$asset" == *.webp || "$asset" == *.png ]]; then
    file_type=$(file -b --mime-type "$asset")
    if [[ "$file_type" != "image/webp" && "$file_type" != "image/png" ]]; then
      echo "Error: Asset $asset is not a valid image (type: $file_type)"
      exit 1
    fi
  fi
done

# Clean previous builds and caches
echo "Cleaning previous builds and caches..."
flutter clean || { echo "Flutter clean failed"; exit 1; }
flutter pub cache repair || { echo "Pub cache repair failed"; exit 1; }
rm -f pubspec.lock || { echo "Failed to remove pubspec.lock"; exit 1; }

# Get dependencies with fallback override for intl
echo "Getting dependencies..."
if ! flutter pub get; then
  echo "Warning: Initial flutter pub get failed, likely due to a dependency conflict with intl."
  echo "Checking dependency tree..."
  flutter pub deps -- --style=compact | grep -A 1 "flutter_localizations" || true
  echo "Attempting to downgrade intl constraint to ^0.19.0..."
  # Replace intl constraint
  sed -i '/intl: ^0.20.0/c\  intl: ^0.19.0' pubspec.yaml
  # Retry dependency resolution
  if ! flutter pub get; then
    echo "Error: Flutter pub get failed even after downgrading intl constraint."
    # Restore pubspec.yaml
    mv pubspec.yaml.bak pubspec.yaml
    exit 1
  fi
  echo "Successfully resolved dependencies with downgraded intl constraint."
else
  # Remove pubspec.yaml.bak if it exists from a previous run
  rm -f pubspec.yaml.bak
fi

# Run tests
echo "Running tests..."
flutter test || { echo "Tests failed"; exit 1; }

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
      # Show diff of keys
      diff <(echo "$reference_keys" | tr -d '[]' | tr ',' '\n') <(echo "$file_keys" | tr -d '[]' | tr ',' '\n') | grep -E '^[<>]' || true
      exit 1
    fi
  fi
done

# Build web release with CanvasKit
echo "Building web release..."
flutter build web --dart-define=flutter.web.renderer=canvaskit --release --base-href=/AeraSync/ || { echo "Flutter build failed"; exit 1; }

# Analyze bundle size
echo "Analyzing bundle size..."
total_size=$(du -sh build/web | cut -f1)
echo "Total build size: $total_size"

# Prepare gh-pages directory
GH_PAGES_DIR="../AeraSync-gh-pages"
if [ ! -d "$GH_PAGES_DIR" ]; then
  echo "gh-pages directory not found. Initializing it..."
  git worktree add "$GH_PAGES_DIR" gh-pages || { echo "Failed to set up gh-pages worktree. Please ensure the gh-pages branch exists."; exit 1; }
fi

# Clean gh-pages directory and copy build
echo "Copying build to gh-pages..."
rm -rf "$GH_PAGES_DIR"/* || { echo "Failed to clean gh-pages directory"; exit 1; }
cp -r build/web/* "$GH_PAGES_DIR/" || { echo "Copy failed"; exit 1; }

# Commit and push changes
cd "$GH_PAGES_DIR" || { echo "Failed to change to gh-pages directory"; exit 1; }

echo "Committing changes..."
git add . || { echo "Git add failed"; exit 1; }
# Allow empty commits in case there are no changes
if ! git diff --staged --quiet; then
  git commit -m "Update with latest changes" || { echo "Git commit failed"; exit 1; }
else
  echo "No changes to commit"
fi
git push origin gh-pages || { echo "Git push failed"; exit 1; }

# Derive GitHub username from remote URL
REMOTE_URL=$(git remote get-url origin)
USER_NAME=$(echo "$REMOTE_URL" | grep -oP '(?<=github\.com[:/])([^/]+)' | head -n1)
REPO_NAME="AeraSync"
echo "✅ Deployment completed successfully"
echo "View your site at: https://$USER_NAME.github.io/$REPO_NAME/"