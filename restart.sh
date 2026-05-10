#!/bin/bash
# Quick restart of services

if [ -z "$1" ]; then
    echo "🔄 Restarting all services..."
    docker compose restart
    echo "✅ All services restarted"
else
    echo "🔄 Restarting $1..."
    docker compose restart "$1"
    echo "✅ $1 restarted"
fi

echo ""
echo "Check status with: ./status.sh"
