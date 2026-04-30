#!/bin/bash

# OmniRoute-OpenClaw Professional Update Script
# Updates submodules, rebuilds images, and cleans up disk space.

set -e # Exit on error

echo "🚀 Starting professional update process..."

# 1. Update submodules
echo "📥 Pulling latest versions of submodules..."
git submodule update --remote --merge

# 2. Check for .env file in root
if [ ! -f .env ]; then
    echo "⚠️ Warning: .env file not found in root. Creating from example..."
    cp .env.example .env
    echo "‼️ PLEASE EDIT .env AND SET YOUR STORAGE_ENCRYPTION_KEY!"
fi

# 3. Rebuild and restart
echo "🛠 Rebuilding Docker images (this may take a few minutes)..."
docker-compose build --pull

echo "🔄 Restarting containers..."
docker-compose up -d

# 4. Cleanup
echo "🧹 Cleaning up old Docker images and builders to save space..."
docker image prune -f
docker builder prune -f --filter "until=24h"

echo "✅ Update complete! System is optimized and running latest versions."
