# 🚀 START HERE - Быстрый старт

**Последнее обновление**: 2026-05-11 09:36 UTC

---

## ⚡ Самый быстрый способ (Рекомендуется)

Одна команда - всё готово за 5-7 минут:

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/bootstrap.sh | bash
```

**Что произойдет:**
1. Клонирование репозитория
2. Генерация секретов
3. Скачивание Docker образов
4. Запуск всех сервисов
5. Настройка OpenCode MCP
6. Включение Memory Management

**Результат:**
- ✅ OmniRoute Dashboard: http://localhost:20128
- ✅ OpenClaw Gateway: http://localhost:18789
- ✅ Memory Dashboard: http://localhost:20128/dashboard/memory
- ✅ OpenCode MCP настроен автоматически

---

## 📚 Альтернативные способы

### Fast Mode (3-5 минут)

```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./scripts/generate-secrets.sh
docker compose -f docker-compose.fast.yml up -d
./scripts/setup-opencode-mcp.sh
./scripts/enable-memory.sh
```

### Build Mode (15-20 минут)

```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./scripts/generate-secrets.sh
docker compose up -d --build
./scripts/setup-opencode-mcp.sh
./scripts/enable-memory.sh
```

---

## 📖 Документация

### Начните здесь
- **[QUICK_DEPLOY.md](QUICK_DEPLOY.md)** - Полное руководство по развертыванию

### OpenCode интеграция
- **[INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md)** - Интеграция Memory Management
- **[QUICKSTART_OPENCODE_MEMORY.md](QUICKSTART_OPENCODE_MEMORY.md)** - Краткая инструкция

### Технические детали
- **[DEPLOYMENT_COMPLETE.md](DEPLOYMENT_COMPLETE.md)** - Отчет о развертывании
- **[README.md](README.md)** - Основная документация

---

## 🔐 Первый вход

**OmniRoute:**
- URL: http://localhost:20128
- Логин: `admin`
- Пароль: `admin`

**OpenClaw:**
- URL: http://localhost:18789
- Пароль: смотрите в файле `.env` (переменная `OPENCLAW_PASSWORD`)

⚠️ **ВАЖНО**: Смените пароли после первого входа!

---

## 💡 Быстрые команды

```bash
# Просмотр логов
docker compose logs -f

# Перезапуск сервисов
docker compose restart

# Остановка сервисов
docker compose down

# Проверка статуса
docker ps
```

---

## 🎯 Что дальше?

1. **Войдите в Dashboard**: http://localhost:20128
2. **Добавьте API ключи** провайдеров (Settings → Providers)
3. **Проверьте Memory**: http://localhost:20128/dashboard/memory
4. **Настройте OpenCode** (если используете):
   - Перезапустите OpenCode
   - Проверьте: "Какие MCP инструменты доступны?"
   - Протестируйте: "Запомни, что этот проект называется OmniRoute"

---

## 🆘 Нужна помощь?

- **Troubleshooting**: [QUICK_DEPLOY.md](QUICK_DEPLOY.md#troubleshooting)
- **Логи**: `docker compose logs -f`
- **Проверка здоровья**: `curl http://localhost:20128/api/health`

---

**Удачи! 🚀**
