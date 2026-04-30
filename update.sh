#!/bin/bash
# OmniRoute-OpenClaw One-Click Installer & Updater
set -e

echo "🚀 Starting OmniRoute-OpenClaw Setup..."

# 1. Submodule Initialization
if [ ! -f "OmniRoute/package.json" ]; then
    echo "📦 Initializing submodules..."
    git submodule update --init --recursive
else
    echo "📥 Updating submodules..."
    git submodule update --remote --merge
fi

# 2. Automatic .env & Secret Generation
if [ ! -f .env ]; then
    echo "📝 Creating .env from example..."
    cp .env.example .env
fi

# Function to generate secret if empty
generate_secret() {
    local var_name=$1
    local current_val=$(grep "^${var_name}=" .env | cut -d'=' -f2)
    if [ -z "$current_val" ] || [ "$current_val" == "CHANGEME" ] || [[ "$current_val" == *"replace_this"* ]]; then
        echo "🔐 Generating secure $var_name..."
        local new_val=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | hex)
        # Use a simpler sed for compatibility
        sed -i "s|^${var_name}=.*|${var_name}=${new_val}|" .env
    fi
}

generate_secret "STORAGE_ENCRYPTION_KEY"
generate_secret "JWT_SECRET"
generate_secret "API_KEY_SECRET"
generate_secret "OPENCLAW_PASSWORD"

# 3. Docker build and run
echo "🛠 Building and starting containers..."
docker-compose build --pull
docker-compose up -d

# 4. Maintenance
echo "🧹 Cleaning up disk space..."
docker image prune -f

echo "✅ ALL SYSTEMS GO!"
echo "📍 OmniRoute Dashboard: http://localhost:20128"
echo "📍 OpenClaw Gateway: http://localhost:18789"
