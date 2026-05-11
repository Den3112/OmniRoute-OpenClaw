#!/bin/bash
# Performance monitoring script for free-ai-aggregator

echo "=== free-ai-aggregator Monitoring ==="
echo "Time: $(date)"
echo ""

echo "--- Container Status ---"
docker ps --filter "name=omniroute" --filter "name=openclaw" --filter "name=omniroute-redis" --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
echo ""

echo "--- Resource Usage ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" omniroute openclaw omniroute-redis 2>/dev/null
echo ""

echo "--- Health Checks ---"
echo -n "OmniRoute: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:20128/api/monitoring/health 2>/dev/null || echo "unavailable"
echo ""
echo -n "OpenClaw: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/healthz 2>/dev/null || echo "unavailable"
echo ""
echo -n "Redis: "
docker exec omniroute-redis redis-cli ping 2>/dev/null || echo "unavailable"
echo ""

echo "--- Redis Statistics ---"
docker exec omniroute-redis redis-cli INFO stats 2>/dev/null | grep -E "total_connections_received|total_commands_processed|keyspace_hits|keyspace_misses|evicted_keys" || echo "Unavailable"
echo ""

echo "--- Disk Usage ---"
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_PATH=$(df -h . | tail -1 | awk '{print $6}')
DISK_AVAIL=$(df -h . | tail -1 | awk '{print $4}')

echo "Path: $DISK_PATH"
echo "Usage: ${DISK_USAGE}%"
echo "Available: $DISK_AVAIL"

if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  CRITICAL: Disk is more than 90% full!"
    echo "   Recommended to clean logs and old images:"
    echo "   docker system prune -a --volumes"
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  WARNING: Disk is more than 80% full"
    echo "   Recommended to monitor disk usage"
else
    echo "✓ Disk usage is normal"
fi
echo ""

echo "--- Logs (Recent Errors) ---"
echo "OmniRoute:"
docker logs omniroute --tail 5 2>&1 | grep -i error || echo "No errors"
echo ""
echo "OpenClaw:"
docker logs openclaw --tail 5 2>&1 | grep -i error || echo "No errors"
echo ""
