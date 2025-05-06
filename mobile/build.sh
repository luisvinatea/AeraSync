#!/bin/bash

# Make script executable
chmod +x build.sh

# Install dependencies explicitly
npm install --no-save

# Run webpack build
npm run build