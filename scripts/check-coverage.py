#!/usr/bin/env python3
"""Coverage ratchet (QA-COV-001, QA-COV-002).

Reads an lcov file (flutter test --branch-coverage) and fails when line or branch coverage is below
the committed baseline. --update raises the baseline to the current values and refuses to lower it.
Usage: python3 scripts/check-coverage.py --lcov apps/mobile/coverage/lcov.info \
           --baseline apps/mobile/coverage-baseline.json [--update]
"""

import argparse
import json
import sys
from pathlib import Path

METRICS = {"DA": "lines", "BRDA": "branches"}


def measure(lcov):
    """Counts DA (line) and BRDA (branch) records; Flutter's lcov has BRDA but no BRF/BRH totals."""
    found = {metric: 0 for metric in METRICS.values()}
    hit = {metric: 0 for metric in METRICS.values()}
    for line in lcov.read_text(encoding="utf-8").splitlines():
        key, _, value = line.partition(":")
        metric = METRICS.get(key)
        if metric:
            count = value.split(",")[-1]
            found[metric] += 1
            hit[metric] += count not in ("-", "0")
    result = {}
    for metric in METRICS.values():
        if found[metric] == 0:
            raise ValueError(f"{lcov}: no {metric} data; run flutter test --branch-coverage")
        result[metric] = round(100.0 * hit[metric] / found[metric], 2)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lcov", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--update", action="store_true")
    args = parser.parse_args()
    try:
        current = measure(args.lcov)
        baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    drops = [m for m in METRICS.values() if current[m] < float(baseline.get(m, 0))]
    summary = ", ".join(
        f"{m} {current[m]:.2f}% (baseline {float(baseline.get(m, 0)):.2f}%)"
        for m in METRICS.values()
    )
    if drops:
        print(f"FAIL: coverage dropped: {summary}", file=sys.stderr)
        if args.update:
            print("FAIL: --update never lowers the baseline", file=sys.stderr)
        return 1
    if args.update:
        args.baseline.write_text(
            json.dumps({**baseline, **current}, indent=2) + "\n", encoding="utf-8"
        )
        print(f"UPDATED: {args.baseline} -> {summary}")
        return 0
    print(f"PASS: {summary}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
