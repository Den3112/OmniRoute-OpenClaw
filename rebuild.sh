#!/bin/bash
# Скрипт для быстрой пересборки с использованием кэша

set -e

echo "=== Быстрая пересборка с кэшем ==="
echo ""

# Включаем BuildKit для лучшего кэширования
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "--- Проверка кэша ---"
if [ -d "/tmp/docker-cache/omniroute" ]; then
    echo "✓ Кэш OmniRoute найден ($(du -sh /tmp/docker-cache/omniroute | cut -f1))"
else
    echo "✗ Кэш OmniRoute не найден, будет создан"
fi

if [ -d "/tmp/docker-cache/openclaw" ]; then
    echo "✓ Кэш OpenClaw найден ($(du -sh /tmp/docker-cache/openclaw | cut -f1))"
else
    echo "✗ Кэш OpenClaw не найден, будет создан"
fi
echo ""

echo "--- Пересборка контейнеров ---"
cd /home/creator/PROJECTS/free-ai-aggregator

# Пересборка с использованием кэша
docker-compose build --progress=plain

echo ""
echo "--- Перезапуск сервисов ---"
docker-compose down
docker-compose up -d

echo ""
echo "--- Ожидание готовности ---"
sleep 10

echo ""
echo "--- Статус ---"
docker-compose ps

echo ""
echo "=== Готово! ==="
echo "Используйте './monitor.sh' для проверки состояния"
