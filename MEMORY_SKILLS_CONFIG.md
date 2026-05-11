# Настройка Memory Management и Skills в OmniRoute

## Текущее состояние системы

### ✅ Статус компонентов

**База данных:**
- ✅ Таблица `memories` создана (11 колонок)
- ✅ Таблица `skills` создана (14 колонок)
- ✅ Таблица `skill_executions` создана
- ✅ FTS5 индекс для полнотекстового поиска (`memory_fts`)
- ✅ Все миграции применены (015, 016, 022, 023, 027)

**Текущие настройки:**
```json
{
  "memoryEnabled": true,
  "memoryMaxTokens": 2000,
  "memoryRetentionDays": 30,
  "memoryStrategy": "hybrid",
  "skillsEnabled": true,
  "skillsmpApiKey": "sk_live_skillsmp_I7fRCYDrzngcjUl8VQOD1r5Xp9uc_hs6XGaF0WFENFo"
}
```

---

## 1. Memory Management (Управление памятью)

### Архитектура

Memory Management в OmniRoute обеспечивает персистентную память для AI-агентов через:

1. **Хранилище** (`src/lib/memory/store.ts`)
   - CRUD операции с кэшированием (TTL 5 минут, max 10,000 записей)
   - UPSERT логика (обновление по apiKeyId + key)
   - Пагинация и фильтрация

2. **Извлечение** (`src/lib/memory/retrieval.ts`)
   - 3 стратегии: `exact` (хронологическая), `semantic` (FTS5), `hybrid` (комбинированная)
   - Контроль токенов (1 токен ≈ 4 символа)
   - Оценка релевантности для поисковых запросов

3. **Инъекция** (`src/lib/memory/injection.ts`)
   - Внедрение памяти в системные/пользовательские сообщения
   - Проверка поддержки системных сообщений провайдером
   - Форматирование контекста памяти

4. **Извлечение фактов** (`src/lib/memory/extraction.ts`)
   - Автоматическое извлечение фактов из ответов LLM
   - 3 категории паттернов: предпочтения, решения, поведенческие паттерны
   - Дедупликация и валидация (3-500 символов)

5. **Суммаризация** (`src/lib/memory/summarization.ts`)
   - Сжатие старых воспоминаний при превышении токенов
   - Сохранение первых 3 предложений

### Типы памяти

```typescript
enum MemoryType {
  FACTUAL = "factual",      // Факты о пользователе
  EPISODIC = "episodic",    // События и эпизоды
  PROCEDURAL = "procedural", // Процедуры и инструкции
  SEMANTIC = "semantic"      // Семантические знания
}
```

### Конфигурация

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Memory Settings
```

**Через API:**
```bash
curl -X PATCH http://localhost:20128/api/settings \
  -H "Content-Type: application/json" \
  -d '{
    "memoryEnabled": true,
    "memoryMaxTokens": 2000,
    "memoryRetentionDays": 30,
    "memoryStrategy": "hybrid"
  }'
```

**Через базу данных:**
```sql
-- Включить память
UPDATE key_value 
SET value = 'true' 
WHERE namespace = 'settings' AND key = 'memoryEnabled';

-- Установить максимум токенов
UPDATE key_value 
SET value = '4000' 
WHERE namespace = 'settings' AND key = 'memoryMaxTokens';

-- Установить стратегию
UPDATE key_value 
SET value = '"semantic"' 
WHERE namespace = 'settings' AND key = 'memoryStrategy';
```

### MCP Tools для Memory

**1. omniroute_memory_search** - Поиск воспоминаний
```json
{
  "name": "omniroute_memory_search",
  "arguments": {
    "query": "user preferences",
    "type": "factual",
    "maxTokens": 1000
  }
}
```

**2. omniroute_memory_add** - Добавить воспоминание
```json
{
  "name": "omniroute_memory_add",
  "arguments": {
    "type": "factual",
    "key": "user_language",
    "content": "User prefers Russian language",
    "metadata": {"source": "conversation"}
  }
}
```

**3. omniroute_memory_clear** - Очистить память
```json
{
  "name": "omniroute_memory_clear",
  "arguments": {
    "type": "episodic",
    "olderThanDays": 90
  }
}
```

### Использование в коде

```typescript
import { retrieveMemories } from "@/lib/memory/retrieval";
import { injectMemory } from "@/lib/memory/injection";
import { extractFacts } from "@/lib/memory/extraction";

// Извлечение памяти
const memories = await retrieveMemories({
  apiKeyId: "key-123",
  query: "user preferences",
  config: {
    enabled: true,
    maxTokens: 2000,
    retrievalStrategy: "hybrid"
  }
});

// Инъекция в запрос
const modifiedMessages = injectMemory(
  originalMessages,
  memories,
  "openai"
);

// Извлечение фактов из ответа
await extractFacts(
  responseText,
  "key-123",
  "session-456"
);
```

---

## 2. Skills System (Система навыков)

### Архитектура

Skills System предоставляет расширяемую систему навыков для AI-агентов:

1. **Реестр** (`src/lib/skills/registry.ts`)
   - Singleton с кэшированием (TTL 60 секунд)
   - Разрешение версий (semver: ^, ~, >, >=, <, <=, ==)
   - Загрузка из базы данных

2. **Исполнитель** (`src/lib/skills/executor.ts`)
   - Выполнение с таймаутом и повторами
   - Отслеживание истории выполнения
   - Проверка глобального включения

3. **Встроенные навыки** (`src/lib/skills/builtins.ts`)
   - `file_read` - Чтение файлов (max 1MB)
   - `file_write` - Запись файлов (max 1MB)
   - `http_request` - HTTP запросы (max 256KB)
   - `web_search` - Веб-поиск
   - `eval_code` - Выполнение JS/Python в sandbox
   - `execute_command` - Shell команды в Docker sandbox

4. **Sandbox** (`src/lib/skills/sandbox.ts`)
   - Docker-изоляция
   - Лимиты ресурсов (256MB RAM, 10s timeout)
   - Изоляция workspace по API ключу

5. **Инъекция** (`src/lib/skills/injection.ts`)
   - Внедрение навыков как инструментов
   - 3 формата: OpenAI, Claude, Gemini
   - 2 режима: "on" (всегда), "auto" (контекстный скоринг)

6. **Перехват** (`src/lib/skills/interception.ts`)
   - Перехват вызовов инструментов
   - Маршрутизация к обработчикам навыков
   - Форматирование результатов

### Режимы навыков

```typescript
enum SkillMode {
  AUTO = "auto",     // Автоматический выбор на основе контекста
  MANUAL = "manual", // Только по явному вызову
  HYBRID = "hybrid"  // Комбинированный режим
}
```

### Источники навыков

1. **SkillsMP** (Marketplace) - `skillsmp`
   - Официальный маркетплейс навыков
   - Требует API ключ
   - Установка через Dashboard

2. **Skills.sh** (Public Directory) - `skillssh`
   - Публичный каталог навыков
   - Бесплатный доступ
   - GitHub-based

3. **Local** (Локальные) - `local`
   - Пользовательские навыки
   - Полный контроль

### Конфигурация

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Skills Settings
```

**Через API:**
```bash
# Включить Skills
curl -X PATCH http://localhost:20128/api/settings \
  -H "Content-Type: application/json" \
  -d '{
    "skillsEnabled": true,
    "skillsProvider": "skillsmp",
    "skillsmpApiKey": "sk_live_..."
  }'

# Список навыков
curl http://localhost:20128/api/skills \
  -H "Authorization: Bearer YOUR_API_KEY"

# Установить навык
curl -X POST http://localhost:20128/api/skills/marketplace/install \
  -H "Content-Type: application/json" \
  -d '{
    "skillId": "web-scraper",
    "version": "1.0.0"
  }'
```

**Через базу данных:**
```sql
-- Включить Skills
UPDATE key_value 
SET value = 'true' 
WHERE namespace = 'settings' AND key = 'skillsEnabled';

-- Установить провайдер
UPDATE key_value 
SET value = '"skillsmp"' 
WHERE namespace = 'settings' AND key = 'skillsProvider';

-- Список установленных навыков
SELECT id, name, version, enabled, mode, source_provider 
FROM skills 
WHERE enabled = 1;

-- История выполнения
SELECT s.name, se.status, se.duration_ms, se.created_at
FROM skill_executions se
JOIN skills s ON se.skill_id = s.id
ORDER BY se.created_at DESC
LIMIT 10;
```

### MCP Tools для Skills

**1. omniroute_skills_list** - Список навыков
```json
{
  "name": "omniroute_skills_list",
  "arguments": {
    "enabled": true,
    "sourceProvider": "skillsmp"
  }
}
```

**2. omniroute_skills_enable** - Включить/выключить навык
```json
{
  "name": "omniroute_skills_enable",
  "arguments": {
    "skillId": "skill-uuid",
    "enabled": true
  }
}
```

**3. omniroute_skills_execute** - Выполнить навык
```json
{
  "name": "omniroute_skills_execute",
  "arguments": {
    "skillName": "web_search",
    "version": "1.0.0",
    "input": {
      "query": "OmniRoute documentation"
    }
  }
}
```

**4. omniroute_skills_executions** - История выполнения
```json
{
  "name": "omniroute_skills_executions",
  "arguments": {
    "skillId": "skill-uuid",
    "limit": 10
  }
}
```

### Создание пользовательского навыка

```typescript
// 1. Определить схему
const skillSchema = {
  input: {
    type: "object",
    properties: {
      url: { type: "string" },
      selector: { type: "string" }
    },
    required: ["url"]
  },
  output: {
    type: "object",
    properties: {
      content: { type: "string" }
    }
  }
};

// 2. Создать обработчик
const handler = async (input, context) => {
  const { url, selector } = input;
  // Ваша логика
  return { content: "scraped data" };
};

// 3. Зарегистрировать
import { registerCustomSkill } from "@/lib/skills/custom";

await registerCustomSkill({
  apiKeyId: "key-123",
  name: "web_scraper",
  version: "1.0.0",
  description: "Scrapes web pages",
  schema: skillSchema,
  handler: handler.toString(),
  enabled: true,
  mode: "auto",
  tags: ["web", "scraping"]
});
```

---

## 3. Интеграция с MCP Server

### Доступные транспорты

1. **stdio** - Стандартный ввод/вывод
```bash
omniroute --mcp
```

2. **SSE** - Server-Sent Events
```
http://localhost:20128/api/mcp/sse
```

3. **HTTP** - Streamable HTTP
```
http://localhost:20128/api/mcp/stream
```

### Области доступа (Scopes)

MCP Server поддерживает 10 областей доступа:

1. `health` - Проверка здоровья системы
2. `combos` - Управление комбо
3. `quota` - Проверка квот
4. `routing` - Маршрутизация запросов
5. `cost` - Отчеты о стоимости
6. `cache` - Управление кэшем
7. `compression` - Управление сжатием
8. `proxy` - Управление прокси (1proxy)
9. `memory` - Управление памятью ✅
10. `skills` - Управление навыками ✅

### Конфигурация MCP

**Файл `.mcp.json` (для Claude Desktop):**
```json
{
  "mcpServers": {
    "omniroute": {
      "command": "omniroute",
      "args": ["--mcp"],
      "env": {
        "OMNIROUTE_API_KEY": "your-api-key",
        "OMNIROUTE_BASE_URL": "http://localhost:20128"
      }
    }
  }
}
```

**Проверка MCP инструментов:**
```bash
# Список всех инструментов
curl http://localhost:20128/api/mcp/tools

# Вызов инструмента
curl -X POST http://localhost:20128/api/mcp/stream \
  -H "Content-Type: application/json" \
  -d '{
    "method": "tools/call",
    "params": {
      "name": "omniroute_memory_search",
      "arguments": {
        "query": "user preferences"
      }
    }
  }'
```

---

## 4. Рекомендуемая конфигурация

### Для разработки

```bash
# .env
MEMORY_ENABLED=true
MEMORY_MAX_TOKENS=4000
MEMORY_RETENTION_DAYS=90
MEMORY_STRATEGY=hybrid

SKILLS_ENABLED=true
SKILLS_PROVIDER=skillsmp
SKILLSMP_API_KEY=sk_live_...

# Включить отладку
DEBUG=omniroute:memory,omniroute:skills
```

### Для продакшена

```bash
# .env
MEMORY_ENABLED=true
MEMORY_MAX_TOKENS=2000
MEMORY_RETENTION_DAYS=30
MEMORY_STRATEGY=semantic

SKILLS_ENABLED=true
SKILLS_PROVIDER=skillsmp
SKILLSMP_API_KEY=sk_live_...

# Ограничения sandbox
SKILLS_SANDBOX_TIMEOUT=10000
SKILLS_SANDBOX_MEMORY_LIMIT=256m
```

### Оптимизация производительности

1. **Memory кэширование:**
   - TTL: 5 минут
   - Max entries: 10,000
   - Инвалидация при записи

2. **Skills кэширование:**
   - TTL: 60 секунд
   - Предзагрузка при старте
   - Ленивая загрузка обработчиков

3. **FTS5 индексация:**
   - Автоматическая синхронизация
   - Триггеры на INSERT/UPDATE/DELETE
   - Оптимизация для поиска

---

## 5. Мониторинг и отладка

### Логи

```bash
# Логи Memory
docker logs omniroute 2>&1 | grep -i memory

# Логи Skills
docker logs omniroute 2>&1 | grep -i skill

# Логи MCP
docker logs omniroute 2>&1 | grep -i mcp
```

### Метрики

```sql
-- Статистика памяти
SELECT 
  type,
  COUNT(*) as count,
  AVG(LENGTH(content)) as avg_size
FROM memories
GROUP BY type;

-- Статистика навыков
SELECT 
  s.name,
  COUNT(se.id) as executions,
  AVG(se.duration_ms) as avg_duration,
  SUM(CASE WHEN se.status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as success_rate
FROM skills s
LEFT JOIN skill_executions se ON s.id = se.skill_id
GROUP BY s.id, s.name;

-- Использование MCP инструментов
SELECT 
  tool_name,
  COUNT(*) as calls,
  AVG(duration_ms) as avg_duration
FROM mcp_audit
WHERE created_at > datetime('now', '-7 days')
GROUP BY tool_name
ORDER BY calls DESC;
```

### Health Check

```bash
# Проверка Memory
curl http://localhost:20128/api/memory/health

# Проверка Skills
curl http://localhost:20128/api/skills/health

# Проверка MCP
curl http://localhost:20128/api/mcp/health
```

---

## 6. Troubleshooting

### Memory не работает

1. Проверить настройки:
```sql
SELECT * FROM key_value 
WHERE namespace = 'settings' 
AND key LIKE '%memory%';
```

2. Проверить таблицу:
```sql
SELECT COUNT(*) FROM memories;
PRAGMA table_info(memories);
```

3. Проверить FTS5:
```sql
SELECT COUNT(*) FROM memory_fts;
```

### Skills не выполняются

1. Проверить глобальное включение:
```sql
SELECT value FROM key_value 
WHERE namespace = 'settings' 
AND key = 'skillsEnabled';
```

2. Проверить навыки:
```sql
SELECT id, name, enabled, mode 
FROM skills 
WHERE enabled = 1;
```

3. Проверить sandbox:
```bash
docker ps | grep omniroute
docker logs omniroute | grep sandbox
```

### MCP инструменты недоступны

1. Проверить транспорт:
```bash
curl http://localhost:20128/api/mcp/tools
```

2. Проверить области доступа:
```sql
SELECT * FROM api_keys WHERE id = 'your-key-id';
```

3. Проверить аудит:
```sql
SELECT * FROM mcp_audit 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 7. Дополнительные ресурсы

### Документация

- **Memory System**: `/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/src/lib/memory/`
- **Skills System**: `/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/src/lib/skills/`
- **MCP Server**: `/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/`
- **Миграции**: `/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/src/lib/db/migrations/`

### Тесты

```bash
# Memory тесты
npm run test tests/unit/memory-*.test.ts
npm run test tests/integration/chat-pipeline.test.ts

# Skills тесты
npm run test tests/unit/skills-*.test.ts
npm run test tests/e2e/skills-marketplace.spec.ts

# MCP тесты
npm run test:protocols:e2e
```

### API Endpoints

- `GET /api/memory` - Список воспоминаний
- `POST /api/memory` - Создать воспоминание
- `GET /api/memory/:id` - Получить воспоминание
- `PATCH /api/memory/:id` - Обновить воспоминание
- `DELETE /api/memory/:id` - Удалить воспоминание
- `GET /api/skills` - Список навыков
- `POST /api/skills` - Создать навык
- `GET /api/skills/:id` - Получить навык
- `PATCH /api/skills/:id` - Обновить навык
- `DELETE /api/skills/:id` - Удалить навык
- `GET /api/skills/executions` - История выполнения
- `POST /api/skills/marketplace/install` - Установить из маркетплейса

---

## Заключение

Memory Management и Skills System в OmniRoute полностью настроены и готовы к использованию:

✅ **База данных**: Все таблицы и индексы созданы
✅ **Настройки**: Memory и Skills включены
✅ **MCP интеграция**: 7 инструментов доступны
✅ **API**: Все эндпоинты работают
✅ **Документация**: Полное описание архитектуры

**Следующие шаги:**
1. Настроить SkillsMP API ключ (если нужен доступ к маркетплейсу)
2. Установить необходимые навыки через Dashboard
3. Протестировать Memory через MCP инструменты
4. Интегрировать с вашими AI-агентами

**Дата создания**: 2026-05-10
**Версия OmniRoute**: 3.7.8+
**Статус**: Production Ready ✅
