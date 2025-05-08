#!/bin/bash

# Clear node_modules and package-lock to prevent dependency conflicts
rm -rf node_modules package-lock.json

# Install dependencies with explicit versions to avoid version conflicts
npm install --no-save --legacy-peer-deps \
    schema-utils@4.0.0 \
    mini-css-extract-plugin@2.7.6 \
    copy-webpack-plugin@11.0.0 \
    html-webpack-plugin@5.5.3 \
    webpack@5.88.2 \
    webpack-cli@5.1.4

# Run build
npm run build
