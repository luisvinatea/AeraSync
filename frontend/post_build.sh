#!/bin/bash

# Post-build optimization script
BUILD_DIR="build/web"

# Compress images
echo "Optimizing images..."
find $BUILD_DIR/icons -name "*.webp" -exec bash -c 'echo "Optimizing $1"; convert "$1" -quality 85 -resize "800>" "$1"' _ {} \;
find $BUILD_DIR/assets -name "*.png" -exec bash -c 'echo "Optimizing $1"; pngquant --force --quality=65-80 --skip-if-larger --strip "$1"' _ {} \;

# Add viewport height fix for mobile keyboards
echo "Adding mobile viewport fixes..."
cat >> $BUILD_DIR/flutter.js << 'EOF'
// Mobile viewport height fix
(function() {
  function setVh() {
    let vh = window.innerHeight * 0.01;
    document.documentElement.style.setProperty('--vh', `${vh}px`);
  }
  window.addEventListener('resize', setVh);
  setVh();
})();
EOF

echo "Mobile web optimization complete!"