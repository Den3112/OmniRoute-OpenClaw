# 📥 Руководство по установке

Полное руководство по установке OmniRoute + OpenClaw на различных платформах.

---

## 📋 Содержание

1. [Системные требования](#-системные-требования)
2. [Быстрая установка](#-быстрая-установка)
3. [Инструкции для конкретных платформ](#-инструкции-для-конкретных-платформ)
   - [Ubuntu/Debian](#ubuntudebian)
   - [macOS](#macos)
   - [Windows (WSL2)](#windows-wsl2)
   - [Другие дистрибутивы Linux](#другие-дистрибутивы-linux)
4. [Ручная установка](#-ручная-установка)
5. [После установки](#-после-установки)
6. [Проверка](#-проверка)
7. [Решение проблем](#-решение-проблем)

---

## 💻 Системные требования

### Минимальные требования
- **CPU:** 2 ядра
- **RAM:** 4 ГБ
- **Диск:** 10 ГБ свободного места
- **ОС:** Linux, macOS или Windows с WSL2

### Рекомендуемые требования
- **CPU:** 4+ ядра
- **RAM:** 8 ГБ+
- **Диск:** 20 ГБ+ (предпочтительно SSD)
- **ОС:** Ubuntu 22.04+, macOS 12+ или Windows 11 с WSL2

### Необходимое ПО
- **Docker:** 20.10+ с плагином Docker Compose
- **Git:** 2.30+
- **Bash:** 4.0+ (для скриптов установки)

---

## ⚡ Быстрая установка

### Установка одной командой (Рекомендуется)

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

Это автоматически:
- ✅ Проверит системные требования
- ✅ Установит Docker при необходимости (на поддерживаемых платформах)
- ✅ Клонирует репозиторий с подмодулями
- ✅ Сгенерирует безопасные ключи шифрования
- ✅ Соберёт и запустит все контейнеры
- ✅ Проверит работоспособность всех сервисов

**Время установки:** 5-15 минут (в зависимости от скорости интернета)

---

## 🖥 Инструкции для конкретных платформ

### Ubuntu/Debian

#### 1. Обновите систему
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Установите Docker
```bash
# Установка Docker
curl -fsSL https://get.docker.com | sudo sh

# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER

# Примените изменения группы (или выйдите/войдите)
newgrp docker

# Проверьте установку Docker
docker --version
docker compose version
```

#### 3. Установите Git
```bash
sudo apt install -y git curl
```

#### 4. Запустите установку
```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### macOS

#### 1. Установите Homebrew (если не установлен)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Установите Docker Desktop
```bash
brew install --cask docker
```

**Или скачайте вручную:** [Docker Desktop для Mac](https://www.docker.com/products/docker-desktop/)

#### 3. Запустите Docker Desktop
- Откройте Docker Desktop из Приложений
- Дождитесь запуска Docker (значок кита в строке меню)
- Проверьте: `docker --version`

#### 4. Настройте ресурсы Docker
- Откройте Docker Desktop → Settings → Resources
- **Memory:** Установите минимум 4ГБ (рекомендуется 8ГБ)
- **CPUs:** Установите минимум 2 ядра (рекомендуется 4)
- **Disk:** Убедитесь, что доступно минимум 20ГБ

#### 5. Запустите установку
```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### Windows (WSL2)

#### 1. Включите WSL2
Откройте PowerShell от имени администратора:
```powershell
wsl --install
```

Перезагрузите компьютер.

#### 2. Установите Ubuntu из Microsoft Store
- Откройте Microsoft Store
- Найдите "Ubuntu 22.04 LTS"
- Нажмите "Получить" и установите
- Запустите Ubuntu и создайте учётную запись

#### 3. Установите Docker Desktop для Windows
- Скачайте: [Docker Desktop для Windows](https://www.docker.com/products/docker-desktop/)
- Установите и включите интеграцию с WSL2
- Settings → Resources → WSL Integration → Включите Ubuntu

#### 4. Внутри Ubuntu WSL2
```bash
# Обновите систему
sudo apt update && sudo apt upgrade -y

# Установите Git
sudo apt install -y git curl

# Запустите установку
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### Другие дистрибутивы Linux

#### Fedora/RHEL/CentOS
```bash
# Установите Docker
sudo dnf install -y docker docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Установите Git
sudo dnf install -y git curl

# Запустите установку
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

#### Arch Linux
```bash
# Установите Docker
sudo pacman -S docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Установите Git
sudo pacman -S git curl

# Запустите установку
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

## 🔧 Ручная установка

Если вы предпочитаете ручную установку или автоматический скрипт не работает:

### 1. Клонируйте репозиторий
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
```

### 2. Запустите скрипт обновления
```bash
# Интерактивный режим (запрашивает подтверждение)
./update.sh

# Или автоматический режим (без запросов)
./update.sh --yes
```

Скрипт выполнит:
- Инициализацию и обновление всех подмодулей
- Создание `.env` из примера
- Генерацию безопасных ключей шифрования
- Настройку прав доступа
- Сборку и запуск Docker контейнеров
- Проверку работоспособности

### 3. Дождитесь сборки
Первая сборка занимает 5-15 минут. Вы увидите:
```
[+] Building omniroute...
[+] Building openclaw...
[+] Starting services...
```

---

## 🎯 После установки

### 1. Доступ к сервисам

После завершения установки откройте:

| Сервис | URL | Учётные данные по умолчанию |
|--------|-----|----------------------------|
| **Панель OmniRoute** | http://localhost:20128 | Логин: `admin`<br>Пароль: Смотрите в файле `.env` |
| **Шлюз OpenClaw** | http://localhost:18789 | Токен: Смотрите в файле `.env` |

### 2. Смените пароли по умолчанию

**⚠️ ВАЖНО:** Немедленно смените пароли по умолчанию!

#### Панель OmniRoute:
1. Откройте http://localhost:20128
2. Войдите с учётными данными из `.env`
3. Перейдите в Настройки → Безопасность
4. Смените пароль администратора

#### Шлюз OpenClaw:
1. Отредактируйте файл `.env`:
   ```bash
   nano .env
   ```
2. Измените `OPENCLAW_PASSWORD` на надёжный пароль
3. Перезапустите сервисы:
   ```bash
   ./restart.sh
   ```

### 3. Настройте API ключи

#### Добавьте ключи AI провайдеров:
1. Откройте панель OmniRoute
2. Перейдите в раздел "Провайдеры"
3. Добавьте ваши API ключи для:
   - OpenAI
   - Anthropic
   - Google Gemini
   - DeepSeek
   - Groq
   - xAI
   - и др.

### 4. Протестируйте установку

```bash
# Проверьте статус сервисов
./status.sh

# Просмотрите логи
./logs.sh

# Протестируйте API endpoint
curl http://localhost:20128/api/monitoring/health
```

---

## ✅ Проверка

### Проверьте статус контейнеров
```bash
docker ps
```

Вы должны увидеть 3 работающих контейнера:
- `omniroute` (healthy)
- `openclaw` (healthy)
- `omniroute-redis` (healthy)

### Проверьте здоровье сервисов
```bash
./healthcheck.sh
```

Ожидаемый вывод:
```
✓ OmniRoute работает нормально
✓ OpenClaw работает нормально
✓ Redis работает нормально
✓ Все сервисы работают корректно
```

### Протестируйте API endpoints

#### Здоровье OmniRoute:
```bash
curl http://localhost:20128/api/monitoring/health
```

#### Здоровье OpenClaw:
```bash
curl http://localhost:18789/healthz
```

### Проверьте логи
```bash
# Все сервисы
./logs.sh

# Конкретный сервис
docker logs omniroute
docker logs openclaw
docker logs omniroute-redis
```

---

## 🔍 Решение проблем

### Проблемы установки

#### "Docker не найден"
Установите Docker, следуя инструкциям для вашей платформы выше.

#### Ошибки "Permission denied"
```bash
# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Или запустите с sudo (не рекомендуется)
sudo ./update.sh
```

#### "Порт уже используется"
```bash
# Проверьте, что использует порт
sudo lsof -i :20128
sudo lsof -i :18789

# Измените порты в файле .env
nano .env
# Отредактируйте PORT и OPENCLAW_PORT
./restart.sh
```

#### "Недостаточно места на диске"
```bash
# Очистите Docker
./cleanup.sh

# Или вручную
docker system prune -a --volumes
```

### Проблемы с сервисами

#### Контейнеры не запускаются
```bash
# Проверьте логи
./logs.sh

# Проверьте ресурсы Docker (macOS/Windows)
# Увеличьте память до 8ГБ в настройках Docker Desktop

# Перезапустите сервисы
./restart.sh
```

#### Статус "Unhealthy"
```bash
# Подождите 2-3 минуты для инициализации сервисов
# Затем проверьте логи
docker logs omniroute
docker logs openclaw

# Если всё ещё unhealthy, перезапустите
./restart.sh
```

#### Ошибки подключения к Redis
```bash
# Проверьте, что Redis запущен
docker ps | grep redis

# Перезапустите Redis
docker restart omniroute-redis

# Проверьте логи Redis
docker logs omniroute-redis
```

### Проблемы производительности

#### Медленное время отклика
```bash
# Проверьте использование ресурсов
./monitor.sh

# Увеличьте ресурсы Docker (macOS/Windows)
# Docker Desktop → Settings → Resources
# Memory: 8ГБ+, CPUs: 4+
```

#### Высокое использование памяти
```bash
# Проверьте текущее использование
docker stats

# Перезапустите сервисы для очистки кэша
./restart.sh
```

---

## 📚 Дополнительные ресурсы

- **Полная документация:** [README.md](../../README.md)
- **Архитектура:** [ARCHITECTURE.md](../../ARCHITECTURE.md)
- **Решение проблем:** [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)
- **Участие в разработке:** [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

## 🆘 Получение помощи

Если у вас возникли проблемы:

1. Проверьте [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)
2. Поищите в [GitHub Issues](https://github.com/Den3112/OmniRoute-OpenClaw/issues)
3. Создайте новый issue с указанием:
   - Вашей ОС и версии
   - Версии Docker (`docker --version`)
   - Сообщений об ошибках из логов
   - Вывода команды `./status.sh`

---

## 🎉 Следующие шаги

После успешной установки:

1. ✅ Смените пароли по умолчанию
2. ✅ Добавьте ваши API ключи AI провайдеров
3. ✅ Прочитайте [Руководство по панели управления](../../DASHBOARD_GUIDE.md)
4. ✅ Изучите [Руководство по быстрому старту](../../QUICKSTART.md)
5. ✅ Настройте резервное копирование с помощью `./backup.sh`

---

<div align="center">
Создано с ❤️ для сообщества AI разработчиков
</div>
