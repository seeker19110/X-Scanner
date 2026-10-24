#!/usr/bin/env python3
"""APK size budget (XC-GREEN-002).

Fails when the built APK is missing, is not a zip, or its contents are larger than max_bytes in the budget
file. It measures the uncompressed size of the entries, not the file: Gradle repackages a debug APK
incrementally in an old build folder with other compression, so the same contents gave 163 MB fresh and
191 MB incremental (TRAPS.md). The budget file also records the measured baseline; raise max_bytes only in
a reviewed PR that says why the app grew.
Usage: python3 scripts/check-apk-size.py --apk <path> --budget apps/mobile/apk-size-budget.json
"""
import argparse
import json
import sys
import zipfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--budget', type=Path, required=True)
    args = parser.parse_args()
    try:
        with zipfile.ZipFile(args.apk) as apk:
            size = sum(entry.file_size for entry in apk.infolist())
        limit = int(json.loads(args.budget.read_text(encoding='utf-8'))['max_bytes'])
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        print(f'FAIL: cannot check APK size: {error}', file=sys.stderr)
        return 1
    verdict = 'PASS' if size <= limit else 'FAIL'
    print(f'{verdict}: {args.apk.name} contents are {size} bytes uncompressed (budget {limit} bytes)')
    return 0 if size <= limit else 1


if __name__ == '__main__':
    sys.exit(main())
