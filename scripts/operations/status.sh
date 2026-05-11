#!/bin/bash
# Detailed system status (wrapper for monitor.sh)

if [ -f "./monitor.sh" ]; then
    ./monitor.sh
else
    echo "📊 System Status"
    echo ""
    docker compose ps
fi
