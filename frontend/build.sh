#!/bin/bash

# Build the Flutter web app in release mode
flutter build web --release --web-renderer canvaskit

# Copy build output to the public directory that Vercel expects
mkdir -p public
cp -r build/web/* public/

# Create a Vercel-specific _redirects file for additional fallback
echo "/* /index.html 200" > public/_redirects