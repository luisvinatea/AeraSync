#!/bin/bash

# Install dependencies explicitly
npm install --legacy-peer-deps

# Run vercel-build script instead of regular build
npm run vercel-build
