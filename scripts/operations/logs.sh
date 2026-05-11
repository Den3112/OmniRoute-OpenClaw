#!/bin/bash
# View logs from all services or specific service

if [ -z "$1" ]; then
    echo "📋 Viewing logs from all services (Ctrl+C to exit)..."
    docker compose logs -f
else
    echo "📋 Viewing logs from $1 (Ctrl+C to exit)..."
    docker compose logs -f "$1"
fi
