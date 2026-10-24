#!/usr/bin/env bash
# test-dev-task-gate-lock.sh — hai `dev-task.sh gate` chạy cùng lúc trên một checkout phải nối tiếp, không chồng nhau.
# VÌ SAO: Claude Code chạy song song các hook PreToolUse khớp `git commit`; sau #57 cả `pre-commit-gate.sh` và
# `pre-bash-guard.sh` gọi gate, hai bản build cùng ghi apps/mobile/build và làm build đỏ ngẫu nhiên (F-077, TRAPS.md).
# Chạy: bash scripts/test-dev-task-gate-lock.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/repo/scripts" "$WORK/repo/.claude"
cp "$SRC/dev-task.sh" "$SRC/_dev-task-verify.sh" "$SRC/_stack-detect.sh" "$WORK/repo/scripts/"
# Mỗi kiểm tra ghi "bắt đầu/kết thúc" vào một nhật ký ngoài repo; chồng nhau = hai "bắt đầu" liền nhau.
cat > "$WORK/repo/.claude/project-commands.sh" <<CMDS
export format=''
export lint='git diff --check'
export typecheck='bash -n scripts/dev-task.sh'
export build='echo start >> "$WORK/trace"; sleep 2; echo end >> "$WORK/trace"'
export test='bash -n scripts/_stack-detect.sh'
CMDS
git -C "$WORK/repo" init -q && git -C "$WORK/repo" add -A && \
  git -C "$WORK/repo" -c user.name=t -c user.email=t@t commit -qm init
( cd "$WORK/repo" && CLAUDE_PROJECT_DIR= bash scripts/dev-task.sh gate >"$WORK/a.log" 2>&1 ) & a=$!
( cd "$WORK/repo" && CLAUDE_PROJECT_DIR= bash scripts/dev-task.sh gate >"$WORK/b.log" 2>&1 ) & b=$!
ra=0; rb=0; wait "$a" || ra=$?; wait "$b" || rb=$?
trace="$(tr '\n' ' ' < "$WORK/trace" 2>/dev/null || true)"
if [ "$trace" != "start end start end " ]; then
  echo "FAIL: hai gate chồng nhau hoặc không chạy đủ (trace: '$trace'; exit $ra/$rb)" >&2
  sed -n '1,20p' "$WORK/a.log" "$WORK/b.log" >&2
  exit 1
fi
[ "$ra" = 0 ] && [ "$rb" = 0 ] || { echo "FAIL: gate không PASS (exit $ra/$rb)" >&2; cat "$WORK/a.log" "$WORK/b.log" >&2; exit 1; }
echo "PASS: hai gate đồng thời chạy nối tiếp (trace: $trace)"
