#!/usr/bin/env python3
"""APK size budget (XC-GREEN-002).

Fails when the built APK is missing or larger than max_bytes in the budget file. The budget file also
records the measured baseline; raise max_bytes only in a reviewed PR that says why the app grew.
Usage: python3 scripts/check-apk-size.py --apk <path> --budget apps/mobile/apk-size-budget.json
"""
import argparse
import json
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--budget', type=Path, required=True)
    args = parser.parse_args()
    try:
        size = args.apk.stat().st_size
        limit = int(json.loads(args.budget.read_text(encoding='utf-8'))['max_bytes'])
    except (OSError, ValueError, KeyError) as error:
        print(f'FAIL: cannot check APK size: {error}', file=sys.stderr)
        return 1
    verdict = 'PASS' if size <= limit else 'FAIL'
    print(f'{verdict}: {args.apk.name} is {size} bytes (budget {limit} bytes)')
    return 0 if size <= limit else 1


if __name__ == '__main__':
    sys.exit(main())
