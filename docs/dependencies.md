# Зависимости скиллов, правил и инструментов

Скилл вызывается по имени. Правило читается по указателю в `AGENTS.md`, когда задача совпадает с разделом. Внешний инструмент нужен только части скиллов. Остальные правят XML-выгрузку скриптом.

## Как выбрать скилл

Начните с `1c-config-router`. Он сопоставляет формулировку задачи с именем скилла. Короткое имя из его таблицы (`/cf-init`) в OpenCode означает `1c-cf-init`.

| Задача | Скилл | Правило, которое прочитать до правки |
|---|---|---|
| Новый объект метаданных | `1c-meta-compile` | `rules/metadata/1c-mdo-integrity.md` |
| Форма | `1c-form-compile`, `1c-form-edit` | `rules/forms/edt-form-xml-requirements.md`, `rules/forms/form_module_rules.md` |
| Запрос | `composing-1c-queries`, `1c-query-validate` | `rules/queries/1c-query-specifics.md`, `rules/performance/query-optimization-tips.md` |
| Код BSL | `1c-bsl-validate`, `1c-code-review` | `rules/bsl/1c-coding-standards.md`, `rules/performance/anti_patterns.md`, `rules/bsl/async-methods-1c.md` |
| Расширение | `1c-cfe-init`, `1c-cfe-borrow`, `1c-cfe-patch-method` | `rules/extensions/1c-extension-patterns.md` |
| Роль и RLS | `1c-role-compile`, `1c-role-edit` | `rules/security/1c-role-rights.md` |
| СКД | `1c-skd-compile`, `1c-skd-edit` | `rules/skd/1c-skd-specifics.md` |
| БСП | `1c-bsp-api`, `1c-ssl-patterns` | `rules/bsp/bsl-ssl.md` |
| База, CF, DT, XML | `1c-db-list` и соседние `1c-db-*` | `rules/workflow/designer-batch-verdict.md`, `rules/metadata/edt-thick-client-monopoly.md` |
| Хранилище конфигурации | `1c-storage-ops` | `rules/security/git-safety-rules.md` |

Полные списки: [skills-catalog.md](skills-catalog.md), [rules-catalog.md](rules-catalog.md).

## Что нужно окружению

| Компонент | Обязательность | Зачем |
|---|---|---|
| PowerShell 5.1+ на Windows | да для `.ps1` скиллов | основной рантайм скриптов |
| Python 3.8+ | нет для базовых операций | порты скриптов, `v8unpack-cf`, проверки `tools/` |
| Python-пакет `lxml` | для прогона тестов портов | разбор XML в тестах |
| 1С:Предприятие 8.3 | нет | `1c-db-*`, сборка EPF/ERF, толстый клиент |
| 1C:EDT и плагин AI-EDT | нет | скилл `ai-edt-tools`, правила `edt-*` |
| `MCP_Toolkit.epf` | нет | `1c-mcp-toolkit` |
| `v8unpack` | нет | `v8unpack-cf` |
| `gcomp` | нет | `1c77-dev` |
| Node.js и `@mermaid-js/mermaid-cli` | нет | `mermaid-render` |
| pandoc | нет | команда `/docx-to-md` |
| ffmpeg | нет | `transcribe` |

Платформа, EDT и MCP в этой среде не проверялись: их нет в контуре, где собирался репозиторий.

## Скрипты репозитория

| Файл | Назначение |
|---|---|
| `install.ps1`, `install.sh` | установка в OpenCode |
| `tools/validate_ruleset.py` | frontmatter, ссылки, счетчики README, бюджет описаний |
| `tools/install_home.py` | установщик домашнего каталога Claude Code из исходного набора. Для OpenCode не используется |
| `commands/check_uuid_duplicates.py` | команда `/check-uuid` |
| `skills/<имя>/scripts/*.ps1` и `*.py` | операция скилла. Агент запускает скрипт и читает его вывод |

Каталогов `agents/` и `hooks/` в репозитории нет. Их не потеряли при копировании: в исходном Cursor-зеркале их тоже не было, на них только ссылались тексты Claude Code.

## Правила и скиллы

Правило не вызывает скилл само. Скилл не вставляет текст правила в ответ. Связь такая:

1. `AGENTS.md` говорит, какой файл правила открыть.
2. Скилл выполняет шаги и скрипты.
3. Валидатор скилла проверяет XML. Смысл BSL и план запроса без платформы он не доказывает.

Поэтому после генерации объекта нужен скилл проверки (`*-validate`), а после ручного BSL — `1c-bsl-validate` или `1c-code-review` и правила из `rules/bsl` и `rules/performance`.
