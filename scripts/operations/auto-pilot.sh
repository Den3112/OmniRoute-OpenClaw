#!/bin/bash
# OmniRoute-OpenClaw Auto-Pilot & Self-Healing Script
# This script ensures the environment is always up-to-date and correctly configured.

set -e

PROJECT_ROOT="/home/creator/PROJECTS/free-ai-aggregator"
DATA_DIR="${PROJECT_ROOT}/data"
LOG_FILE="${PROJECT_ROOT}/auto-pilot.log"

# Redirect output to log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===================================================="
echo "🚀 AUTO-PILOT START: $(date)"
echo "===================================================="

cd "$PROJECT_ROOT"

# 1. NETWORK & DOCKER CHECK
echo "📡 Waiting for network connectivity..."
MAX_RETRIES=10
RETRY_COUNT=0
SKIP_UPDATES=true

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "✓ Internet connection detected."
        SKIP_UPDATES=false
        break
    fi
    echo "   Wait for network... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$SKIP_UPDATES" = "true" ]; then
    echo "⚠️ No internet connection after 50s. Skipping updates."
fi

echo "🐳 Waiting for Docker daemon..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker info >/dev/null 2>&1; then
        echo "✓ Docker daemon is ready."
        break
    fi
    echo "   Wait for Docker... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

# 2. SECRETS RECOVERY
echo "🔐 Checking secrets (.env)..."
if [ ! -f .env ]; then
    if [ -f "${DATA_DIR}/omniroute/env.bak" ]; then
        echo "♻️  Restoring .env from persistent backup..."
        cp "${DATA_DIR}/omniroute/env.bak" .env
    else
        echo "❌ CRITICAL: No .env and no backup found! Running update.sh to generate new ones..."
        ./scripts/maintenance/update.sh --yes
    fi
else
    # Update backup if current .env is good
    mkdir -p "${DATA_DIR}/omniroute"
    cp .env "${DATA_DIR}/omniroute/env.bak"
    echo "✓ .env verified and backed up."
fi

# 3. GIT & SUBMODULES SYNC
if [ "$SKIP_UPDATES" = "false" ]; then
    echo "🔄 Syncing with repository..."
    # Fetch main repo
    git fetch origin main
    
    # Check if we are behind
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "⬆️  Main repository is behind. Pulling latest changes..."
        git pull --rebase origin main
    fi

    echo "📦 Syncing submodules..."
    # This ensures submodules follow the branch defined in .gitmodules (main)
    # We stash local changes in submodules if any, to avoid conflicts
    git submodule foreach 'git stash || true'
    git submodule update --init --recursive --remote --merge
    git submodule foreach 'git stash pop || true'
    echo "✓ Submodules synced to latest branch heads."
else
    echo "⏩ Skipping git updates due to no network."
fi

# 4. DOCKER HEALTH & STARTUP
echo "🐳 Starting Docker services..."
# Using docker-compose.fast.yml with pre-built GHCR images is much faster and avoids compilation failures
docker compose -f docker-compose.fast.yml up -d

# 5. DATABASE INTEGRITY (Optional but recommended)
echo "💾 Checking database backups..."
mkdir -p "${DATA_DIR}/omniroute/db_backups"
# Ensure we have a recent backup
if [ -f "${DATA_DIR}/omniroute/storage.sqlite" ]; then
    cp "${DATA_DIR}/omniroute/storage.sqlite" "${DATA_DIR}/omniroute/db_backups/last_boot_backup.sqlite"
fi

# 6. HOUSEKEEPING
echo "🧹 Cleaning up old Docker artifacts..."
docker image prune -f >/dev/null 2>&1

echo "===================================================="
echo "✅ AUTO-PILOT COMPLETE: $(date)"
echo "📍 Dashboard: http://localhost:20128"
echo "===================================================="
