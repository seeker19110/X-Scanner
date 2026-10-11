#!/usr/bin/env bash
# arch-health-radar.sh — Shell wrapper cho Architectural Health & Tech Debt Radar Engine.

source "$(cd "$(dirname "$0")" && pwd)/_python-exec.sh" "arch-health-radar" "$@"
