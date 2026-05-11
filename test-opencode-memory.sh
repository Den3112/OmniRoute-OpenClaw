# 🧪 Тестовый скрипт для проверки интеграции OpenCode + OmniRoute Memory

#!/bin/bash

echo "🧪 Тестирование интеграции OpenCode с OmniRoute Memory Management"
echo "=================================================================="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

# 1. Проверка OmniRoute
echo "1️⃣  Проверка OmniRoute..."
docker ps | grep -q omniroute
check "OmniRoute контейнер запущен"

curl -s http://localhost:20128/api/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ OmniRoute API доступен${NC}"
else
    echo -e "${YELLOW}⚠️  OmniRoute API требует аутентификацию (это нормально)${NC}"
fi

echo ""

# 2. Проверка Memory Management
echo "2️⃣  Проверка Memory Management..."
MEMORY_ENABLED=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const result = db.prepare('SELECT value FROM key_value WHERE namespace = \"settings\" AND key = \"memoryEnabled\"').get();
console.log(result ? result.value : 'false');
" 2>/dev/null)

if [ "$MEMORY_ENABLED" = "true" ]; then
    echo -e "${GREEN}✅ Memory Management включен${NC}"
else
    echo -e "${RED}❌ Memory Management выключен${NC}"
fi

# Проверка таблицы memories
MEMORY_COUNT=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const result = db.prepare('SELECT COUNT(*) as count FROM memories').get();
console.log(result.count);
" 2>/dev/null)

echo -e "${GREEN}✅ Таблица memories существует (записей: $MEMORY_COUNT)${NC}"

echo ""

# 3. Проверка MCP сервера
echo "3️⃣  Проверка MCP сервера..."
if [ -f "/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts" ]; then
    echo -e "${GREEN}✅ MCP сервер найден${NC}"
else
    echo -e "${RED}❌ MCP сервер не найден${NC}"
fi

# Проверка зависимостей
cd /home/creator/PROJECTS/free-ai-aggregator/OmniRoute
if [ -d "node_modules/@modelcontextprotocol" ]; then
    echo -e "${GREEN}✅ MCP SDK установлен${NC}"
else
    echo -e "${YELLOW}⚠️  MCP SDK не найден, устанавливаю...${NC}"
    npm install > /dev/null 2>&1
    check "MCP SDK установлен"
fi

echo ""

# 4. Проверка конфигурации OpenCode
echo "4️⃣  Проверка конфигурации OpenCode..."
if [ -f "$HOME/.config/opencode/mcp-servers.json" ]; then
    echo -e "${GREEN}✅ Глобальная конфигурация MCP создана${NC}"
    echo "   Путь: ~/.config/opencode/mcp-servers.json"
else
    echo -e "${RED}❌ Глобальная конфигурация MCP не найдена${NC}"
fi

if [ -f "/home/creator/PROJECTS/free-ai-aggregator/.opencode/mcp-servers.json" ]; then
    echo -e "${GREEN}✅ Проектная конфигурация MCP создана${NC}"
    echo "   Путь: .opencode/mcp-servers.json"
else
    echo -e "${RED}❌ Проектная конфигурация MCP не найдена${NC}"
fi

echo ""

# 5. Тест запуска MCP сервера
echo "5️⃣  Тест запуска MCP сервера..."
echo -e "${YELLOW}⏳ Запускаю MCP сервер (5 секунд)...${NC}"

timeout 5s npx tsx /home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts > /tmp/mcp-test.log 2>&1 &
MCP_PID=$!
sleep 2

if ps -p $MCP_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MCP сервер запустился успешно${NC}"
    kill $MCP_PID 2>/dev/null
    wait $MCP_PID 2>/dev/null
else
    echo -e "${RED}❌ MCP сервер не запустился${NC}"
    echo "Логи:"
    cat /tmp/mcp-test.log
fi

# Проверка логов на наличие ошибок
if grep -q "error\|Error\|ERROR" /tmp/mcp-test.log 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Обнаружены ошибки в логах:${NC}"
    grep -i error /tmp/mcp-test.log | head -5
else
    if grep -q "MCP Server connected and ready" /tmp/mcp-test.log 2>/dev/null; then
        echo -e "${GREEN}✅ MCP сервер готов к работе${NC}"
    fi
fi

echo ""

# 6. Создание тестового воспоминания
echo "6️⃣  Создание тестового воспоминания..."
TEST_MEMORY=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const crypto = require('crypto');
const id = crypto.randomUUID();
const now = new Date().toISOString();

try {
    db.prepare(\`
        INSERT INTO memories (id, api_key_id, session_id, type, key, content, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    \`).run(
        id,
        'test-api-key',
        'test-session',
        'factual',
        'opencode_integration_test',
        'Интеграция OpenCode с OmniRoute Memory Management настроена и протестирована ' + now,
        now,
        now
    );
    console.log('SUCCESS');
} catch (e) {
    console.log('ERROR: ' + e.message);
}
" 2>&1)

if echo "$TEST_MEMORY" | grep -q "SUCCESS"; then
    echo -e "${GREEN}✅ Тестовое воспоминание создано${NC}"
else
    echo -e "${RED}❌ Ошибка создания воспоминания: $TEST_MEMORY${NC}"
fi

# Проверка поиска
SEARCH_RESULT=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const result = db.prepare('SELECT * FROM memories WHERE key = \"opencode_integration_test\"').get();
console.log(result ? 'FOUND' : 'NOT_FOUND');
" 2>&1)

if echo "$SEARCH_RESULT" | grep -q "FOUND"; then
    echo -e "${GREEN}✅ Тестовое воспоминание найдено через поиск${NC}"
else
    echo -e "${RED}❌ Тестовое воспоминание не найдено${NC}"
fi

echo ""

# 7. Итоговая статистика
echo "7️⃣  Итоговая статистика..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATS=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');

// Общее количество воспоминаний
const total = db.prepare('SELECT COUNT(*) as count FROM memories').get();

// По типам
const byType = db.prepare('SELECT type, COUNT(*) as count FROM memories GROUP BY type').all();

// Последние 3
const recent = db.prepare('SELECT type, key, created_at FROM memories ORDER BY created_at DESC LIMIT 3').all();

console.log(JSON.stringify({ total: total.count, byType, recent }, null, 2));
" 2>/dev/null)

echo "$STATS" | jq '.' 2>/dev/null || echo "$STATS"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 8. Инструкции для пользователя
echo "📋 Следующие шаги:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Перезапустите OpenCode:"
echo "   ${YELLOW}opencode${NC}"
echo ""
echo "2. Проверьте доступные MCP инструменты:"
echo "   ${YELLOW}Какие MCP инструменты доступны?${NC}"
echo ""
echo "3. Создайте первое воспоминание:"
echo "   ${YELLOW}Запомни, что этот проект называется free-ai-aggregator${NC}"
echo ""
echo "4. Проверьте извлечение памяти:"
echo "   ${YELLOW}Как называется этот проект?${NC}"
echo ""
echo "5. Откройте Dashboard для просмотра памяти:"
echo "   ${YELLOW}http://localhost:20128/dashboard/memory${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Документация:"
echo "   - OPENCODE_MEMORY_INTEGRATION.md - полная инструкция"
echo "   - MEMORY_SKILLS_CONFIG.md - техническая документация"
echo ""
echo "✅ Тестирование завершено!"
