#!/bin/bash

# Install dependencies explicitly
npm install --legacy-peer-deps

# Run vercel-specific build for better compatibility
npm run vercel-build
