#!/bin/bash

# OmniRoute-OpenClaw Update Script
# This script updates submodules to their latest versions and restarts Docker containers.

echo "🚀 Starting update process..."

# 1. Update submodules to latest remote commits
echo "📥 Pulling latest versions of OmniRoute and openclaw..."
git submodule update --remote --merge

# 2. Rebuild Docker images
echo "🛠 Rebuilding Docker images..."
docker-compose build

# 3. Restart containers
echo "🔄 Restarting containers..."
docker-compose up -d

echo "✅ Update complete! System is running the latest versions."
