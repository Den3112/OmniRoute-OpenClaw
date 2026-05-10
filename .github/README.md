# GitHub Actions Workflows

Этот репозиторий использует GitHub Actions для автоматизации сборки и проверки конфигурации.

## Workflows

### 1. Docker Build & Publish (`docker-publish.yml`)

**Триггеры:**
- Push в ветку `main` (только при изменении Docker-файлов)
- Ручной запуск через `workflow_dispatch`

**Что делает:**
- Собирает Docker образы для OmniRoute и OpenClaw параллельно
- Публикует образы в GitHub Container Registry (ghcr.io)
- Использует кэширование для ускорения сборки
- Добавляет теги: `latest` и `YYYYMMDD-<sha>`

**Образы:**
- `ghcr.io/<owner>/omniroute:latest`
- `ghcr.io/<owner>/openclaw:latest`

**Оптимизации:**
- Параллельная сборка (2 отдельных job)
- GitHub Actions cache для слоев Docker
- Раздельные scope для кэша (omniroute/openclaw)
- Path filters - сборка только при изменении нужных файлов

### 2. Configuration Check (`config-check.yml`)

**Триггеры:**
- Pull requests с изменениями конфигурации
- Push в `main` с изменениями конфигурации
- Ручной запуск

**Что проверяет:**
- ✅ Валидность `docker-compose.yml`
- ✅ Наличие обязательных файлов
- ✅ Исполняемость скриптов (monitor.sh, rebuild.sh)
- ✅ Полноту `.env.example`

## Использование

### Ручной запуск workflow

```bash
# Через GitHub CLI
gh workflow run docker-publish.yml
gh workflow run config-check.yml

# Или через веб-интерфейс:
# Actions → выбрать workflow → Run workflow
```

### Просмотр статуса

```bash
# Последние запуски
gh run list

# Детали конкретного запуска
gh run view <run-id>

# Логи
gh run view <run-id> --log
```

### Отладка ошибок

Если workflow падает:

1. Проверьте логи в Actions tab на GitHub
2. Для Docker build ошибок - проверьте Dockerfile
3. Для config check - убедитесь, что все файлы на месте
4. Запустите локально:
   ```bash
   docker-compose config
   ./monitor.sh
   ./rebuild.sh
   ```

## Permissions

Workflows требуют следующих разрешений:
- `contents: read` - чтение кода
- `packages: write` - публикация в GHCR

Эти разрешения настроены автоматически через `GITHUB_TOKEN`.

## Кэширование

### GitHub Actions Cache
- Хранит слои Docker между запусками
- Автоматически очищается через 7 дней неиспользования
- Максимум 10GB на репозиторий

### Локальный кэш
- `/tmp/docker-cache/` - для локальной разработки
- Используется через `docker-compose build`

## Troubleshooting

### "No space left on device"
```bash
# Очистить кэш GitHub Actions (через Settings → Actions → Caches)
# Или локально:
docker system prune -af
```

### "Submodule not found"
```bash
# Убедитесь, что submodules инициализированы:
git submodule update --init --recursive
```

### "Permission denied"
```bash
# Проверьте права на скрипты:
chmod +x monitor.sh rebuild.sh OPTIMIZATIONS.sh
```

## Best Practices

1. **Не коммитьте секреты** - используйте GitHub Secrets
2. **Тестируйте локально** перед push
3. **Используйте path filters** для экономии CI минут
4. **Проверяйте логи** при ошибках
5. **Обновляйте actions** регулярно (dependabot)

## Мониторинг

Проверить статус workflows:
- https://github.com/<owner>/OmniRoute-OpenClaw/actions

Badges для README:
```markdown
![Docker Build](https://github.com/<owner>/OmniRoute-OpenClaw/actions/workflows/docker-publish.yml/badge.svg)
![Config Check](https://github.com/<owner>/OmniRoute-OpenClaw/actions/workflows/config-check.yml/badge.svg)
```
