#!/usr/bin/env bash
# Проверка установщика на временных каталогах. Не трогает домашний каталог агента.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"
mkdir -p "$HOME"
PROJ="$WORK/proj"
mkdir -p "$PROJ"
INSTALL="$ROOT/install.sh"

run() {
  local log="$WORK/last.log"
  "$@" >"$log"
  cat "$log"
}

echo "== проект, только скиллы =="
run "$INSTALL" --non-interactive --project "$PROJ" --skills-only
[[ -f "$PROJ/.opencode/skills/1c-cf-info/SKILL.md" ]] || fail "скилл не скопирован"
[[ ! -d "$PROJ/.opencode/1c-rules" ]] || fail "правила попали в установку только скиллов"
[[ ! -f "$PROJ/AGENTS.md" ]] || fail "AGENTS.md создан без правил"
[[ ! -f "$PROJ/opencode.json" ]] || fail "opencode.json создан без правил"
grep -q "1c-cf-info" "$PROJ/.opencode/1c-kit-manifest.tsv" || fail "нет записи в манифесте"

echo "== повтор без изменений =="
run "$INSTALL" --non-interactive --project "$PROJ" --skills-only
grep -q "поставлено 0" "$WORK/last.log"

echo "== пользовательский скилл и правка =="
mkdir -p "$PROJ/.opencode/skills/my-own-skill"
echo "user" > "$PROJ/.opencode/skills/my-own-skill/SKILL.md"
echo "user-edit" >> "$PROJ/.opencode/skills/1c-cf-info/SKILL.md"
run "$INSTALL" --non-interactive --project "$PROJ" --skills-only
grep -q "оставлено ваших" "$WORK/last.log"
grep -q "user-edit" "$PROJ/.opencode/skills/1c-cf-info/SKILL.md" || fail "правка скилла затерта"
[[ -f "$PROJ/.opencode/skills/my-own-skill/SKILL.md" ]] || fail "чужой скилл удален"

echo "== замена с --yes и резервная копия =="
run "$INSTALL" --non-interactive --yes --project "$PROJ" --skills-only
grep -q "заменено" "$WORK/last.log"
grep -q "user-edit" "$PROJ/.opencode/skills/1c-cf-info/SKILL.md" && fail "правка должна была смениться версией набора"
find "$PROJ/.opencode/1c-kit-backups" -name 'SKILL.md' | grep -q . || fail "нет резервной копии"

echo "== правила поверх своего AGENTS.md =="
printf 'Мои инструкции\n' > "$PROJ/AGENTS.md"
run "$INSTALL" --non-interactive --project "$PROJ" --rules-only
grep -q "блок не добавлен" "$WORK/last.log"
grep -qx 'Мои инструкции' "$PROJ/AGENTS.md" || fail "свой AGENTS.md изменен без спроса"
run "$INSTALL" --non-interactive --yes --project "$PROJ" --rules-only
grep -q 'Мои инструкции' "$PROJ/AGENTS.md" || fail "свой текст пропал"
grep -q '1c-opencode-rules:start' "$PROJ/AGENTS.md" || fail "блок не добавлен"
[[ -f "$PROJ/.opencode/1c-rules/bsl/async-methods-1c.md" ]] || fail "правило не на месте"
python3 - "$PROJ/opencode.json" <<'PY' || fail "не все правила попали в instructions"
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
items = data.get("instructions") or []
need = ".opencode/1c-rules/bsl/async-methods-1c.md"
if need not in items or len(items) < 49:
    raise SystemExit(1)
PY

echo "== глобально, только команды =="
run "$INSTALL" --non-interactive --global --commands-only
[[ -f "$HOME/.config/opencode/commands/check-uuid.md" ]] || fail "команда не встала глобально"
[[ -f "$HOME/.config/opencode/commands/check_uuid_duplicates.py" ]] || fail "скрипт команды не встал"
[[ ! -d "$HOME/.config/opencode/skills" ]] || fail "глобальные скиллы появились без запроса"

echo "== удаление скиллов проекта сохраняет чужое и измененное =="
echo "keep-me" >> "$PROJ/.opencode/skills/1c-meta-compile/SKILL.md"
run "$INSTALL" --non-interactive --yes --project "$PROJ" --uninstall --skills-only
[[ ! -f "$PROJ/.opencode/skills/1c-cf-info/SKILL.md" ]] || fail "неизмененный скилл не удален"
grep -q "keep-me" "$PROJ/.opencode/skills/1c-meta-compile/SKILL.md" || fail "измененный скилл удален"
[[ -f "$PROJ/.opencode/skills/my-own-skill/SKILL.md" ]] || fail "чужой скилл удален при удалении набора"
grep -q 'Мои инструкции' "$PROJ/AGENTS.md" || fail "AGENTS.md пострадал при удалении скиллов"
grep -q '1c-opencode-rules:start' "$PROJ/AGENTS.md" || fail "блок правил снят вместе со скиллами"

echo "== удаление правил снимает блок и оставляет свой текст =="
run "$INSTALL" --non-interactive --yes --project "$PROJ" --uninstall --rules-only
grep -q 'Мои инструкции' "$PROJ/AGENTS.md" || fail "свой текст удален вместе с блоком"
grep -q '1c-opencode-rules:start' "$PROJ/AGENTS.md" && fail "блок правил остался"
[[ ! -f "$PROJ/.opencode/1c-rules/bsl/async-methods-1c.md" ]] || fail "правило не удалено"
[[ ! -f "$PROJ/opencode.json" ]] || fail "созданный установщиком opencode.json не удален"

echo "== пустой проект: установка и полное удаление AGENTS.md =="
PROJ2="$WORK/proj2"
mkdir -p "$PROJ2"
run "$INSTALL" --non-interactive --project "$PROJ2" --rules-only
run "$INSTALL" --non-interactive --yes --project "$PROJ2" --uninstall --rules-only
[[ ! -f "$PROJ2/AGENTS.md" ]] || fail "созданный установщиком AGENTS.md не удален"
[[ ! -f "$PROJ2/opencode.json" ]] || fail "созданный установщиком opencode.json не удален"

echo "== свой opencode.json сохраняет чужие ключи =="
PROJ3="$WORK/proj3"
mkdir -p "$PROJ3"
printf '%s\n' '{"model":"keep-me"}' > "$PROJ3/opencode.json"
run "$INSTALL" --non-interactive --project "$PROJ3" --rules-only
python3 - "$PROJ3/opencode.json" <<'PY' || fail "чужой ключ opencode.json потерян или правила не добавлены"
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
if data.get("model") != "keep-me":
    raise SystemExit(1)
if ".opencode/1c-rules/workflow/model-selection.md" not in data.get("instructions", []):
    raise SystemExit(2)
PY
run "$INSTALL" --non-interactive --yes --project "$PROJ3" --uninstall --rules-only
python3 - "$PROJ3/opencode.json" <<'PY' || fail "после удаления чужой opencode.json испорчен"
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
if data.get("model") != "keep-me":
    raise SystemExit(1)
items = data.get("instructions") or []
if any("1c-rules/" in item for item in items):
    raise SystemExit(2)
PY

echo "OK"
