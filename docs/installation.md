# Установка набора 1С для OpenCode

Набор ставится скриптом. Скрипт копирует файлы по одному, не удаляет чужие скиллы и не заменяет отличающийся файл без подтверждения. Перед заменой делает резервную копию.

## 1. Что нужно заранее

- Git, чтобы склонировать репозиторий.
- OpenCode 1 или OpenCode 2. Команда `opencode` должна находиться в `PATH`.
- Windows: PowerShell 5.1 или новее. Скрипт `install.ps1` не требует Python.
- Linux и macOS: Bash и `sha256sum` (на macOS подойдет набор coreutils; если команды нет, поставьте `coreutils` или используйте Linux). Скрипт `install.sh`.
- Для самих скиллов 1С Python не обязателен: у операций есть порт на PowerShell. Python 3.8+ нужен отдельным скиллам (`v8unpack-cf`, часть проверок, транскрибация). Платформа 1С, EDT и MCP не нужны, чтобы поставить набор. Они нужны только когда вы вызываете скиллы баз, EDT и веб-публикации.

## 2. Как скачать репозиторий

Windows (PowerShell):

```powershell
git clone https://github.com/IliasNizamutdinov/opencode_1c_rules_skills.git C:\src\opencode_1c_rules_skills
Set-Location C:\src\opencode_1c_rules_skills
```

Linux и macOS:

```bash
git clone https://github.com/IliasNizamutdinov/opencode_1c_rules_skills.git ~/src/opencode_1c_rules_skills
cd ~/src/opencode_1c_rules_skills
```

Дальше команды запускаются из корня этого клона. Каталог клона — источник файлов. Он не является установленной копией, пока вы не запустите установщик.

## 3. Глобальная установка

Скиллы и правила становятся видны во всех проектах OpenCode.

Windows:

```powershell
.\install.ps1 -Global
```

Linux и macOS:

```bash
./install.sh --global
```

Куда кладутся файлы:

| Что | Путь |
|---|---|
| Скиллы | `%USERPROFILE%\.config\opencode\skills\` или `~/.config/opencode/skills/` |
| Правила | `%USERPROFILE%\.config\opencode\1c-rules\` или `~/.config/opencode/1c-rules/` |
| Команды | `%USERPROFILE%\.config\opencode\commands\` или `~/.config/opencode/commands/` |
| Указатель правил | `%USERPROFILE%\.config\opencode\AGENTS.md` или `~/.config/opencode/AGENTS.md` |
| Манифест | `1c-kit-manifest.tsv` в том же каталоге `.config/opencode` |
| Резервные копии | `1c-kit-backups\<дата-время>\` там же |

Если задана переменная `XDG_CONFIG_HOME`, `install.sh` использует `$XDG_CONFIG_HOME/opencode`. OpenCode по документации читает `~/.config/opencode`. Не перенаправляйте `XDG_CONFIG_HOME`, если хотите, чтобы клиент увидел глобальные скиллы.

В `AGENTS.md` установщик добавляет блок между маркерами `<!-- 1c-opencode-rules:start -->` и `<!-- 1c-opencode-rules:end -->`. В глобальном блоке пути к правилам абсолютные: агент читает их из проекта, а не из каталога конфигурации.

## 4. Установка в один проект

Windows:

```powershell
.\install.ps1 -ProjectDir C:\Projects\my-1c
```

Текущий каталог, если он и есть проект:

```powershell
Set-Location C:\Projects\my-1c
C:\src\opencode_1c_rules_skills\install.ps1
```

Linux и macOS:

```bash
./install.sh --project /path/to/my-1c
```

Куда кладутся файлы:

| Что | Путь внутри проекта |
|---|---|
| Скиллы | `.opencode/skills/` |
| Правила | `.opencode/1c-rules/` |
| Команды | `.opencode/commands/` |
| Указатель правил | `AGENTS.md` в корне проекта |
| Манифест | `.opencode/1c-kit-manifest.tsv` |
| Резервные копии | `.opencode/1c-kit-backups/<дата-время>/` |

Свой текст в `AGENTS.md` установщик не заменяет. Блок набора добавляется в конец. Если файла не было, создается только блок. При удалении набора свой текст остается.

Проектная копия перекрывает глобальную для тех же имен скиллов: OpenCode видит оба источника, имена должны быть уникальны. Не ставьте один и тот же набор и глобально, и в проект, если не готовы разруливать совпадения имен.

## 5. Только правила

Windows:

```powershell
.\install.ps1 -ProjectDir C:\Projects\my-1c -RulesOnly
.\install.ps1 -Global -RulesOnly
```

Linux и macOS:

```bash
./install.sh --project /path/to/my-1c --rules-only
./install.sh --global --rules-only
```

Ставятся файлы правил и блок в `AGENTS.md`. Скиллы и команды не копируются и при таком запуске не удаляются.

## 6. Только скиллы

Windows:

```powershell
.\install.ps1 -ProjectDir C:\Projects\my-1c -SkillsOnly
.\install.ps1 -Global -SkillsOnly
```

Linux и macOS:

```bash
./install.sh --project /path/to/my-1c --skills-only
./install.sh --global --skills-only
```

`AGENTS.md` при этом не меняется. Только команды:

```powershell
.\install.ps1 -CommandsOnly
```

```bash
./install.sh --commands-only
```

Флаги состава можно совмещать. Без них ставится полный комплект: правила, скиллы и команды.

## 7. Как проверить, что установка прошла

Windows, проект:

```powershell
.\install.ps1 -ProjectDir C:\Projects\my-1c -List
Test-Path C:\Projects\my-1c\.opencode\skills\1c-config-router\SKILL.md
Test-Path C:\Projects\my-1c\.opencode\1c-rules\bsl\1c-coding-standards.md
Select-String -Path C:\Projects\my-1c\AGENTS.md -Pattern "1c-opencode-rules:start"
```

Windows, глобально:

```powershell
.\install.ps1 -Global -List
Test-Path "$env:USERPROFILE\.config\opencode\skills\1c-config-router\SKILL.md"
Test-Path "$env:USERPROFILE\.config\opencode\1c-rules\performance\anti_patterns.md"
```

Linux и macOS:

```bash
./install.sh --project /path/to/my-1c --list
test -f /path/to/my-1c/.opencode/skills/1c-config-router/SKILL.md && echo skills-ok
test -f /path/to/my-1c/.opencode/1c-rules/bsl/async-methods-1c.md && echo rules-ok
grep -n "1c-opencode-rules:start" /path/to/my-1c/AGENTS.md
```

В отчете `-List` / `--list` три состояния: `совпадает`, `нет`, `отличается`. После чистой установки отличающихся файлов нет.

Откройте проект в OpenCode заново. В списке скиллов должен быть `1c-config-router`. Команды `/check-uuid`, `/docx-to-md`, `/move-project`, `/browser-debug`, `/quality` появляются из `.opencode/commands` или из глобального `commands`.

Проверка самого репозитория, без установки в проект:

```bash
python tools/validate_ruleset.py
bash tests/install/test_install.sh
```

## 8. Где лежат файлы

Исходники в клоне:

- `skills/<имя>/SKILL.md` — скилл;
- `rules/<раздел>/*.md` — правила;
- `commands/` — тексты команд и `check_uuid_duplicates.py`;
- `templates/rules-index.md` — текст блока для `AGENTS.md`, в нем плейсхолдер `@RULES_ROOT@`.

Установленная копия — каталоги из разделов 3 и 4. Каталог клона после установки можно оставить: обновление идет из него.

## 9. Как обновить

```powershell
Set-Location C:\src\opencode_1c_rules_skills
git pull
.\install.ps1 -Global
```

```bash
cd ~/src/opencode_1c_rules_skills
git pull
./install.sh --global
```

Повторный запуск идемпотентен. Совпавшие файлы не трогаются. Файл, который вы правили, не заменяется молча.

Чтобы принять версию репозитория поверх своих правок:

```powershell
.\install.ps1 -Global -Yes
```

```bash
./install.sh --global --yes
```

Перед заменой копия лежит в `1c-kit-backups/<дата-время>/`. `-Yes` и `--yes` — это и есть подтверждение замены.

В интерактивном запуске на каждый отличающийся файл скрипт показывает `diff` и спрашивает: оставить (`k`), заменить (`r`), заменить все оставшиеся (`a`), прервать (`q`).

В неинтерактивном запуске (нет терминала, либо `-NonInteractive` / `--non-interactive`) новые файлы ставятся, отличающиеся остаются вашими.

## 10. Как удалить набор и не задеть свои файлы

Удаляются только файлы, чей хеш совпадает с манифестом установки. Измененный файл набора остается. Скилл, которого нет в наборе, не удаляется. Из `AGENTS.md` вырезается только блок между маркерами. Если установщик сам создал `AGENTS.md` и своего текста в нем нет, файл удаляется. Если свой текст был, он остается.

Windows:

```powershell
.\install.ps1 -ProjectDir C:\Projects\my-1c -Uninstall
.\install.ps1 -Global -Uninstall -Yes
.\install.ps1 -SkillsOnly -Uninstall -Yes
.\install.ps1 -RulesOnly -Uninstall -Yes
```

Linux и macOS:

```bash
./install.sh --project /path/to/my-1c --uninstall
./install.sh --global --uninstall --yes
./install.sh --skills-only --uninstall --yes
./install.sh --rules-only --uninstall --yes
```

Без `-Yes` / `--yes` скрипт спрашивает подтверждение. В неинтерактивном режиме без этого флага удаление отменяется.

Резервные копии в `1c-kit-backups` скрипт не удаляет. Их можно стереть вручную, когда они не нужны.

## 11. Как подключить правила через opencode.json

По умолчанию правила не попадают в каждый ход. OpenCode не умеет включать инструкцию по маске файла так, как Cursor включает `.mdc` по `globs`. Агент читает нужный файл по указателю в `AGENTS.md`.

Если нужно держать часть правил в контексте всегда, добавьте их в `instructions`. Пример для проекта, после установки:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    ".opencode/1c-rules/bsl/*.md",
    ".opencode/1c-rules/performance/*.md",
    ".opencode/1c-rules/queries/*.md"
  ]
}
```

Глобально тот же массив можно положить в `~/.config/opencode/opencode.json`. Для домашнего каталога путь пишется так:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "~/.config/opencode/1c-rules/bsl/*.md"
  ]
}
```

Полный набор правил — это сотни килобайт. Не подключайте все каталоги, если сессии и так длинные. Установщик сам `opencode.json` не переписывает.

В репозитории набора `opencode.jsonc` указывает `skills` на `./skills`, чтобы скиллы были видны при открытии самого репозитория в OpenCode 2. В чужой проект этот файл не копируется: там скиллы лежат в `.opencode/skills`, и OpenCode находит их без ключа `skills`.

## 12. Свои правила и скиллы

Свой скилл — каталог `.opencode/skills/<имя>/SKILL.md` или `~/.config/opencode/skills/<имя>/SKILL.md`. Поле `name` совпадает с именем каталога. Установщик каталоги, которых нет в наборе, не удаляет и не переименовывает.

Свое правило — отдельный Markdown. Подключите его через `instructions` или дайте на него ссылку в своем `AGENTS.md` вне маркеров набора. Текст вне маркеров обновление набора не затирает. Текст внутри маркеров при обновлении сравнивается с блоком набора и без подтверждения не меняется.

Не кладите свой скилл в каталог с именем скилла набора: при `-Yes` файлы набора в этом каталоге будут обновлены. Соседний файл, которого нет в наборе, останется.

## 13. Типовые проблемы

**Скилл не появляется в OpenCode.** Сессию нужно открыть заново. Проверьте путь: проектный `.opencode/skills/<имя>/SKILL.md` или глобальный `~/.config/opencode/skills/<имя>/SKILL.md`. Имя в frontmatter должно совпадать с каталогом. В OpenCode 1 ключ `skills` в конфиге может не подхватить произвольный каталог. Рабочий путь для обеих веток — каталоги обнаружения выше, их и заполняет установщик.

**Правила «не действуют».** Они не вставляются в ход целиком. В `AGENTS.md` должен быть блок `1c-opencode-rules`. Попросите агента прочитать конкретный файл из указателя перед правкой BSL. Либо подключите нужный каталог через `instructions`, как в разделе 11.

**Установщик отказался заменить файл.** Так и задумано. Смотрите строку `отличается` в `--list`. Замена: интерактивный ответ `r` или флаг `--yes` / `-Yes`. Старая копия — в `1c-kit-backups`.

**Свой AGENTS.md не получил блок.** Без подтверждения блок не дописывается в уже существующий файл. Запустите еще раз и ответьте `r` или добавьте `-Yes`. Свой текст при этом остается.

**Два AGENTS.md спорят.** OpenCode склеивает глобальный и проектный файлы, а не выбирает один. Не копируйте полный текст правил в оба. Глобальный блок и проектный блок с одним и тем же набором дают два одинаковых указателя.

**Windows и кириллица в путях.** Читайте `rules/workflow/1c-cyrillic-windows.md` до первого запуска платформы из скрипта. К установке набора это не относится: установщик пишет в `.opencode` и в `.config\opencode`.

**Команда /quality ничего не записывает.** В репозитории нет хука `hooks/release-writer.mjs`. Команда сообщает об этом и не создает след. См. `docs/migration.md`.

**Нужна платформа, а ее нет.** Скиллы сборки XML, форм, ролей, СКД и валидаторы по выгрузке работают без платформы. Скиллы `1c-db-*`, сборка EPF/ERF в бинарник, веб-публикация и AI-EDT без платформы или EDT не выполняются. Это граница скилла, а не поломка установки.
