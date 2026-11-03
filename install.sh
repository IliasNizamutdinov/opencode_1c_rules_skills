#!/usr/bin/env bash
# Установщик правил и скиллов 1С для OpenCode.
# Не перезаписывает отличающиеся файлы без подтверждения и не удаляет чужие скиллы.
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(pwd)"
GLOBAL=0
LIST=0
UNINSTALL=0
YES=0
NONINTERACTIVE=0
DRY=0
DO_RULES=0
DO_SKILLS=0
DO_COMMANDS=0
ANY_COMPONENT=0

usage() {
  cat <<'EOF'
Использование: ./install.sh [режим] [состав]

Режим:
  --project <каталог>   установка в проект (по умолчанию текущий каталог)
  --global              установка в ~/.config/opencode (или $XDG_CONFIG_HOME/opencode)
  --list                показать, что уже стоит, ничего не менять
  --uninstall           снять файлы набора, которые не менялись после установки
  --yes                 подтвердить замену отличающихся файлов и удаление при --uninstall
  --non-interactive     не спрашивать: новые файлы ставить, отличающиеся не трогать
  --dry-run             показать действия без записи

Состав (по умолчанию все):
  --rules-only
  --skills-only
  --commands-only

Флаги состава можно совмещать. Без них ставятся правила, скиллы и команды.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="$(cd "$2" && pwd)"
      shift 2
      ;;
    --global) GLOBAL=1; shift ;;
    --list) LIST=0; LIST=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --yes) YES=1; shift ;;
    --non-interactive) NONINTERACTIVE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --rules-only) DO_RULES=1; ANY_COMPONENT=1; shift ;;
    --skills-only) DO_SKILLS=1; ANY_COMPONENT=1; shift ;;
    --commands-only) DO_COMMANDS=1; ANY_COMPONENT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Неизвестный аргумент: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$ANY_COMPONENT" -eq 0 ]]; then
  DO_RULES=1
  DO_SKILLS=1
  DO_COMMANDS=1
fi

if [[ ! -t 0 && "$YES" -eq 0 ]]; then
  NONINTERACTIVE=1
fi

if [[ "$GLOBAL" -eq 1 ]]; then
  CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  BASE="$CONFIG_ROOT"
  AGENTS_FILE="$CONFIG_ROOT/AGENTS.md"
  MANIFEST="$CONFIG_ROOT/1c-kit-manifest.tsv"
  BACKUP_ROOT="$CONFIG_ROOT/1c-kit-backups"
  RULES_LINK="$CONFIG_ROOT/1c-rules"
  SCOPE="global"
else
  BASE="$PROJECT/.opencode"
  AGENTS_FILE="$PROJECT/AGENTS.md"
  MANIFEST="$BASE/1c-kit-manifest.tsv"
  BACKUP_ROOT="$BASE/1c-kit-backups"
  RULES_LINK=".opencode/1c-rules"
  SCOPE="project"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
REPLACE_ALL=0
if [[ "$YES" -eq 1 ]]; then
  REPLACE_ALL=1
fi

is_text() {
  case "${1##*.}" in
    md|markdown|txt|json|yml|yaml|py|ps1|sh|mjs|js|bsl|xml|csv|tsv) return 0 ;;
    *) return 1 ;;
  esac
}

hash_file() {
  if is_text "$1"; then
    tr -d '\r' < "$1" | sha256sum | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

backup_dest() {
  local dest="$1"
  local root dest_rel backup
  if [[ "$SCOPE" == "project" ]]; then
    root="$PROJECT"
  else
    root="$CONFIG_ROOT"
  fi
  dest_rel="${dest#"$root"/}"
  backup="$BACKUP_ROOT/$STAMP/$dest_rel"
  mkdir -p "$(dirname "$backup")"
  cp -p "$dest" "$backup"
  echo "$backup"
}

collect_sources() {
  SOURCES_FILE="$(mktemp)"
  if [[ "$DO_SKILLS" -eq 1 ]]; then
    find "$SOURCE/skills" -type f ! -path '*/__pycache__/*' ! -name '*.pyc' | while read -r file; do
      rel="skills/${file#"$SOURCE/skills/"}"
      printf '%s\t%s\t%s\n' "$rel" "$file" "skills"
    done >> "$SOURCES_FILE"
  fi
  if [[ "$DO_RULES" -eq 1 ]]; then
    find "$SOURCE/rules" -type f ! -name 'README.md' | while read -r file; do
      rel="1c-rules/${file#"$SOURCE/rules/"}"
      printf '%s\t%s\t%s\n' "$rel" "$file" "rules"
    done >> "$SOURCES_FILE"
  fi
  if [[ "$DO_COMMANDS" -eq 1 ]]; then
    find "$SOURCE/commands" -type f | while read -r file; do
      rel="commands/${file#"$SOURCE/commands/"}"
      printf '%s\t%s\t%s\n' "$rel" "$file" "commands"
    done >> "$SOURCES_FILE"
  fi
}

# Поля манифеста в файлах состояния, чтобы не требовать bash 4.
STATE="$(mktemp -d)"
mkdir -p "$STATE/old" "$STATE/new"
AGENTS_CREATED=0
OLD_AGENTS_CREATED=0

dest_for() {
  # relpath is skills/..., commands/..., 1c-rules/...
  printf '%s/%s\n' "$BASE" "$1"
}

confirm_replace() {
  local dest="$1" src="$2"
  if [[ "$REPLACE_ALL" -eq 1 ]]; then
    return 0
  fi
  if [[ "$NONINTERACTIVE" -eq 1 || "$DRY" -eq 1 ]]; then
    return 1
  fi
  echo "Файл уже есть и отличается от версии набора:"
  echo "  $dest"
  echo "Замена обновит файл до версии репозитория. Перед заменой будет резервная копия."
  diff -u "$dest" "$src" | head -n 120 || true
  echo "Действие: [k] оставить вашу версию, [r] заменить, [a] заменить все оставшиеся, [q] прервать"
  local answer
  read -r answer
  case "$answer" in
    r|R) return 0 ;;
    a|A) REPLACE_ALL=1; return 0 ;;
    q|Q) echo "Установка прервана."; exit 2 ;;
    *) return 1 ;;
  esac
}

COPIED=0
SAME=0
KEPT=0
REPLACED=0

install_one() {
  local rel="$1" src="$2" component="$3"
  local dest hash old
  dest="$(dest_for "$rel")"
  hash="$(hash_file "$src")"
  if [[ ! -e "$dest" ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "поставить $rel"
    else
      mkdir -p "$(dirname "$dest")"
      cp -p "$src" "$dest"
    fi
    COPIED=$((COPIED + 1))
    record_new "$hash" "$component" "$rel"
    return
  fi
  old="$(hash_file "$dest")"
  if [[ "$old" == "$hash" ]]; then
    SAME=$((SAME + 1))
    record_new "$hash" "$component" "$rel"
    return
  fi
  echo "отличается: $rel"
  if confirm_replace "$dest" "$src"; then
    if [[ "$DRY" -eq 0 ]]; then
      local backup
      backup="$(backup_dest "$dest" "$rel")"
      cp -p "$src" "$dest"
      echo "  заменен, копия: $backup"
    else
      echo "  dry-run: был бы заменен"
    fi
    REPLACED=$((REPLACED + 1))
    record_new "$hash" "$component" "$rel"
  else
    echo "  оставлена ваша версия"
    KEPT=$((KEPT + 1))
    if [[ -f "$STATE/old/$(manifest_key "$rel")" ]]; then
      cp "$STATE/old/$(manifest_key "$rel")" "$STATE/new/$(manifest_key "$rel")"
    fi
  fi
}

manifest_key() {
  printf '%s' "$1" | sha256sum | awk '{print $1}'
}

record_new() {
  local hash="$1" component="$2" rel="$3"
  printf '%s\t%s\t%s\n' "$hash" "$component" "$rel" > "$STATE/new/$(manifest_key "$rel")"
}

write_manifest() {
  local tmp="$MANIFEST.tmp"
  mkdir -p "$(dirname "$MANIFEST")"
  {
    echo -e "# opencode-1c-kit\t1"
    printf 'meta\tagents_created\t%s\n' "$AGENTS_CREATED"
    printf 'meta\tscope\t%s\n' "$SCOPE"
    local entry hash component rel
    for entry in "$STATE/new"/*; do
      [[ -e "$entry" ]] || continue
      IFS=$'\t' read -r hash component rel < "$entry"
      printf 'file\t%s\t%s\t%s\n' "$hash" "$component" "$rel"
    done
    if [[ -f "$MANIFEST" ]]; then
      while IFS=$'\t' read -r kind hash component rel; do
        [[ "$kind" == "file" ]] || continue
        case "$component" in
          skills) [[ "$DO_SKILLS" -eq 1 ]] && continue ;;
          rules) [[ "$DO_RULES" -eq 1 ]] && continue ;;
          commands) [[ "$DO_COMMANDS" -eq 1 ]] && continue ;;
        esac
        printf 'file\t%s\t%s\t%s\n' "$hash" "$component" "$rel"
      done < "$MANIFEST"
    fi
  } > "$tmp"
  mv "$tmp" "$MANIFEST"
}

# Перечитываю load_manifest: формат file<TAB>sha<TAB>component<TAB>rel
# Состояние old хранит sha<TAB>component<TAB>rel по ключу пути.
load_manifest() {
  AGENTS_CREATED=0
  OLD_AGENTS_CREATED=0
  [[ -f "$MANIFEST" ]] || return 0
  while IFS=$'\t' read -r kind a b c; do
    [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
    if [[ "$kind" == "meta" && "$a" == "agents_created" ]]; then
      OLD_AGENTS_CREATED="$b"
      AGENTS_CREATED="$b"
    elif [[ "$kind" == "file" ]]; then
      printf '%s\t%s\t%s\n' "$a" "$b" "$c" > "$STATE/old/$(manifest_key "$c")"
    fi
  done < "$MANIFEST"
}

apply_agents_block() {
  [[ "$DO_RULES" -eq 1 ]] || return 0
  local block old new_file
  block="$(sed "s#@RULES_ROOT@#${RULES_LINK}#g" "$SOURCE/templates/rules-index.md")"
  block="$(printf '%s\n%s\n%s\n' '<!-- 1c-opencode-rules:start -->' "$block" '<!-- 1c-opencode-rules:end -->')"
  if [[ ! -f "$AGENTS_FILE" ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "создать $AGENTS_FILE"
      return 0
    fi
    mkdir -p "$(dirname "$AGENTS_FILE")"
    printf '%s\n' "$block" > "$AGENTS_FILE"
    AGENTS_CREATED=1
    echo "создан $AGENTS_FILE"
    return 0
  fi
  if grep -q '1c-opencode-rules:start' "$AGENTS_FILE"; then
    local current
    current="$(awk '
      /<!-- 1c-opencode-rules:start -->/ {p=1}
      p {print}
      /<!-- 1c-opencode-rules:end -->/ {p=0}
    ' "$AGENTS_FILE")"
    if [[ "$(printf '%s\n' "$current" | tr -d '\r')" == "$(printf '%s\n' "$block" | tr -d '\r')" ]]; then
      echo "блок правил в AGENTS.md совпадает"
      return 0
    fi
    echo "блок правил в AGENTS.md отличается"
    if ! confirm_replace "$AGENTS_FILE" <(printf '%s\n' "$block"); then
      echo "  блок правил оставлен как есть"
      KEPT=$((KEPT + 1))
      return 0
    fi
    if [[ "$DRY" -eq 1 ]]; then
      echo "  dry-run: блок был бы заменен"
      return 0
    fi
    backup_dest "$AGENTS_FILE" "AGENTS.md" >/dev/null
    new_file="$(mktemp)"
    awk '
      BEGIN {skip=0}
      /<!-- 1c-opencode-rules:start -->/ {skip=1; next}
      /<!-- 1c-opencode-rules:end -->/ {skip=0; next}
      skip==0 {print}
    ' "$AGENTS_FILE" > "$new_file"
    printf '\n%s\n' "$block" >> "$new_file"
    mv "$new_file" "$AGENTS_FILE"
    echo "  блок правил обновлен"
    REPLACED=$((REPLACED + 1))
    return 0
  fi
  echo "В $AGENTS_FILE нет блока набора. Будет добавлен в конец, остальной текст не изменится."
  if ! confirm_replace "$AGENTS_FILE" <(printf '%s\n' "$block"); then
    echo "  блок не добавлен. Подключите правила вручную, см. docs/installation.md"
    KEPT=$((KEPT + 1))
    return 0
  fi
  if [[ "$DRY" -eq 1 ]]; then
    echo "  dry-run: блок был бы добавлен"
    return 0
  fi
  backup_dest "$AGENTS_FILE" "AGENTS.md" >/dev/null
  printf '\n%s\n' "$block" >> "$AGENTS_FILE"
  echo "  блок добавлен в конец $AGENTS_FILE"
  REPLACED=$((REPLACED + 1))
}

remove_obsolete() {
  [[ "$DRY" -eq 1 ]] && return 0
  local key entry hash component rel dest current
  for entry in "$STATE/old"/*; do
    [[ -e "$entry" ]] || continue
    key="$(basename "$entry")"
    [[ -f "$STATE/new/$key" ]] && continue
    IFS=$'\t' read -r hash component rel < "$entry"
    case "$component" in
      skills) [[ "$DO_SKILLS" -eq 1 ]] || continue ;;
      rules) [[ "$DO_RULES" -eq 1 ]] || continue ;;
      commands) [[ "$DO_COMMANDS" -eq 1 ]] || continue ;;
      *) continue ;;
    esac
    dest="$(dest_for "$rel")"
    [[ -f "$dest" ]] || continue
    current="$(hash_file "$dest")"
    if [[ "$current" == "$hash" ]]; then
      rm -f "$dest"
      echo "удален устаревший файл набора: $rel"
    else
      echo "устаревший файл изменен вами, оставлен: $rel"
    fi
  done
}

cmd_list() {
  collect_sources
  local missing=0 modified=0 ok=0 rel src component dest
  while IFS=$'\t' read -r rel src component; do
    [[ -z "$rel" ]] && continue
    dest="$(dest_for "$rel")"
    if [[ ! -f "$dest" ]]; then
      echo "нет       $rel"
      missing=$((missing + 1))
    elif [[ "$(hash_file "$dest")" == "$(hash_file "$src")" ]]; then
      echo "совпадает $rel"
      ok=$((ok + 1))
    else
      echo "отличается $rel"
      modified=$((modified + 1))
    fi
  done < "$SOURCES_FILE"
  echo "Совпадает: $ok, нет: $missing, отличается: $modified"
  echo "Каталог: $BASE"
  if [[ -f "$AGENTS_FILE" ]] && grep -q '1c-opencode-rules:start' "$AGENTS_FILE"; then
    echo "Блок правил в $AGENTS_FILE: есть"
  else
    echo "Блок правил в $AGENTS_FILE: нет"
  fi
}

cmd_uninstall() {
  if [[ ! -f "$MANIFEST" ]]; then
    echo "Манифест не найден: $MANIFEST. Удалять нечего."
    exit 0
  fi
  if [[ "$YES" -eq 0 && "$NONINTERACTIVE" -eq 1 ]]; then
    echo "Удаление без --yes в неинтерактивном режиме отменено."
    exit 2
  fi
  if [[ "$YES" -eq 0 ]]; then
    echo "Будут удалены только файлы набора, которые совпадают с манифестом."
    echo "Измененные и чужие файлы останутся. Продолжить? [y/N]"
    local answer
    read -r answer
    case "$answer" in
      y|Y) ;;
      *) echo "Отменено."; exit 2 ;;
    esac
  fi
  load_manifest
  local entry hash component rel dest current removed=0 kept=0
  for entry in "$STATE/old"/*; do
    [[ -e "$entry" ]] || continue
    IFS=$'\t' read -r hash component rel < "$entry"
    case "$component" in
      skills) [[ "$DO_SKILLS" -eq 1 ]] || continue ;;
      rules) [[ "$DO_RULES" -eq 1 ]] || continue ;;
      commands) [[ "$DO_COMMANDS" -eq 1 ]] || continue ;;
    esac
    dest="$(dest_for "$rel")"
    if [[ ! -f "$dest" ]]; then
      continue
    fi
    current="$(hash_file "$dest")"
    if [[ "$current" == "$hash" ]]; then
      rm -f "$dest"
      removed=$((removed + 1))
      echo "удален $rel"
    else
      kept=$((kept + 1))
      echo "оставлен измененный $rel"
    fi
  done
  if [[ "$DO_RULES" -eq 1 && -f "$AGENTS_FILE" ]] && grep -q '1c-opencode-rules:start' "$AGENTS_FILE"; then
    backup_dest "$AGENTS_FILE" "AGENTS.md" >/dev/null
    local stripped
    stripped="$(mktemp)"
    awk '
      BEGIN {skip=0}
      /<!-- 1c-opencode-rules:start -->/ {skip=1; next}
      /<!-- 1c-opencode-rules:end -->/ {skip=0; next}
      skip==0 {print}
    ' "$AGENTS_FILE" > "$stripped"
    if [[ "$AGENTS_CREATED" == "1" ]] && [[ -z "$(tr -d '[:space:]' < "$stripped")" ]]; then
      rm -f "$AGENTS_FILE" "$stripped"
      echo "удален $AGENTS_FILE (его создал установщик, своего текста не было)"
    else
      mv "$stripped" "$AGENTS_FILE"
      echo "из $AGENTS_FILE удален только блок набора"
    fi
    AGENTS_CREATED=0
  fi
  # пересобрать манифест без удаленных компонентов
  DO_RULES_SAVED=$DO_RULES
  DO_SKILLS_SAVED=$DO_SKILLS
  DO_COMMANDS_SAVED=$DO_COMMANDS
  # write_manifest копирует невыбранные компоненты. Сначала очистим new и
  # пометим выбранные как "ставились", чтобы они не вернулись из старого манифеста.
  rm -rf "$STATE/new"
  mkdir -p "$STATE/new"
  # Временно считаем выбранные компоненты обработанными: write_manifest берет
  # из старого файла только невыбранные.
  write_manifest
  echo "Удалено файлов: $removed, оставлено измененных: $kept"
}

cmd_install() {
  collect_sources
  load_manifest
  local rel src component
  while IFS=$'\t' read -r rel src component; do
    [[ -z "$rel" ]] && continue
    install_one "$rel" "$src" "$component"
  done < "$SOURCES_FILE"
  remove_obsolete
  apply_agents_block
  if [[ "$DRY" -eq 0 ]]; then
    write_manifest
  fi
  echo "Готово ($SCOPE): поставлено $COPIED, без изменений $SAME, заменено $REPLACED, оставлено ваших $KEPT"
  echo "Каталог: $BASE"
  if [[ "$DO_RULES" -eq 1 ]]; then
    echo "Правила: $RULES_LINK"
    echo "Указатель: $AGENTS_FILE"
  fi
}

if [[ "$LIST" -eq 1 ]]; then
  cmd_list
elif [[ "$UNINSTALL" -eq 1 ]]; then
  cmd_uninstall
else
  cmd_install
fi
