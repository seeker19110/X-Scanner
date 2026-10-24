#!/usr/bin/env bash
# check-repo-tree.sh — reruns the pre-commit secret and large-file checks on EVERY tracked file
# (BASE-GATE-006: a hook can be skipped with --no-verify, the gate in CI cannot). Patterns and the
# size limit come from scripts/_commit-guard.sh, the single source shared with the hooks.
# Run from the repository root (or a fixture repo): bash scripts/check-repo-tree.sh
set -uo pipefail
# shellcheck source=scripts/_commit-guard.sh
. "$(dirname "$0")/_commit-guard.sh"
fail=0
# Excluded: .xtemplates/scripts/xt.py holds a redacted "BEGIN PRIVATE KEY" marker as redaction test data
# (framework copy, not edited here); gitleaks still scans it in CI.
secrets="$(git grep -I -l -E -e "$COMMIT_GUARD_SECRET_RE" -- . ':(exclude).xtemplates/scripts/xt.py' 2>/dev/null)"
if [ -n "$secrets" ]; then
  echo "FAIL: tracked file(s) contain a key/token-like string (scripts/_commit-guard.sh):" >&2
  printf '  %s\n' $secrets >&2
  fail=1
fi
big=""
while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue
  [ "$(wc -c <"$f")" -gt "$COMMIT_GUARD_MAX_FILE_BYTES" ] && big="$big $f"
done < <(git ls-files -z)
if [ -n "$big" ]; then
  echo "FAIL: tracked file(s) over $COMMIT_GUARD_MAX_FILE_BYTES bytes:$big" >&2
  fail=1
fi
[ "$fail" = 0 ] && echo "PASS: no tracked secret-like string or file over $COMMIT_GUARD_MAX_FILE_BYTES bytes"
exit "$fail"
