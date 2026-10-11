#!/usr/bin/env bash
# Reviewed: docs/specs/2026-10-11-framework-adoption.md; assignments only, no secrets.
export gate_tools='bash git python3 jq'
export lint='python3 scripts/check-adoption.py --lint'
export test='python3 scripts/check-adoption.py && bash scripts/test-hooks-gate.sh && bash scripts/test-hooks-gate-guard.sh'
export gate_skip_build_reason='Adoption-only: no application source or chosen SDK; not a mobile build. Replace before product implementation.'
export gate_skip_typecheck_reason='Adoption-only docs and Bash; syntax/JSON checks run in lint. Add real language analysis when the app stack is chosen.'
