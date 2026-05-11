# 🔗 Интеграция OpenCode с OmniRoute Memory Management

**Дата**: 2026-05-11  
**Статус**: ✅ Настроено и готово к использованию

---

## 🎯 Что было сделано

Интегрирована система Memory Management из OmniRoute в OpenCode через MCP (Model Context Protocol). Теперь OpenCode может автоматически сохранять и извлекать контекст между сессиями.

---

## 📋 Архитектура решения

```
┌─────────────────────────────────────────────────────────────┐
│                      OpenCode Agent                          │
│                  (Build / Plan / Custom)                     │
└────────────────────────┬────────────────────────────────────┘
                         │ MCP Protocol (stdio)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              OmniRoute MCP Server                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Memory Tools (3):                                   │   │
│  │  - omniroute_memory_search   (поиск воспоминаний)   │   │
│  │  - omniroute_memory_add      (добавить память)      │   │
│  │  - omniroute_memory_clear    (очистить память)      │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP API
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              OmniRoute Memory System                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  SQLite Database (storage.sqlite)                    │   │
│  │  - memories table (4 типа памяти)                   │   │
│  │  - FTS5 полнотекстовый поиск                        │   │
│  │  - 3 стратегии: exact, semantic, hybrid             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Быстрый старт

### 1. Проверка конфигурации

MCP сервер уже настроен в двух местах:

**Глобальная конфигурация** (`~/.config/opencode/mcp-servers.json`):
```json
{
  "mcpServers": {
    "omniroute-memory": {
      "command": "npx",
      "args": [
        "tsx",
        "/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts"
      ],
      "env": {
        "OMNIROUTE_BASE_URL": "http://localhost:20128",
        "OMNIROUTE_API_KEY": "",
        "OMNIROUTE_MCP_ENFORCE_SCOPES": "false"
      }
    }
  }
}
```

**Проектная конфигурация** (`.opencode/mcp-servers.json`):
- Та же конфигурация для использования в этом проекте

### 2. Перезапуск OpenCode

Перезапустите OpenCode, чтобы загрузить MCP сервер:

```bash
# Выйдите из текущей сессии OpenCode
# Запустите заново
opencode
```

### 3. Проверка подключения

В OpenCode выполните команду для проверки доступных MCP инструментов:

```
Какие MCP инструменты доступны?
```

Вы должны увидеть 3 инструмента для работы с памятью:
- `omniroute_memory_search`
- `omniroute_memory_add`
- `omniroute_memory_clear`

---

## 💡 Как использовать

### Автоматическое сохранение контекста

OpenCode теперь может автоматически сохранять важную информацию:

**Пример 1: Сохранение предпочтений**
```
Запомни, что я предпочитаю использовать TypeScript с strict mode 
и функциональный стиль программирования.
```

OpenCode использует `omniroute_memory_add` для сохранения этой информации.

**Пример 2: Сохранение решений**
```
Мы решили использовать PostgreSQL вместо MongoDB для этого проекта 
из-за требований к транзакциям.
```

### Автоматическое извлечение контекста

При новой сессии OpenCode может извлекать релевантную память:

**Пример 3: Поиск предыдущих решений**
```
Какую базу данных мы решили использовать?
```

OpenCode использует `omniroute_memory_search` для поиска релевантной информации.

**Пример 4: Поиск по типу памяти**
```
Покажи все мои предпочтения по стилю кодирования
```

### Ручное управление памятью

Вы также можете явно управлять памятью:

**Добавить воспоминание:**
```
Используй omniroute_memory_add чтобы сохранить:
- Тип: factual
- Ключ: database_choice
- Содержание: Используем PostgreSQL 16 с расширением pgvector для векторного поиска
```

**Найти воспоминания:**
```
Используй omniroute_memory_search чтобы найти все воспоминания 
связанные с базой данных
```

**Очистить старые воспоминания:**
```
Используй omniroute_memory_clear чтобы удалить воспоминания старше 90 дней
```

---

## 🔧 Типы памяти

OmniRoute поддерживает 4 типа памяти:

### 1. **factual** (Факты)
Объективные факты о проекте, пользователе, технологиях.

**Примеры:**
- "Проект использует Next.js 15 с App Router"
- "API ключ хранится в переменной OPENAI_API_KEY"
- "Пользователь предпочитает русский язык"

### 2. **episodic** (Эпизоды)
События и действия, которые произошли.

**Примеры:**
- "2026-05-11: Настроили интеграцию с OmniRoute MCP"
- "Исправили баг с утечкой памяти в компоненте Dashboard"
- "Провели рефакторинг модуля аутентификации"

### 3. **procedural** (Процедуры)
Инструкции, процессы, как что-то делать.

**Примеры:**
- "Для деплоя: npm run build && docker-compose up -d"
- "Тесты запускаются через npm test -- --watch"
- "Миграции применяются автоматически при старте"

### 4. **semantic** (Семантика)
Концепции, определения, знания о домене.

**Примеры:**
- "Combo в OmniRoute - это цепочка моделей с fallback стратегией"
- "Memory Management использует FTS5 для полнотекстового поиска"
- "MCP - Model Context Protocol для интеграции AI инструментов"

---

## 🎓 Стратегии поиска

OmniRoute использует 3 стратегии поиска памяти:

### 1. **exact** (Точный)
Хронологический порядок, последние записи первыми.

**Когда использовать:**
- Нужны последние действия
- Важна хронология событий

### 2. **semantic** (Семантический)
FTS5 полнотекстовый поиск с оценкой релевантности.

**Когда использовать:**
- Поиск по ключевым словам
- Нужны наиболее релевантные результаты

### 3. **hybrid** (Гибридный) ⭐ Рекомендуется
Комбинация exact + semantic для лучших результатов.

**Когда использовать:**
- Универсальный поиск
- Баланс между релевантностью и хронологией

---

## 📊 Примеры использования

### Сценарий 1: Начало новой сессии

**Вы:** Привет! Продолжим работу над проектом.

**OpenCode:** 
1. Автоматически вызывает `omniroute_memory_search` с query="проект"
2. Находит релевантные воспоминания:
   - "Проект: free-ai-aggregator - AI gateway с 160+ провайдерами"
   - "Последняя задача: интеграция Memory Management с OpenCode"
   - "Используем Docker для деплоя, порт 20128"
3. Использует эту информацию для контекста

**OpenCode:** Привет! Вижу, что мы работаем над free-ai-aggregator. 
Последний раз настраивали Memory Management. Что будем делать дальше?

### Сценарий 2: Сохранение важного решения

**Вы:** Мы решили использовать Redis для кэширования вместо in-memory кэша.

**OpenCode:**
1. Вызывает `omniroute_memory_add`:
   - type: "factual"
   - key: "caching_decision"
   - content: "Используем Redis для кэширования вместо in-memory кэша"
2. Сохраняет в базу данных

**OpenCode:** Записал это решение. Теперь при следующей сессии я буду помнить, 
что мы используем Redis для кэширования.

### Сценарий 3: Поиск предыдущих решений

**Вы:** Какую систему кэширования мы используем?

**OpenCode:**
1. Вызывает `omniroute_memory_search` с query="кэширование"
2. Находит: "Используем Redis для кэширования вместо in-memory кэша"

**OpenCode:** Мы используем Redis для кэширования. Это решение было принято 
вместо in-memory кэша.

---

## 🔍 Отладка и мониторинг

### Проверка работы MCP сервера

```bash
# Проверить, что MCP сервер запускается
cd /home/creator/PROJECTS/free-ai-aggregator/OmniRoute
npx tsx open-sse/mcp-server/server.ts
```

Вы должны увидеть:
```
[DB] SQLite database ready: /home/creator/.omniroute/storage.sqlite
[MCP] OmniRoute MCP Server starting (stdio transport)...
[MCP] OmniRoute MCP Server connected and ready.
```

### Проверка памяти в базе данных

```bash
# Посмотреть все воспоминания
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const memories = db.prepare('SELECT * FROM memories ORDER BY created_at DESC LIMIT 10').all();
console.log(JSON.stringify(memories, null, 2));
"
```

### Проверка через Dashboard

Откройте Dashboard OmniRoute:
```
http://localhost:20128/dashboard/memory
```

Здесь вы можете:
- Просмотреть все воспоминания
- Фильтровать по типу
- Искать по содержимому
- Удалять ненужные записи

---

## ⚙️ Настройка

### Изменение лимита токенов

По умолчанию: 2000 токенов на запрос.

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Memory Settings
→ Max Tokens: 4000
```

**Через API:**
```bash
curl -X PATCH http://localhost:20128/api/settings \
  -H "Content-Type: application/json" \
  -d '{"memoryMaxTokens": 4000}'
```

### Изменение стратегии поиска

По умолчанию: hybrid

**Доступные стратегии:**
- `exact` - хронологический
- `semantic` - полнотекстовый поиск
- `hybrid` - комбинированный (рекомендуется)

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Memory Settings
→ Strategy: hybrid
```

### Изменение срока хранения

По умолчанию: 30 дней

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Memory Settings
→ Retention Days: 90
```

---

## 🚨 Troubleshooting

### Проблема: MCP сервер не подключается

**Решение 1:** Проверьте, что OmniRoute запущен
```bash
docker ps | grep omniroute
curl http://localhost:20128/api/health
```

**Решение 2:** Проверьте путь к серверу в конфигурации
```bash
ls -la /home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts
```

**Решение 3:** Проверьте логи OpenCode
```bash
# Логи OpenCode обычно в ~/.opencode/logs/
tail -f ~/.opencode/logs/latest.log
```

### Проблема: Инструменты памяти не видны

**Решение:** Перезапустите OpenCode
```bash
# Выйдите из OpenCode (Ctrl+C или /exit)
# Запустите заново
opencode
```

### Проблема: Память не сохраняется

**Решение 1:** Проверьте настройки Memory в OmniRoute
```bash
curl http://localhost:20128/api/settings | jq '.memoryEnabled'
# Должно быть: true
```

**Решение 2:** Проверьте базу данных
```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const count = db.prepare('SELECT COUNT(*) as count FROM memories').get();
console.log('Memories count:', count.count);
"
```

---

## 📚 Дополнительные ресурсы

### Документация OmniRoute Memory
- **Полная документация**: `MEMORY_SKILLS_CONFIG.md`
- **Быстрый старт**: `QUICKSTART_MEMORY_SKILLS.md`
- **Сводка**: `MEMORY_SKILLS_SUMMARY.md`

### Документация OpenCode MCP
- **OpenCode MCP серверы**: https://opencode.ai/docs/mcp-servers/
- **Создание MCP сервера**: https://opencode.ai/docs/plugins/

### API Reference

**Memory API endpoints:**
- `GET /api/memory` - список воспоминаний
- `POST /api/memory` - создать воспоминание
- `GET /api/memory/:id` - получить воспоминание
- `PATCH /api/memory/:id` - обновить воспоминание
- `DELETE /api/memory/:id` - удалить воспоминание

**MCP Tools:**
- `omniroute_memory_search(query, type?, maxTokens?)` - поиск
- `omniroute_memory_add(type, key, content, metadata?)` - добавить
- `omniroute_memory_clear(type?, olderThan?)` - очистить

---

## ✅ Чеклист готовности

- [x] OmniRoute запущен и работает
- [x] Memory Management включен
- [x] MCP сервер настроен
- [x] Конфигурация OpenCode создана
- [x] Документация написана
- [ ] OpenCode перезапущен с новой конфигурацией
- [ ] Протестирована работа memory tools
- [ ] Создано первое воспоминание

---

## 🎉 Следующие шаги

1. **Перезапустите OpenCode** чтобы загрузить MCP сервер
2. **Протестируйте** сохранение и извлечение памяти
3. **Создайте первое воспоминание** о вашем проекте
4. **Начните новую сессию** и проверьте, что контекст сохранился

---

**Создано**: 2026-05-11  
**Автор**: OpenCode AI Assistant  
**Статус**: ✅ Готово к использованию
