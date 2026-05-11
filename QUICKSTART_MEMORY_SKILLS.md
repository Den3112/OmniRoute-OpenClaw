# 🚀 Быстрый старт: Memory & Skills в OmniRoute

## ✅ Текущий статус

**Дата проверки**: 2026-05-10

```
✅ Memory Management: ВКЛЮЧЕНО
✅ Skills System: ВКЛЮЧЕНО
✅ MCP Server: РАБОТАЕТ
✅ База данных: НАСТРОЕНА
✅ API Endpoints: ДОСТУПНЫ
```

---

## 📋 Текущая конфигурация

### Memory Settings
```json
{
  "memoryEnabled": true,
  "memoryMaxTokens": 2000,
  "memoryRetentionDays": 30,
  "memoryStrategy": "hybrid"
}
```

### Skills Settings
```json
{
  "skillsEnabled": true,
  "skillsmpApiKey": "sk_live_skillsmp_I7fRCYDrzngcjUl8VQOD1r5Xp9uc_hs6XGaF0WFENFo"
}
```

---

## 🎯 Быстрые команды

### 1. Проверка статуса

```bash
# Проверить контейнеры
docker ps | grep omniroute

# Проверить логи
docker logs omniroute --tail 50

# Проверить базу данных
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
console.log('Memories:', db.prepare('SELECT COUNT(*) as count FROM memories').get());
console.log('Skills:', db.prepare('SELECT COUNT(*) as count FROM skills').get());
"
```

### 2. Работа с Memory через API

```bash
# Создать воспоминание
curl -X POST http://localhost:20128/api/memory \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "type": "factual",
    "key": "user_language",
    "content": "Пользователь предпочитает русский язык",
    "metadata": {"source": "manual"}
  }'

# Поиск воспоминаний
curl "http://localhost:20128/api/memory?query=язык" \
  -H "Authorization: Bearer YOUR_API_KEY"

# Список всех воспоминаний
curl "http://localhost:20128/api/memory?limit=10" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### 3. Работа со Skills через API

```bash
# Список навыков
curl http://localhost:20128/api/skills \
  -H "Authorization: Bearer YOUR_API_KEY"

# Установить навык из маркетплейса
curl -X POST http://localhost:20128/api/skills/marketplace/install \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "skillId": "web-search",
    "version": "1.0.0"
  }'

# История выполнения
curl http://localhost:20128/api/skills/executions \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### 4. MCP инструменты

```bash
# Список MCP инструментов
curl http://localhost:20128/api/mcp/tools

# Memory Search через MCP
curl -X POST http://localhost:20128/api/mcp/stream \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "omniroute_memory_search",
      "arguments": {
        "query": "user preferences",
        "maxTokens": 1000
      }
    }
  }'

# Skills List через MCP
curl -X POST http://localhost:20128/api/mcp/stream \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "omniroute_skills_list",
      "arguments": {
        "enabled": true
      }
    }
  }'
```

---

## 🔧 Изменение настроек

### Через Dashboard (Рекомендуется)

1. Откройте: http://localhost:20128/dashboard/settings
2. Найдите секцию "Memory Settings"
3. Измените параметры
4. Нажмите "Save"

### Через базу данных

```bash
# Увеличить лимит токенов для памяти
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
db.prepare('UPDATE key_value SET value = ? WHERE namespace = ? AND key = ?')
  .run('4000', 'settings', 'memoryMaxTokens');
console.log('Updated memoryMaxTokens to 4000');
"

# Изменить стратегию памяти на semantic
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
db.prepare('UPDATE key_value SET value = ? WHERE namespace = ? AND key = ?')
  .run('\"semantic\"', 'settings', 'memoryStrategy');
console.log('Updated memoryStrategy to semantic');
"

# Увеличить срок хранения до 90 дней
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
db.prepare('UPDATE key_value SET value = ? WHERE namespace = ? AND key = ?')
  .run('90', 'settings', 'memoryRetentionDays');
console.log('Updated memoryRetentionDays to 90');
"
```

### Через переменные окружения

Добавьте в `.env`:
```bash
# Memory
MEMORY_ENABLED=true
MEMORY_MAX_TOKENS=4000
MEMORY_RETENTION_DAYS=90
MEMORY_STRATEGY=semantic

# Skills
SKILLS_ENABLED=true
SKILLS_PROVIDER=skillsmp
SKILLSMP_API_KEY=sk_live_...
```

Перезапустите контейнер:
```bash
docker restart omniroute
```

---

## 📊 Мониторинг

### Статистика памяти

```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');

console.log('=== Memory Statistics ===');
const stats = db.prepare(\`
  SELECT 
    type,
    COUNT(*) as count,
    AVG(LENGTH(content)) as avg_size,
    MAX(LENGTH(content)) as max_size
  FROM memories
  GROUP BY type
\`).all();

stats.forEach(s => {
  console.log(\`\${s.type}: \${s.count} entries, avg size: \${Math.round(s.avg_size)} bytes\`);
});

const total = db.prepare('SELECT COUNT(*) as count FROM memories').get();
console.log(\`Total memories: \${total.count}\`);
"
```

### Статистика навыков

```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');

console.log('=== Skills Statistics ===');
const skills = db.prepare(\`
  SELECT 
    s.name,
    s.version,
    s.enabled,
    s.mode,
    s.source_provider,
    COUNT(se.id) as executions
  FROM skills s
  LEFT JOIN skill_executions se ON s.id = se.skill_id
  GROUP BY s.id
\`).all();

skills.forEach(s => {
  console.log(\`\${s.name} v\${s.version}: \${s.executions} executions, mode: \${s.mode}, enabled: \${s.enabled}\`);
});

console.log(\`Total skills: \${skills.length}\`);
"
```

### Последние выполнения навыков

```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');

console.log('=== Recent Skill Executions ===');
const executions = db.prepare(\`
  SELECT 
    s.name,
    se.status,
    se.duration_ms,
    se.created_at,
    se.error_message
  FROM skill_executions se
  JOIN skills s ON se.skill_id = s.id
  ORDER BY se.created_at DESC
  LIMIT 10
\`).all();

executions.forEach(e => {
  const status = e.status === 'success' ? '✅' : '❌';
  console.log(\`\${status} \${e.name}: \${e.status} (\${e.duration_ms}ms) - \${e.created_at}\`);
  if (e.error_message) console.log(\`   Error: \${e.error_message}\`);
});
"
```

---

## 🧪 Тестирование

### Тест Memory

```bash
# 1. Создать тестовое воспоминание
curl -X POST http://localhost:20128/api/memory \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "type": "factual",
    "key": "test_memory",
    "content": "This is a test memory for verification"
  }'

# 2. Найти его
curl "http://localhost:20128/api/memory?query=test" \
  -H "Authorization: Bearer YOUR_API_KEY"

# 3. Удалить (замените MEMORY_ID)
curl -X DELETE http://localhost:20128/api/memory/MEMORY_ID \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Тест Skills

```bash
# 1. Проверить встроенные навыки
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const builtins = db.prepare('SELECT name, enabled FROM skills WHERE source_provider = ?').all('local');
console.log('Built-in skills:', builtins);
"

# 2. Выполнить тестовый навык (если есть)
curl -X POST http://localhost:20128/api/mcp/stream \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "omniroute_skills_execute",
      "arguments": {
        "skillName": "web_search",
        "version": "1.0.0",
        "input": {
          "query": "OmniRoute documentation"
        }
      }
    }
  }'
```

---

## 🐛 Troubleshooting

### Memory не сохраняется

```bash
# Проверить настройки
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const settings = db.prepare('SELECT key, value FROM key_value WHERE namespace = ? AND key LIKE ?').all('settings', '%memory%');
console.log('Memory settings:', settings);
"

# Проверить таблицу
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const info = db.prepare('PRAGMA table_info(memories)').all();
console.log('Memories table structure:', info);
"

# Проверить права доступа
docker exec omniroute ls -la /app/data/storage.sqlite
```

### Skills не выполняются

```bash
# Проверить глобальное включение
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const enabled = db.prepare('SELECT value FROM key_value WHERE namespace = ? AND key = ?').get('settings', 'skillsEnabled');
console.log('Skills enabled:', enabled);
"

# Проверить Docker (для sandbox)
docker ps
docker info | grep -i "Server Version"

# Проверить логи ошибок
docker logs omniroute 2>&1 | grep -i "skill" | tail -20
```

### MCP инструменты недоступны

```bash
# Проверить эндпоинт
curl -I http://localhost:20128/api/mcp/tools

# Проверить процесс
docker exec omniroute ps aux | grep node

# Проверить порты
docker port omniroute
```

---

## 📚 Полезные ссылки

- **Полная документация**: `/home/creator/PROJECTS/free-ai-aggregator/MEMORY_SKILLS_CONFIG.md`
- **Dashboard**: http://localhost:20128/dashboard
- **API Docs**: http://localhost:20128/api/docs
- **MCP Tools**: http://localhost:20128/api/mcp/tools
- **Health Check**: http://localhost:20128/api/health

---

## 🎓 Примеры использования

### Пример 1: Сохранение предпочтений пользователя

```javascript
// В вашем AI-агенте
const userPreference = {
  type: "factual",
  key: "ui_theme",
  content: "User prefers dark mode with blue accent",
  metadata: { source: "conversation", confidence: 0.95 }
};

await fetch('http://localhost:20128/api/memory', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_API_KEY'
  },
  body: JSON.stringify(userPreference)
});
```

### Пример 2: Извлечение контекста для запроса

```javascript
// Получить релевантную память перед запросом
const memories = await fetch(
  'http://localhost:20128/api/memory?query=user preferences&maxTokens=1000',
  {
    headers: { 'Authorization': 'Bearer YOUR_API_KEY' }
  }
).then(r => r.json());

// Добавить в контекст
const systemMessage = {
  role: "system",
  content: `User context: ${memories.map(m => m.content).join('; ')}`
};
```

### Пример 3: Использование навыка через MCP

```javascript
// Выполнить веб-поиск через навык
const result = await fetch('http://localhost:20128/api/mcp/stream', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    method: "tools/call",
    params: {
      name: "omniroute_skills_execute",
      arguments: {
        skillName: "web_search",
        version: "1.0.0",
        input: { query: "latest AI news" }
      }
    }
  })
}).then(r => r.json());

console.log('Search results:', result);
```

---

## ⚡ Оптимизация производительности

### Для высоконагруженных систем

```bash
# Увеличить кэш памяти
docker exec omniroute node -e "
// В коде: src/lib/memory/cache.ts
// Увеличить MAX_CACHE_SIZE с 10000 до 50000
// Увеличить CACHE_TTL_MS с 300000 до 600000
"

# Оптимизировать FTS5
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
db.prepare('INSERT INTO memory_fts(memory_fts) VALUES(\"optimize\")').run();
console.log('FTS5 index optimized');
"

# Очистить старые воспоминания
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const deleted = db.prepare('DELETE FROM memories WHERE created_at < datetime(\"now\", \"-90 days\")').run();
console.log('Deleted old memories:', deleted.changes);
"
```

---

## 🔐 Безопасность

### Рекомендации

1. **API ключи**: Используйте уникальные ключи для каждого клиента
2. **Sandbox**: Skills выполняются в изолированном Docker контейнере
3. **Лимиты**: Настройте лимиты на размер файлов и время выполнения
4. **Аудит**: Все действия логируются в `skill_executions` и `mcp_audit`

### Проверка безопасности

```bash
# Проверить изоляцию sandbox
docker exec omniroute docker ps | grep skill-sandbox

# Проверить лимиты ресурсов
docker exec omniroute docker stats --no-stream

# Аудит последних действий
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const audit = db.prepare('SELECT * FROM mcp_audit ORDER BY created_at DESC LIMIT 10').all();
console.log('Recent MCP actions:', audit);
"
```

---

**Последнее обновление**: 2026-05-10
**Версия**: 1.0.0
**Статус**: ✅ Production Ready
