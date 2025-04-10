#!/bin/bash
# Deployment script for AeraSync to GitHub Pages
set -e # Exit immediately if a command exits with a non-zero status

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working directory is not clean. Please commit or stash changes before deploying."
  exit 1
fi

# Check Flutter version
echo "Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[\d\.]+')
MINIMUM_VERSION="3.0.0"
if [[ $(echo -e "$FLUTTER_VERSION\n$MINIMUM_VERSION" | sort -V | head -n1) != "$MINIMUM_VERSION" ]]; then
  echo "Error: Flutter version $FLUTTER_VERSION is too old. Minimum required version is $MINIMUM_VERSION."
  echo "Please upgrade Flutter by running 'flutter upgrade'."
  exit 1
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

# Run tests
echo "Running tests..."
flutter test || { echo "Tests failed"; exit 1; }

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