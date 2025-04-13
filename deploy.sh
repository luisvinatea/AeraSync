#!/bin/bash
# Deployment script for AeraSync to GitHub Pages
# Assumes this script is run from the project root directory.
set -e # Exit immediately if a command exits with a non-zero status

# --- Pre-Checks ---

echo "Running deployment script from: $(pwd)"

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
RECOMMENDED_FLUTTER_VERSION="3.29.2" # Consider updating this recommendation periodically
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

# Backup pubspec.yaml only if modification is needed
NEEDS_LINT_MOD=false
# Remove previous backup if it exists
rm -f "$PUBSPEC_BAK_FILE"

if [[ $(echo -e "$DART_VERSION\n3.5.0" | sort -V | head -n1) != "3.5.0" ]]; then
  # Dart < 3.5.0, needs lints ^4.0.0
  if grep -q "$LINTS_V5_PATTERN" "$PUBSPEC_FILE"; then
    echo "Dart version $DART_VERSION is older than 3.5.0, adjusting flutter_lints to ^4.0.0..."
    NEEDS_LINT_MOD=true
    cp "$PUBSPEC_FILE" "$PUBSPEC_BAK_FILE" # Create backup
    sed -i.bak "s/$LINTS_V5_PATTERN/$LINTS_V4_REPLACEMENT/" "$PUBSPEC_FILE" # Use sed's backup feature as fallback
  fi
else
  # Dart >= 3.5.0, needs lints ^5.0.0
  if grep -q "$LINTS_V4_PATTERN" "$PUBSPEC_FILE"; then
    echo "Dart version $DART_VERSION is 3.5.0 or higher, adjusting flutter_lints to ^5.0.0..."
    NEEDS_LINT_MOD=true
    cp "$PUBSPEC_FILE" "$PUBSPEC_BAK_FILE" # Create backup
    sed -i.bak "s/$LINTS_V4_PATTERN/$LINTS_V5_REPLACEMENT/" "$PUBSPEC_FILE" # Use sed's backup feature as fallback
  fi
fi
# Remove sed's automatic backup if our main backup was created
if [ -f "$PUBSPEC_BAK_FILE" ]; then rm -f "$PUBSPEC_FILE.bak"; fi


# --- Removed problematic `cd "$(dirname "$0")"` ---
# Script assumes it's run from the project root directory.
echo "Working directory: $(pwd)"

# --- Verify Assets ---
echo "Verifying required assets..."
# Paths are relative to the project root
ASSET_MISSING=false
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
  web/manifest.json \
  web/privacy.html \
  assets/data/o2_temp_sal_100_sat.json \
  assets/data/shrimp_respiration_salinity_temperature_weight.json \
  lib/l10n/app_en.arb; do # Add more critical files if needed
  if [ ! -f "$asset" ]; then
    echo "Error: Required asset/file $asset is missing"
    ASSET_MISSING=true
  fi
done
if [ "$ASSET_MISSING" = true ]; then exit 1; fi

# --- Clean & Dependencies ---
echo "Cleaning previous builds and caches..."
flutter clean || { echo "Flutter clean failed"; exit 1; }
rm -f pubspec.lock || { echo "Failed to remove pubspec.lock"; exit 1; }

# Get dependencies with fallback override for intl (Potentially Risky sed)
echo "Getting dependencies..."
INTL_V19_PATTERN='intl: ^0\.19\.0' # Escaped dot
INTL_V20_PATTERN='intl: ^0\.20\.0' # Escaped dot
INTL_V19_REPLACEMENT='  intl: ^0.19.0'
NEEDS_INTL_MOD=false
if ! flutter pub get; then
  echo "Warning: Initial flutter pub get failed, likely due to intl dependency."
  if grep -q "$INTL_V20_PATTERN" "$PUBSPEC_FILE"; then
      echo "Attempting to downgrade intl constraint to ^0.19.0..."
      if [ ! -f "$PUBSPEC_BAK_FILE" ]; then # Backup only if not already backed up
          cp "$PUBSPEC_FILE" "$PUBSPEC_BAK_FILE"
      fi
      sed -i.bak "s/$INTL_V20_PATTERN/$INTL_V19_REPLACEMENT/" "$PUBSPEC_FILE"
      NEEDS_INTL_MOD=true
      if ! flutter pub get; then
        echo "Error: Flutter pub get failed even after downgrading intl constraint."
        if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi # Restore on error
        exit 1
      fi
      echo "Successfully resolved dependencies with downgraded intl constraint."
  else
      echo "Error: Flutter pub get failed, and intl ^0.20.0 was not found to downgrade."
       # Restore if only lints modified it
        if [ -f "$PUBSPEC_BAK_FILE" ] && [ "$NEEDS_LINT_MOD" = true ] && [ "$NEEDS_INTL_MOD" = false ]; then
            mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"
        fi
      exit 1
  fi
fi
# Remove sed's automatic backup if our main backup was created
if [ -f "$PUBSPEC_BAK_FILE" ]; then rm -f "$PUBSPEC_FILE.bak"; fi


echo "Generating localization files..."
flutter gen-l10n || { echo "Localization generation failed"; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; } # Restore on failure

# --- Testing & Generation ---
echo "Running tests..."
flutter test || { echo "Tests failed"; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; } # Restore on failure


# --- ARB Checks (Requires Python 3) ---
echo "Linting .arb files (requires python3)..."
PYTHON_EXE="python3" # Or just "python" if python3 isn't standard
if ! command -v $PYTHON_EXE &> /dev/null; then
    echo "Warning: $PYTHON_EXE command not found. Skipping ARB checks."
else
    for file in lib/l10n/*.arb; do
      if [ ! -f "$file" ]; then
        echo "Warning: No .arb files found in lib/l10n/"
        break
      fi
      if ! $PYTHON_EXE -m json.tool "$file" >/dev/null 2>&1; then
        echo "Error: Invalid JSON syntax in $file"
        if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi # Restore on failure
        exit 1
      fi
    done

    echo "Checking consistency of localization keys (requires python3)..."
    reference_file="lib/l10n/app_en.arb"
    if [ -f "$reference_file" ]; then
      # Use python script for robust key extraction and comparison
      read -r -d '' PY_SCRIPT << EOM
import json, sys, os
try:
    ref_file = sys.argv[1]
    l10n_dir = os.path.dirname(ref_file)
    with open(ref_file, 'r', encoding='utf-8') as f:
        ref_keys = set(json.load(f).keys())

    mismatch = False
    for filename in os.listdir(l10n_dir):
        if filename.startswith('app_') and filename.endswith('.arb') and filename != os.path.basename(ref_file):
            file_path = os.path.join(l10n_dir, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    file_keys = set(json.load(f).keys())
                if ref_keys != file_keys:
                    mismatch = True
                    missing_in_file = sorted(list(ref_keys - file_keys))
                    extra_in_file = sorted(list(file_keys - ref_keys))
                    print(f"Error: Key mismatch in {filename}")
                    if missing_in_file: print(f"  Missing keys: {missing_in_file}")
                    if extra_in_file: print(f"  Extra keys: {extra_in_file}")
            except Exception as e:
                print(f"Error processing {filename}: {e}")
                mismatch = True # Treat parse errors as mismatch

    sys.exit(1 if mismatch else 0)

except Exception as e:
    print(f"Python script error: {e}")
    sys.exit(1)
EOM
      if ! $PYTHON_EXE -c "$PY_SCRIPT" "$reference_file"; then
          echo "ARB key consistency check failed."
          if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi # Restore on failure
          exit 1
      fi
    else
        echo "Warning: Reference localization file $reference_file not found. Skipping key consistency check."
    fi
fi

# --- Build ---
echo "Building web release with CanvasKit renderer..."
# Ensure base-href matches your GitHub pages setup (e.g., /RepoName/)
flutter build web --dart-define=flutter.web.renderer=canvaskit --release --base-href=/AeraSync/ || { echo "Flutter build failed"; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; } # Restore on failure

# --- Analyze ---
echo "Analyzing bundle size..."
total_size=$(du -sh build/web | cut -f1)
echo "Total build size: $total_size"

# --- Deployment ---
# Define GH_PAGES_DIR relative to the project root (e.g., a sibling directory)
# Adjust path as needed!
GH_PAGES_DIR="../AeraSync-gh-pages" # Assumes it's one level up from project root
PROJECT_ROOT_DIR=$(pwd) # Store project root

# Prepare gh-pages directory using git worktree
if [ ! -d "$GH_PAGES_DIR/.git" ]; then # Check for .git to confirm it's a worktree/repo
  echo "gh-pages directory/worktree not found at $GH_PAGES_DIR. Initializing..."
  rm -rf "$GH_PAGES_DIR" # Remove potentially existing non-git directory first
  git worktree add "$GH_PAGES_DIR" gh-pages || { echo "Failed to set up gh-pages worktree. Please ensure the gh-pages branch exists and the path is correct."; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; }
else
   echo "gh-pages directory/worktree found at $GH_PAGES_DIR."
fi

# Clean gh-pages directory safely and copy build
echo "Cleaning and copying build to gh-pages directory..."
cd "$GH_PAGES_DIR" || { echo "Failed to change to gh-pages directory"; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PROJECT_ROOT_DIR/$PUBSPEC_BAK_FILE" "$PROJECT_ROOT_DIR/$PUBSPEC_FILE"; fi; exit 1; }

# Safer clean using git commands within the worktree
echo "Cleaning worktree with git..."
# Remove all tracked files first (quietly)
git ls-files -z | xargs -0 rm -f
# Remove all remaining untracked files and directories (forcefully)
git clean -fdx

echo "Copying new build..."
# Copy contents from the build output directory
cp -r "$PROJECT_ROOT_DIR/build/web/"* ./ || { echo "Copy failed"; cd "$PROJECT_ROOT_DIR" || exit 1; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; }

# Commit and push changes
echo "Committing changes..."
git add . || { echo "Git add failed"; cd "$PROJECT_ROOT_DIR" || exit 1; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; }
# Commit only if there are changes to commit
if ! git diff --staged --quiet; then
  git commit -m "Deploy latest build: $(date +'%Y-%m-%d %H:%M:%S')" || { echo "Git commit failed"; cd "$PROJECT_ROOT_DIR" || exit 1; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; }
  echo "Pushing changes to gh-pages..."
  git push origin gh-pages || { echo "Git push failed"; cd "$PROJECT_ROOT_DIR" || exit 1; if [ -f "$PUBSPEC_BAK_FILE" ]; then mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"; fi; exit 1; }
else
  echo "No changes detected in build output to commit."
fi

# Go back to the original directory
cd "$PROJECT_ROOT_DIR" || exit 1

# --- Restore pubspec.yaml if it was modified ---
if [ -f "$PUBSPEC_BAK_FILE" ]; then
    echo "Restoring original pubspec.yaml..."
    mv "$PUBSPEC_BAK_FILE" "$PUBSPEC_FILE"
fi

# --- Final Message ---
# Derive GitHub username from remote URL more robustly
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "") # Handle error if no remote
USER_NAME=""
# Try matching SSH and HTTPS formats
if [[ "$REMOTE_URL" =~ github\.com:([^/]+)/ ]]; then
    USER_NAME="${BASH_REMATCH[1]}"
elif [[ "$REMOTE_URL" =~ github\.com/([^/]+)/ ]]; then
     USER_NAME="${BASH_REMATCH[1]}"
fi
REPO_NAME="AeraSync" # Assuming repo name is fixed

echo "✅ Deployment completed successfully"
if [ -n "$USER_NAME" ]; then
  echo "View your site at: https://$USER_NAME.github.io/$REPO_NAME/"
else
  echo "Could not determine GitHub username from remote '$REMOTE_URL' to construct URL."
fi

