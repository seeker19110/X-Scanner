#!/usr/bin/env python3
"""Kiểm mọi mục MUST của BLUEPRINT.md đã được phân loại (T-003, docs/autopilot/PLAN.md).

Đạt khi mỗi dòng MUST là `[x]` kèm `— Bằng chứng:`, `[~]` kèm `— Không áp dụng:`/`— Miễn:`, hoặc `[ ]` kèm
`— Thiếu:` và ID đó đang được `xt.py loop defer` cho người (.autopilot/state.json). Không đo việc MUST đã
đạt hết: điều đó là `xt.py blueprint-status --strict`.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINE = re.compile(r"^\s*- \[(.)\] `([A-Z0-9-]+)` \*\*MUST")


def deferred_ids() -> set:
    try:
        state = json.loads((ROOT / ".autopilot/state.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return set()
    found = set()
    for item in state.get("deferred", []) or []:
        found.add(item.get("task") if isinstance(item, dict) else str(item))
    if isinstance(state.get("deferred"), dict):
        found |= set(state["deferred"])
    return found


def main() -> int:
    deferred = deferred_ids()
    bad = []
    total = 0
    for n, line in enumerate((ROOT / "BLUEPRINT.md").read_text(encoding="utf-8").splitlines(), 1):
        m = LINE.match(line)
        if not m:
            continue
        total += 1
        box, item = m.groups()
        ok = (
            (box == "x" and "— Bằng chứng:" in line)
            or (box == "~" and ("— Không áp dụng:" in line or "— Miễn:" in line))
            or (box == " " and "— Thiếu:" in line and item in deferred)
        )
        if not ok:
            bad.append(f"{item} (dòng {n})")
    if bad:
        print(f"CHƯA PHÂN LOẠI {len(bad)}/{total} MUST: " + ", ".join(bad[:20]), file=sys.stderr)
        return 1
    print(f"PASS: {total} MUST đều có kết cục (bằng chứng / không áp dụng / chờ người đã defer)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
