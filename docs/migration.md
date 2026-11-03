# Что изменилось при переносе с Cursor на OpenCode

Источник: [Desko77/cursor-1c-skills](https://github.com/Desko77/cursor-1c-skills), лицензия MIT. Этот репозиторий — адаптация для OpenCode, а не новый набор с нуля. Авторство исходных правил, скиллов и скриптов сохранено в `LICENSE`.

## Что перенесено без упрощения алгоритмов

- 121 скилл: тела процедур, `scripts/`, `references/`, шаблоны и примеры.
- 49 правил: полный текст. Формат сменен с `.mdc` на Markdown с полями `description`, `load: on-demand`, `paths`.
- Валидаторы, каталог дефектов, тесты скриптов, справочники БСП и ЗУП, документация форматов в `docs/`.
- Команды `check-uuid`, `browser-debug`, `docx-to-md`, `move-project`, `quality`.

Скиллы не склеивались. Имена каталогов совпадают с полем `name`.

## Как правила попадают в контекст

В Cursor правило с `globs` и `alwaysApply: false` подключалось само, когда в контексте был подходящий файл. В OpenCode такого механизма нет. Документация OpenCode дает два пути: `AGENTS.md` и массив `instructions` в `opencode.json`.

Здесь выбран первый путь как основной. Установщик пишет в `AGENTS.md` указатель: какой файл читать для BSL, форм, запросов, EDT и остальных задач. Агент открывает файл и выполняет его целиком. Второй путь описан в `installation.md` и по умолчанию выключен, потому что полный текст 49 правил слишком велик для каждого хода.

Ограничение: если агент не откроет файл, деталь правила до него не дойдет. Указатель в `AGENTS.md` как раз требует открыть файл до правки. Это не автоматическое подключение Cursor.

## Что адаптировано, а не скопировано

| Место | Было | Стало |
|---|---|---|
| Правила | `.mdc`, `globs`, `alwaysApply` | `rules/<раздел>/*.md`, загрузка по указателю |
| `model-selection` | конкретные семейства моделей и переключение сессии | уровни «быстрый / рабочий / сильный». Модель сессии задает пользователь через `/model` |
| `file-edit-efficiency` | инструменты Cursor и `@`-ссылки на строки | те же приемы экономии контекста для инструментов OpenCode |
| `skill-design` | вызов скилла средой Cursor | формат OpenCode: `name`, лимит `description`, `disable-model-invocation` в OpenCode 2 |
| `1c-config-router` | короткие имена `/cf-init` | те же имена как алиасы `1c-cf-init` |
| `claude-env-setup` | установка в `~/.claude` | `install.ps1` / `install.sh` и каталоги OpenCode |
| `claude-md-bootstrap` | генерация `CLAUDE.md` | генерация `AGENTS.md`. Имя скилла сохранено |
| `report-issue` | Cursor и Claude Code | сначала репозиторий этой адаптации |
| Команды | часть без frontmatter и с путями `~/.claude` | frontmatter OpenCode. `/docx-to-md` вызывает pandoc, потому что `docx_to_md.py` в репозиторий не входил |
| `move-project` | перенос памяти Claude Code | перенос каталога. Базу `opencode.db` скрипт не правит |
| `quality` | хук `hooks/release-writer.mjs` | команда сообщает, что хука нет, и ничего не пишет |

Описание `humanize-ai-text` укорочено на одну фразу триггера: в OpenCode `description` не длиннее 1024 символов. Смысл скилла и его справочники на месте.

## Чего в OpenCode нет как у Cursor

- Автоподключение правила по glob открытого файла.
- Поле `alwaysApply`.
- Ссылки вида `@путь:строки` в чате Cursor.
- Переключение модели сессии из скилла и параметр `model` у вызова Task так, как это описано в исходном `model-selection`.
- Хуки Claude Code (`hooks/release-writer.mjs`) и каталог агентов `~/.claude/agents`. В этом репозитории их не было и в Cursor-зеркале.
- `disable-model-invocation` в OpenCode 1 не скрывает скилл. В OpenCode 2 скрывает. В OpenCode 1 скилл с описанием остается в списке, пока его не закроет `permission.skill: deny`.
- Ключ `skills` в `opencode.json` есть в актуальной схеме конфигурации. Обнаружение `.opencode/skills` и `~/.config/opencode/skills` работает и в описании OpenCode 1, и в OpenCode 2. Установщик кладет файлы туда.

## Проверка, которая здесь выполнялась

- `python tools/validate_ruleset.py` — frontmatter, имя каталога, длина `description`, ссылки на `.md`, счетчики README.
- `bash tests/install/test_install.sh` — проект и глобальная установка, только правила, только скиллы, только команды, повтор, сохранение чужого скилла и своего `AGENTS.md`, отказ затирать правку без `--yes`, замена с копией, удаление неизмененных файлов.
- `install.ps1` на этой машине не запускался: в окружении нет PowerShell. Синтаксис Windows-установщика нужно прогнать на Windows командой `powershell -NoProfile -File .\install.ps1 -List`.
- Снапшот-тесты скриптов (`tests/skills/runner.mjs`) рассчитаны на Windows и установленный `lxml` для Python-порта. В этом проходе они не запускались.
- Платформа 1С, EDT, MCP и веб-публикация не проверялись.

## Что сделать на своей машине

1. Поставить набор `install.ps1` или `install.sh`.
2. Открыть проект в OpenCode и убедиться, что `1c-config-router` есть в списке скиллов.
3. На Windows прогнать снапшоты: `node tests/skills/runner.mjs` и `node tests/skills/runner.mjs --runtime python` после `pip install lxml`.
4. Подключить AI-EDT отдельно, если нужна семантическая модель EDT. Репозиторий плагина: `https://github.com/Desko77/ai-edt`.
