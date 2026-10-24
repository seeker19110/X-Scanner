#!/usr/bin/env bash
# flutter-version.sh — prints the pinned Flutter version, single source apps/mobile/pubspec.yaml
# (environment.flutter, exact). CI installs this version (XC-DX-003); the archive checksum stays in ci.yml.
set -euo pipefail
pubspec="$(dirname "$0")/../apps/mobile/pubspec.yaml"
version="$(sed -n 's/^  flutter: *\([0-9][0-9.]*\) *$/\1/p' "$pubspec")"
[ "$(printf '%s\n' "$version" | grep -c .)" = 1 ] || { echo "flutter-version: need exactly one 'flutter: X.Y.Z' in $pubspec" >&2; exit 1; }
printf '%s\n' "$version"
