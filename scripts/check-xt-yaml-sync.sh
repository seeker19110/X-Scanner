#!/usr/bin/env bash
# Kiểm `xt.yaml` (đọc bởi .xtemplates/scripts/dev-task.sh của khung X-Templates) khớp từng lệnh cổng với
# `.claude/project-commands.sh` (cổng thật mà scripts/dev-task.sh và CI chạy). Lệch = exit 1 kèm tên khoá.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/.claude/project-commands.sh"
fail=0
for key in format lint typecheck test build; do
  want="${!key-}"
  got="$(python3 - "$ROOT/xt.yaml" "$key" <<'PY'
import json, re, sys
for line in open(sys.argv[1], encoding='utf-8'):
    m = re.match(r'^' + re.escape(sys.argv[2]) + r':\s*(".*")\s*$', line)
    if m:
        print(json.loads(m.group(1)))
        break
PY
)"
  if [ "$want" != "$got" ]; then
    echo "LỆCH [$key]: project-commands.sh và xt.yaml khác nhau" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "PASS: xt.yaml khớp .claude/project-commands.sh (format, lint, typecheck, test, build)"
exit "$fail"
