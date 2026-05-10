# OmniRoute + OpenClaw (All-in-One Docker)

![Project Banner](docs/images/banner.png)

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg?logo=docker)](https://www.docker.com/)
[![Version](https://img.shields.io/badge/Version-1.2.0-green.svg)](https://github.com/Den3112/OmniRoute-OpenClaw)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)]()

**Профессиональная среда для запуска OmniRoute и OpenClaw в едином Docker-контейнере.**
*Агрегатор API + Agentic AI Gateway — всё, что нужно для работы с LLM в одном месте.*

[Быстрый старт](#-быстрый-старт) • [Особенности](#-особенности) • [Архитектура](#-архитектура) • [Сервисы](#-сервисы) • [Документация](#-документация)

</div>

---

## 📖 О проекте

Этот репозиторий объединяет два мощных инструмента в одну бесшовную экосистему:

1.  **OmniRoute**: Универсальный агрегатор API для LLM. Позволяет управлять ключами, пользователями и группами, предоставляя единый эндпоинт для доступа к десяткам моделей (OpenAI, Anthropic, Gemini, Local LLMs).
2.  **OpenClaw**: Продвинутый шлюз для "агентного" AI. Он служит мостом между вашими приложениями и LLM, добавляя слой безопасности, кэширования и специфических функций для работы агентов.

**Зачем это нужно?** Вместо того чтобы настраивать каждый проект по отдельности, вы получаете готовую инфраструктуру с автоматической генерацией секретов, настроенным Redis для кэширования и единой точкой управления.

---

## 🚀 Быстрый старт

### Предварительные требования
- **Docker** и **Docker Compose**
- **Git**

### Установка в один клик

1.  **Клонируйте репозиторий** (обязательно с вложенными модулями):
    ```bash
    git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
    cd OmniRoute-OpenClaw
    ```

2.  **Запустите скрипт установки**:
    ```bash
    chmod +x update.sh
    ./update.sh
    ```

**Что сделает скрипт?**
- Инициализирует и обновит все субмодули.
- Создаст файл `.env` на основе примера.
- Сгенерирует надежные случайные ключи (`JWT_SECRET`, `API_KEY_SECRET` и др.).
- Настроит права доступа и запустит контейнеры в Docker.
- Проверит состояние здоровья всех сервисов.

---

## 🏗 Архитектура

Проект использует микросервисную архитектуру, изолированную внутри приватной сети Docker.

```mermaid
graph TD
    User([Пользователь]) -->|HTTP| OR_Dash[OmniRoute Dashboard :20128]
    User -->|API Requests| OC_Gate[OpenClaw Gateway :18789]
    
    subgraph Docker Network
        OC_Gate -->|Internal API| OR_Core[OmniRoute Core]
        OR_Core -->|Cache| Redis[(Redis)]
        OR_Core -->|Storage| DB[(SQLite / Persistent Data)]
    end
    
    OR_Core -->|External API| Providers{AI Providers}
    Providers --> OpenAI[OpenAI]
    Providers --> Anthropic[Anthropic]
    Providers --> Google[Google Gemini]
```

---

## 📍 Сервисы

После запуска вам будут доступны следующие адреса:

| Сервис | Адрес | Логин / Пароль (по умолчанию) |
| :--- | :--- | :--- |
| **OmniRoute Dashboard** | [http://localhost:20128](http://localhost:20128) | `admin` / `admin` |
| **OpenClaw Gateway** | [http://localhost:18789](http://localhost:18789) | Токен: `admin` |
| **Redis** | `redis://localhost:6379` | (Внутренний доступ) |

> [!WARNING]
> Сразу после первого входа обязательно смените стандартные пароли в панели управления OmniRoute!

---

## 🛠 Особенности

- **🔐 Автоматическая безопасность**: Скрипт `update.sh` сам генерирует уникальные ключи шифрования при первом запуске.
- **🚀 Высокая производительность**: Интеграция с Redis обеспечивает мгновенное кэширование сессий и ответов.
- **📊 Умные логи**: Автоматическая ротация логов (макс. 10МБ на файл) защищает ваш диск от переполнения.
- **🔄 Легкое обновление**: Для обновления обоих проектов до последних версий достаточно снова запустить `./update.sh`.
- **📂 Миграция данных**: Скрипт автоматически подхватывает данные из старых версий (в `$HOME/.omniroute`), если они существуют.

---

## ⚙️ Конфигурация

Все настройки хранятся в файле `.env`. Основные переменные:

- `STORAGE_ENCRYPTION_KEY`: Ключ для шифрования данных в базе.
- `JWT_SECRET`: Секрет для авторизации пользователей.
- `OPENCLAW_PASSWORD`: Пароль для доступа к шлюзу OpenClaw.
- `INITIAL_PASSWORD`: Пароль администратора OmniRoute при первом запуске.

---

## 📄 Лицензия

Этот проект распространяется под лицензией **MIT**. Подробности в файле [LICENSE](LICENSE).

---

<div align="center">
Создано с ❤️ для сообщества AI разработчиков.
</div>
