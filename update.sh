#!/bin/bash
# OmniRoute-OpenClaw One-Click Installer & Updater
set -e

echo "🚀 Starting OmniRoute-OpenClaw Setup..."

# 0. Pre-flight checks
command -v docker >/dev/null 2>&1 || { echo >&2 "❌ Docker is required but not installed. Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "❌ Git is required but not installed. Aborting."; exit 1; }

# 1. Data Migration (Optional - if user has old data in home)
OLD_OMNI="$HOME/.omniroute"
OLD_OPENCLAW="$HOME/.openclaw"
NEW_DATA_DIR="./data"

if [ ! -d "$NEW_DATA_DIR" ]; then
    mkdir -p "$NEW_DATA_DIR"
    if [ -d "$OLD_OMNI" ]; then
        echo "📂 Migrating OmniRoute data from $OLD_OMNI..."
        cp -r "$OLD_OMNI" "$NEW_DATA_DIR/omniroute"
    fi
    if [ -d "$OLD_OPENCLAW" ]; then
        echo "📂 Migrating OpenClaw data from $OLD_OPENCLAW..."
        cp -r "$OLD_OPENCLAW" "$NEW_DATA_DIR/openclaw"
    fi
fi

# 2. Submodule Initialization
if [ ! -f "OmniRoute/package.json" ]; then
    echo "📦 Initializing submodules..."
    git submodule update --init --recursive
else
    echo "📥 Updating submodules..."
    git submodule update --remote --merge
fi

# 3. Automatic .env & Secret Generation
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "📝 Creating .env from example..."
        cp .env.example .env
    else
        touch .env
    fi
fi

# Function to generate secret if empty or missing
generate_secret() {
    local var_name=$1
    local current_val=$(grep "^${var_name}=" .env | cut -d'=' -f2 || true)
    if [ -z "$current_val" ] || [ "$current_val" == "CHANGEME" ] || [[ "$current_val" == *"replace_this"* ]]; then
        echo "🔐 Generating secure $var_name..."
        local new_val=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | hex)
        if grep -q "^${var_name}=" .env; then
            sed -i "s|^${var_name}=.*|${var_name}=${new_val}|" .env
        else
            echo "${var_name}=${new_val}" >> .env
        fi
    fi
}

generate_secret "STORAGE_ENCRYPTION_KEY"
generate_secret "JWT_SECRET"
generate_secret "API_KEY_SECRET"
generate_secret "OPENCLAW_PASSWORD"

# 4. Docker build and run
echo "🛠 Building and starting containers..."
docker-compose build --parallel --pull
docker-compose up -d

# 5. Post-update health check
echo "⏳ Waiting for services to become healthy..."
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    UNHEALTHY=$(docker ps --filter "health=unhealthy" --filter "name=omniroute" --filter "name=openclaw" -q)
    STARTING=$(docker ps --filter "health=starting" --filter "name=omniroute" --filter "name=openclaw" -q)
    
    if [ -z "$UNHEALTHY" ] && [ -z "$STARTING" ]; then
        echo "✅ All services are healthy!"
        break
    fi
    
    echo "Waiting for services... ($((COUNT+1))/$MAX_RETRIES)"
    sleep 10
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "⚠️ Warning: Some services are still not healthy."
    echo "Check status with 'docker ps' and logs with 'docker logs openclaw'."
fi

# 6. Maintenance
echo "🧹 Cleaning up disk space..."
docker image prune -f

echo "✅ ALL SYSTEMS GO!"
echo "📍 OmniRoute Dashboard: http://localhost:20128"
echo "📍 OpenClaw Gateway: http://localhost:18789"

