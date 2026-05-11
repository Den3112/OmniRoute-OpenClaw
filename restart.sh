#!/bin/bash
# Quick restart of services

if [ -z "$1" ]; then
    echo "🔄 Applying configuration and starting services..."
    docker compose up -d --remove-orphans
    echo "✅ All services are up to date and running"
else
    echo "🔄 Restarting $1..."
    docker compose up -d "$1"
    echo "✅ $1 restarted"
fi

echo ""
echo "Check status with: ./status.sh"
