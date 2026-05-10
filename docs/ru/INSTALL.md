# 📥 Руководство по установке

Это руководство поможет вам установить и настроить **OmniRoute-OpenClaw** на вашей системе.

## 📋 Содержание
1. [Системные требования](#-системные-требования)
2. [Быстрый старт](#-быстрый-старт)
3. [Инструкции для разных платформ](#-инструкции-для-разных-платформ)
4. [Конфигурация](#-конфигурация)
5. [Проверка работы](#-проверка-работы)
6. [Решение проблем](#-решение-проблем)

---

## 💻 Системные требования

### Минимум
- **Процессор:** 2 ядра (x86_64 или ARM64)
- **ОЗУ:** 4 ГБ
- **Диск:** 10 ГБ свободного места
- **ОС:** Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+), macOS 12+ или Windows 10/11 с WSL2

### Рекомендуется
- **Процессор:** 4+ ядер
- **ОЗУ:** 8 ГБ+
- **Диск:** 20 ГБ+ (SSD)

### Программное обеспечение
- **Docker:** 20.10+
- **Docker Compose:** v2.0+ (v1.x поддерживается, но не рекомендуется)
- **Git:** 2.25+

---

## 🚀 Быстрый старт

Самый быстрый способ начать — использовать наш установщик в одну команду:

```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

Этот скрипт:
1. Проверит системные требования
2. Инициализирует подмодули (submodules)
3. Сгенерирует безопасные API-ключи и пароли
4. Сберет и запустит Docker-контейнеры

---

## 🍎 Инструкции для разных платформ

### 🐧 Linux (Ubuntu/Debian)
```bash
# Установка Docker и Git
sudo apt update
sudo apt install -y docker.io docker-compose-v2 git

# Клонирование и установка
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
chmod +x *.sh
./update.sh
```

### 🍏 macOS
1. Установите [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Откройте терминал и выполните:
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

### 🪟 Windows (WSL2)
1. Установите [WSL2](https://learn.microsoft.com/ru-ru/windows/wsl/install) (рекомендуется Ubuntu)
2. Установите [Docker Desktop для Windows](https://docs.docker.com/desktop/install/windows-install/) и включите интеграцию с WSL2
3. Откройте терминал WSL2 и выполните:
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

---

## ⚙️ Конфигурация

Настройки хранятся в файле `.env`. Установщик генерирует безопасные значения по умолчанию, но вы можете изменить следующие параметры:

- `OPENCLAW_PASSWORD`: Токен для доступа к шлюзу OpenClaw.
- `STORAGE_ENCRYPTION_KEY`: Используется для шифрования данных.
- `JWT_SECRET`: Используется для аутентификации в панели управления.

### Хранение данных
Все данные хранятся в директории `./data`:
- `./data/omniroute`: База данных и конфигурации OmniRoute
- `./data/openclaw`: Постоянные данные OpenClaw

---

## ✅ Проверка работы

После установки убедитесь, что сервисы запущены:

1. **Панель OmniRoute:** [http://localhost:20128](http://localhost:20128)
   - Логин по умолчанию: `admin` / `admin`
2. **Шлюз OpenClaw:** [http://localhost:18789](http://localhost:18789)
   - Проверка статуса: `curl http://localhost:18789/healthz`

---

## 🛠 Решение проблем

Если вы столкнулись с трудностями, обратитесь к руководству [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (на английском).

Полезные команды:
- `./status.sh`: Проверить состояние системы
- `./logs.sh`: Просмотр логов в реальном времени
- `./restart.sh`: Перезапуск всех сервисов
- `./cleanup.sh`: Очистка места на диске
