#!/usr/bin/env bash
# subagent-dispatch.sh — Wrapper script cho Universal Subagent Dispatcher Engine.
# Hoạt động an toàn trên mọi hệ điều hành (Linux, macOS, Windows/MSYS).

source "$(cd "$(dirname "$0")" && pwd)/_python-exec.sh" "subagent-dispatch" "$@"
