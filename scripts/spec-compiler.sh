#!/usr/bin/env bash
# spec-compiler.sh — Shell wrapper cho Autonomous Spec-to-Contract Compiler Engine.

source "$(cd "$(dirname "$0")" && pwd)/_python-exec.sh" "spec-compiler" "$@"
