#!/bin/bash

# Make script executable
chmod +x build.sh

# Install dependencies explicitly
npm install --legacy-peer-deps

# Run webpack build
npm run build