# SETUP-WORKING — Claude Code + DeepSeek V4 (рабочая конфигурация)

Дата фиксации: 2026-05-29
Claude Code: 2.1.154
DeepSeek: deepseek-v4-pro (через DeepSeek API)

## Схема подключения

```
┌──────────────┐     Anthropic API      ┌────────────────────┐     Anthropic API      ┌───────────────────┐
│  Claude Code │ ──────────────────────→ │  free-claude-code  │ ──────────────────────→ │  api.deepseek.com │
│  (CLI/VS     │ ←────────────────────── │  (прокси-сервер)   │ ←────────────────────── │  /anthropic       │
│   Code)      │     SSE стриминг        │  127.0.0.1:8082    │     стриминг            │                   │
└──────────────┘                        └────────────────────┘                        └───────────────────┘
                                                  │
                                                  │ Провайдер: deepseek
                                                  │ Модель: deepseek-v4-pro
                                                  │ Аутентификация: ANTHROPIC_AUTH_TOKEN
                                                  │
                                          ┌───────┴────────┐
                                          │    .env файл    │
                                          │  DEEPSEEK_API_  │
                                          │  KEY=sk-...     │
                                          │  MODEL=deepseek/│
                                          │  deepseek-v4-pro│
                                          └────────────────┘
```

**Как это работает:**
- Claude Code думает что общается с Anthropic API
- Прокси перехватывает запросы, конвертирует их в формат DeepSeek
- Ответы от DeepSeek конвертируются обратно в Anthropic-формат (SSE стриминг)
- Thinking blocks, tool use, token usage — всё нормализуется в формат Claude Code

## Структура репозитория (D:\AI BASE\DEEPSEEK)

```
DEEPSEEK/                      ← форк free-claude-code
├── .env                        ← ключи и модель (НЕ КОММИТИТЬ!)
├── .env.example                ← шаблон переменных
├── server.py                   ← точка входа прокси
├── api/                        ← FastAPI роуты, роутинг моделей
├── providers/                  ← адаптеры: DeepSeek, NVIDIA NIM, OpenRouter, ...
├── core/                       ← общие хелперы Anthropic протокола
├── config/                     ← настройки, логирование
├── SETUP-WORKING.md            ← этот файл
└── ...
```

## Рабочий .env (с плейсхолдерами)

```dotenv
# === ОБЯЗАТЕЛЬНЫЕ ===
ANTHROPIC_AUTH_TOKEN=your-local-token-here
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
MODEL=deepseek/deepseek-v4-pro

# === ОПЦИОНАЛЬНЫЕ (для других провайдеров) ===
# MODEL_OPUS=deepseek/deepseek-v4-pro
# MODEL_SONNET=
# MODEL_HAIKU=
# ENABLE_MODEL_THINKING=true

# === НАСТРОЙКИ ПРОКСИ ===
# HTTP_READ_TIMEOUT=300
# HTTP_WRITE_TIMEOUT=60
# HTTP_CONNECT_TIMEOUT=60
# LOG_RAW_API_PAYLOADS=false
# LOG_RAW_SSE_EVENTS=false
```

## settings.json (C:\Users\Илья\.claude\settings.json)

Рабочая конфигурация Claude Code с **очищенными** `env` и `model`:

```jsonc
{
  "env": {},
  // "model" — удалён, чтобы не конфликтовал с прокси
  "enabledPlugins": {
    "commit-commands@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "learning-output-style@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "vercel@claude-plugins-official": true,
    "ui-ux-pro-max@ui-ux-pro-max-skill": true,
    "interface-design@interface-design": true,
    "design-research@designer-skills": true,
    "design-systems@designer-skills": true,
    // ... остальные плагины по вкусу
  },
  "effortLevel": "low",
  "skipDangerousModePermissionPrompt": true,
  "theme": "light",
  "autoUpdate": false
}
```

**Критически важно:** `"autoUpdate": false` — иначе Claude Code обновится и может сломать совместимость с прокси.

## Команды запуска

### Запуск прокси (терминал 1)

```powershell
cd "D:\AI BASE\DEEPSEEK"
uv run uvicorn server:app --host 127.0.0.1 --port 8082
```

После запуска будет:
```
Server URL: http://127.0.0.1:8082
Admin UI:  http://127.0.0.1:8082/admin
```

### Запуск Claude Code (терминал 2)

Перед запуском Claude Code нужно очистить `model` из settings.json, чтобы он использовал прокси, а не прямой Anthropic API:

```powershell
# 1. Очистить env/model в settings.json (скрипт делает бекап автоматически)
python C:\Users\Илья\.claude\cc-start.py

# 2. Запустить Claude Code с переменными прокси
$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:8082"
$env:ANTHROPIC_AUTH_TOKEN = "freecc"
$env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
claude

# 3. После выхода — восстановить settings.json
python C:\Users\Илья\.claude\cc-end.py
```

### Скрипты cc-start / cc-end

**`cc-start.py`** — бекапит `settings.json` → `settings.backup.json`, очищает `env` и удаляет `model`:

```python
import json, os, shutil
s = os.path.expandvars(r'%USERPROFILE%\.claude\settings.json')
b = os.path.expandvars(r'%USERPROFILE%\.claude\settings.backup.json')
shutil.copy(s, b)
d = json.load(open(s, encoding='utf-8'))
d['env'] = {}
d.pop('model', None)
json.dump(d, open(s, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
print('env cleared')
```

**`cc-end.py`** — восстанавливает из бекапа:

```python
import os, shutil
s = os.path.expandvars(r'%USERPROFILE%\.claude\settings.json')
b = os.path.expandvars(r'%USERPROFILE%\.claude\settings.backup.json')
shutil.copy(b, s)
print('settings restored')
```

## Псевдонимы (алиасы) для удобства

Можно добавить в `~/.bashrc` или PowerShell профиль:

**Bash (~/.bashrc):**
```bash
alias ds-server='cd "D:/AI BASE/DEEPSEEK" && uv run uvicorn server:app --host 127.0.0.1 --port 8082'
alias cc='python "$USERPROFILE/.claude/cc-start.py" && ANTHROPIC_BASE_URL="http://127.0.0.1:8082" ANTHROPIC_AUTH_TOKEN="freecc" CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 claude ; python "$USERPROFILE/.claude/cc-end.py"'
```

**PowerShell (профиль):**
```powershell
function ds-server { cd "D:\AI BASE\DEEPSEEK"; uv run uvicorn server:app --host 127.0.0.1 --port 8082 }
function cc {
    python "$env:USERPROFILE\.claude\cc-start.py"
    $env:ANTHROPIC_BASE_URL = "http://127.0.0.1:8082"
    $env:ANTHROPIC_AUTH_TOKEN = "freecc"
    $env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
    claude
    python "$env:USERPROFILE\.claude\cc-end.py"
}
```

## Что сломано в Claude Code 2.1.154

| Проблема | Симптом | Решение |
|----------|---------|---------|
| **`model` в settings.json конфликтует с прокси** | Claude Code пытается использовать прямой Anthropic API вместо прокси, модель не находится | `cc-start.py` удаляет `model` из settings.json перед запуском |
| **Gateway model discovery требует модель в списке** | `/model` показывает пустой список или "модель не найдена" | `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` + модель в ответе `/v1/models` прокси |
| **`autoUpdate` ломает совместимость** | После автообновления Claude Code может изменить формат запросов — прокси их не понимает | `"autoUpdate": false` в settings.json |
| **Токен авторизации не пробрасывается** | Claude Code шлёт запросы без авторизации | `ANTHROPIC_AUTH_TOKEN="freecc"` должен совпадать с токеном в `.env` прокси |
| **Admin UI перезаписывает модель** | При изменении настроек в Admin UI модель перезаписывается | Не менять модель через Admin UI, править `.env` напрямую |

## Как обновляться когда выйдет фикс

### Вариант А: обновление прокси (free-claude-code)

```powershell
cd "D:\AI BASE\DEEPSEEK"
git pull origin main                    # стянуть свежий upstream
git merge origin/main                   # смержить в ilya/working-setup
# Разрешить конфликты если есть
uv sync                                 # обновить зависимости
```

### Вариант Б: обновление Claude Code

Когда выйдет версия с фиксом проблем совместимости:

```powershell
# 1. Временно включить автообновление
# В settings.json поставить "autoUpdate": true

# 2. Или обновить вручную
npm update -g @anthropic-ai/claude-code

# 3. Проверить версию
claude --version

# 4. Протестировать с прокси
# Запустить ds-server, потом cc
# Если всё работает — отключить автообновление обратно
```

### Признаки что пора обновляться:
- `/model` показывает корректный список моделей без `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`
- `model` в settings.json не конфликтует с прокси
- Thinking blocks работают без ошибок
- Не нужны скрипты `cc-start.py` / `cc-end.py`

## Как восстановить если всё слетело

### Уровень 1: прокси не стартует

```powershell
cd "D:\AI BASE\DEEPSEEK"
uv sync                    # переустановить зависимости
uv run uvicorn server:app --host 127.0.0.1 --port 8082
```

### Уровень 2: Claude Code не коннектится к прокси

```powershell
# Проверить что прокси работает
curl http://127.0.0.1:8082/v1/models

# Проверить переменные окружения в текущей сессии
echo $env:ANTHROPIC_BASE_URL
echo $env:ANTHROPIC_AUTH_TOKEN

# Проверить что model удалён из settings.json
cat "$env:USERPROFILE\.claude\settings.json" | Select-String "model"
```

### Уровень 3: восстановление settings.json из бекапа

```powershell
python "$env:USERPROFILE\.claude\cc-end.py"
# или вручную:
copy "$env:USERPROFILE\.claude\settings.backup.json" "$env:USERPROFILE\.claude\settings.json"
```

### Уровень 4: полный сброс (ядерный вариант)

```powershell
# 1. Склонировать репозиторий заново
cd "D:\AI BASE"
mv DEEPSEEK DEEPSEEK.bak
git clone https://github.com/IlyaVostrikov/free-claude-code.git DEEPSEEK
cd DEEPSEEK
git checkout ilya/working-setup

# 2. Восстановить .env (запросить ключи заново или взять из бекапа)
copy "D:\AI BASE\DEEPSEEK.bak\.env" .env

# 3. Установить зависимости
uv sync

# 4. Восстановить настройки Claude Code
copy "C:\Users\Илья\.claude\settings.backup.json" "C:\Users\Илья\.claude\settings.json"
# Если бекапа нет — создать settings.json с "env": {} и без "model"

# 5. Проверить версию Claude Code
claude --version
# Если не 2.1.154 — установить конкретную версию:
# npm install -g @anthropic-ai/claude-code@2.1.154

# 6. Запустить и проверить
ds-server    # терминал 1
cc           # терминал 2
```

### Уровень 5: новый API ключ DeepSeek

Если ключ скомпрометирован или истёк:
1. Зайти на https://platform.deepseek.com/api_keys
2. Создать новый ключ
3. Обновить `DEEPSEEK_API_KEY` в `D:\AI BASE\DEEPSEEK\.env`
4. Перезапустить прокси

## Полезные ссылки

- [Репозиторий free-claude-code](https://github.com/Alishahryar1/free-claude-code)
- [Форк Ильи](https://github.com/IlyaVostrikov/free-claude-code)
- [DeepSeek API Keys](https://platform.deepseek.com/api_keys)
- [Claude Code Docs](https://code.claude.com/docs/en/overview)
- [DeepSeek Anthropic Endpoint](https://api.deepseek.com/anthropic)
