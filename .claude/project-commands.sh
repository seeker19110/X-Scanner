#!/usr/bin/env bash
# Reviewed: docs/specs/2026-10-11-p0-foundation.md (ADR-0002); assignments only, no secrets.
# Flutter app gates run in apps/mobile; each command runs in its own bash -c from the repo root.
export gate_tools='bash git python3 jq flutter'
export format='cd apps/mobile && dart format lib test'
export lint='python3 scripts/check-adoption.py --lint && cd apps/mobile && dart format --output=none --set-exit-if-changed lib test'
export typecheck='cd apps/mobile && flutter analyze --fatal-infos'
export test='python3 scripts/check-adoption.py && python3 scripts/check-release-manifest.py --self-test && bash scripts/test-hooks-gate.sh && bash scripts/test-hooks-gate-guard.sh && cd apps/mobile && flutter test'
# build also merges the release manifest (~2-3 s) and fails on new permissions/exported components (F-008).
export build='(cd apps/mobile && flutter pub get --enforce-lockfile && flutter build apk --debug && cd android && ./gradlew -q :app:processReleaseMainManifest) && python3 scripts/check-release-manifest.py apps/mobile/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml'
