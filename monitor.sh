#!/bin/bash
# Скрипт мониторинга производительности free-ai-aggregator

echo "=== Мониторинг free-ai-aggregator ==="
echo "Время: $(date)"
echo ""

echo "--- Статус контейнеров ---"
docker ps --filter "name=omniroute" --filter "name=openclaw" --filter "name=omniroute-redis" --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
echo ""

echo "--- Использование ресурсов ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" omniroute openclaw omniroute-redis 2>/dev/null
echo ""

echo "--- Health checks ---"
echo -n "OmniRoute: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:20128/api/monitoring/health 2>/dev/null || echo "недоступен"
echo ""
echo -n "OpenClaw: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/healthz 2>/dev/null || echo "недоступен"
echo ""
echo -n "Redis: "
docker exec omniroute-redis redis-cli ping 2>/dev/null || echo "недоступен"
echo ""

echo "--- Redis статистика ---"
docker exec omniroute-redis redis-cli INFO stats 2>/dev/null | grep -E "total_connections_received|total_commands_processed|keyspace_hits|keyspace_misses|evicted_keys" || echo "Недоступно"
echo ""

echo "--- Использование диска ---"
df -h | grep -E "Filesystem|/home/creator/PROJECTS/free-ai-aggregator"
echo ""

echo "--- Логи (последние ошибки) ---"
echo "OmniRoute:"
docker logs omniroute --tail 5 2>&1 | grep -i error || echo "Нет ошибок"
echo ""
echo "OpenClaw:"
docker logs openclaw --tail 5 2>&1 | grep -i error || echo "Нет ошибок"
echo ""
