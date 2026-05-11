# 🎉 Интеграция OpenCode + OmniRoute Memory: Краткая инструкция

**Дата**: 2026-05-11  
**Статус**: ✅ Полностью настроено и протестировано

---

## ✅ Что сделано

1. ✅ Настроен MCP сервер OmniRoute с Memory Management
2. ✅ Создана конфигурация для OpenCode (глобальная и проектная)
3. ✅ Memory Management включен в OmniRoute
4. ✅ Протестирована работа системы
5. ✅ Создана полная документация

---

## 🚀 Быстрый старт (3 шага)

### Шаг 1: Перезапустите OpenCode

```bash
# Выйдите из текущей сессии OpenCode (если запущена)
# Запустите заново в этой директории
cd /home/creator/PROJECTS/free-ai-aggregator
opencode
```

### Шаг 2: Проверьте MCP инструменты

В OpenCode спросите:
```
Какие MCP инструменты доступны?
```

Вы должны увидеть 3 инструмента памяти:
- `omniroute_memory_search` - поиск воспоминаний
- `omniroute_memory_add` - добавить воспоминание
- `omniroute_memory_clear` - очистить память

### Шаг 3: Протестируйте

**Сохранение:**
```
Запомни, что этот проект называется free-ai-aggregator 
и это AI gateway с поддержкой 160+ провайдеров.
```

**Извлечение (в новой сессии):**
```
Как называется этот проект и что он делает?
```

---

## 📊 Текущее состояние

### OmniRoute
- ✅ Контейнер запущен: `omniroute`
- ✅ API доступен: `http://localhost:20128`
- ✅ Memory Management: **включен**
- ✅ Воспоминаний в базе: 1 (тестовое)

### MCP Сервер
- ✅ Путь: `/home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts`
- ✅ Транспорт: stdio
- ✅ Инструментов: 30+ (включая 3 memory tools)

### OpenCode Конфигурация
- ✅ Глобальная: `~/.config/opencode/mcp-servers.json`
- ✅ Проектная: `.opencode/mcp-servers.json`
- ✅ Сервер: `omniroute-memory`

---

## 💡 Примеры использования

### Автоматическое сохранение

OpenCode автоматически сохраняет важную информацию:

```
Мы решили использовать PostgreSQL для этого проекта.
```

→ OpenCode вызовет `omniroute_memory_add` и сохранит это решение.

### Автоматическое извлечение

При новой сессии OpenCode извлекает релевантную память:

```
Какую базу данных мы используем?
```

→ OpenCode вызовет `omniroute_memory_search` и найдет сохраненное решение.

### Типы памяти

- **factual** - факты о проекте
- **episodic** - события и действия
- **procedural** - инструкции и процессы
- **semantic** - концепции и определения

---

## 🔧 Настройки

### Текущие настройки Memory

- **Включено**: true
- **Макс токенов**: 2000
- **Срок хранения**: 30 дней
- **Стратегия**: hybrid (exact + semantic)

### Изменить настройки

**Через Dashboard:**
```
http://localhost:20128/dashboard/settings
→ Memory Settings
```

**Через API:**
```bash
curl -X PATCH http://localhost:20128/api/settings \
  -H "Content-Type: application/json" \
  -d '{"memoryMaxTokens": 4000}'
```

---

## 📚 Документация

### Основные файлы

1. **OPENCODE_MEMORY_INTEGRATION.md** - полная инструкция (вы здесь)
2. **MEMORY_SKILLS_CONFIG.md** - техническая документация OmniRoute
3. **MEMORY_SKILLS_SUMMARY.md** - краткая сводка системы
4. **test-opencode-memory.sh** - скрипт тестирования

### Запустить тест

```bash
./test-opencode-memory.sh
```

### Просмотр памяти

**Dashboard:**
```
http://localhost:20128/dashboard/memory
```

**Через базу данных:**
```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const memories = db.prepare('SELECT * FROM memories ORDER BY created_at DESC LIMIT 10').all();
console.log(JSON.stringify(memories, null, 2));
"
```

---

## 🎯 Как это работает

```
┌─────────────────────────────────────────────────────────────┐
│  OpenCode Agent                                              │
│  "Запомни, что проект использует TypeScript"                │
└────────────────────────┬────────────────────────────────────┘
                         │ MCP Protocol (stdio)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  OmniRoute MCP Server                                        │
│  omniroute_memory_add(                                       │
│    type: "factual",                                          │
│    key: "tech_stack",                                        │
│    content: "Проект использует TypeScript"                  │
│  )                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP API
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  OmniRoute Memory System                                     │
│  SQLite: memories table                                      │
│  FTS5: полнотекстовый поиск                                 │
│  Стратегия: hybrid (exact + semantic)                       │
└─────────────────────────────────────────────────────────────┘
```

При следующей сессии:

```
┌─────────────────────────────────────────────────────────────┐
│  OpenCode Agent (новая сессия)                               │
│  "Какой язык программирования мы используем?"                │
└────────────────────────┬────────────────────────────────────┘
                         │ MCP Protocol
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  OmniRoute MCP Server                                        │
│  omniroute_memory_search(                                    │
│    query: "язык программирования",                           │
│    maxTokens: 2000                                           │
│  )                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Результат: "Проект использует TypeScript"                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚨 Troubleshooting

### MCP сервер не подключается

1. Проверьте OmniRoute:
   ```bash
   docker ps | grep omniroute
   ```

2. Проверьте путь к серверу:
   ```bash
   ls -la /home/creator/PROJECTS/free-ai-aggregator/OmniRoute/open-sse/mcp-server/server.ts
   ```

3. Перезапустите OpenCode

### Память не сохраняется

1. Проверьте, что Memory включен:
   ```bash
   docker exec omniroute node -e "
   const db = require('better-sqlite3')('/app/data/storage.sqlite');
   const result = db.prepare('SELECT value FROM key_value WHERE namespace = \"settings\" AND key = \"memoryEnabled\"').get();
   console.log(result.value);
   "
   ```

2. Если `false`, включите:
   ```bash
   docker exec omniroute node -e "
   const db = require('better-sqlite3')('/app/data/storage.sqlite');
   db.prepare('UPDATE key_value SET value = \"true\" WHERE namespace = \"settings\" AND key = \"memoryEnabled\"').run();
   "
   ```

### Инструменты не видны в OpenCode

1. Убедитесь, что конфигурация создана:
   ```bash
   cat ~/.config/opencode/mcp-servers.json
   ```

2. Перезапустите OpenCode

---

## 🎉 Готово!

Интеграция полностью настроена. Теперь:

1. **Перезапустите OpenCode**
2. **Начните использовать** - просто общайтесь, память будет сохраняться автоматически
3. **Проверьте Dashboard** - `http://localhost:20128/dashboard/memory`

---

**Создано**: 2026-05-11  
**Версия OmniRoute**: 3.7.8+  
**Статус**: ✅ Production Ready
