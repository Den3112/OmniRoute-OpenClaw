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
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_PATH=$(df -h . | tail -1 | awk '{print $6}')
DISK_AVAIL=$(df -h . | tail -1 | awk '{print $4}')

echo "Путь: $DISK_PATH"
echo "Использование: ${DISK_USAGE}%"
echo "Доступно: $DISK_AVAIL"

if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  КРИТИЧНО: Диск заполнен более чем на 90%!"
    echo "   Рекомендуется очистить логи и старые образы:"
    echo "   docker system prune -a --volumes"
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  ВНИМАНИЕ: Диск заполнен более чем на 80%"
    echo "   Рекомендуется мониторить использование диска"
else
    echo "✓ Использование диска в норме"
fi
echo ""

echo "--- Логи (последние ошибки) ---"
echo "OmniRoute:"
docker logs omniroute --tail 5 2>&1 | grep -i error || echo "Нет ошибок"
echo ""
echo "OpenClaw:"
docker logs openclaw --tail 5 2>&1 | grep -i error || echo "Нет ошибок"
echo ""
