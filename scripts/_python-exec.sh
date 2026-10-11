#!/usr/bin/env bash
# _python-exec.sh — Helper dùng chung cho các wrapper shell gọi engine Python.
# Nhận tên engine (không đuôi .py) làm $1, phần còn lại "$@" chuyển tiếp cho engine.
# KHÔNG gọi trực tiếp — được source bởi các wrapper (spec-compiler.sh, arch-health-radar.sh,
# telemetry-log.sh, subagent-dispatch.sh) để tránh lặp boilerplate dò python3/python + tính ROOT.
# Vì file này được `source`, "$0" khi chạy vẫn là đường dẫn của script GỌI (wrapper), không phải
# của chính helper — nên tính ROOT từ "$0" vẫn đúng như hành vi cũ của từng wrapper.

set -euo pipefail

_python_exec_engine="$1"
shift

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo "Error: Python 3 là bắt buộc để chạy ${_python_exec_engine} engine." >&2
  exit 1
fi

exec "$PYTHON_CMD" "$ROOT/scripts/${_python_exec_engine}.py" "$@"
