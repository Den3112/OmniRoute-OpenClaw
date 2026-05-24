#!/bin/bash
# Boost script for Docker & Antigravity performance

# 1. Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "🚀 Boosting Docker performance..."

# 2. Add BuildKit to .env if missing
if ! grep -q "DOCKER_BUILDKIT" .env; then
    echo "DOCKER_BUILDKIT=1" >> .env
    echo "COMPOSE_DOCKER_CLI_BUILD=1" >> .env
fi

# 3. Optimize .dockerignore
cat >> .dockerignore <<EOF
# Antigravity/Claude specific
.agents
.claude
scratch
*.sh
EOF

# 4. Cleanup old objects
echo "🧹 Cleaning up unused Docker objects..."
docker system prune -f --volumes

# 5. Apply system optimizations
if [ -f "./optimize_system.sh" ]; then
    bash ./optimize_system.sh
fi

# 6. Rebuild with parallel support
echo "🏗️ Rebuilding with parallel execution..."
docker compose build --parallel

echo "✅ Boost applied! Antigravity should now work faster with Docker."
