#!/usr/bin/env python3
"""Offline internal link check (WF-DOC-002, BASE-DOC-006).

Every relative Markdown link in a tracked *.md file must point to a file or directory that exists.
External URLs (any scheme) and pure #anchors are not checked here; code spans and fenced code are skipped.
Usage: python3 scripts/check-links.py [--root DIR]
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

LINK = re.compile(r'(?<!\\)\]\(\s*(<[^>]+>|[^)\s]+)(?:\s+"[^"]*")?\s*\)')
REF = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*(\S+)", re.M)
SCHEME = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")


def targets(text):
    text = re.sub(r"^(```|~~~).*?^\1", "", text, flags=re.S | re.M)
    text = re.sub(r"`[^`\n]*`", "", text)
    for match in LINK.finditer(text):
        yield match.group(1).strip("<>")
    for match in REF.finditer(text):
        yield match.group(1).strip("<>")


def broken_links(root):
    files = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z", "--", "*.md"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split("\0")
    for rel in filter(None, files):
        path = root / rel
        if not path.is_file():
            continue
        for target in targets(path.read_text(encoding="utf-8", errors="replace")):
            if SCHEME.match(target) or target.startswith("#"):
                continue
            local = unquote(target.split("#", 1)[0].split("?", 1)[0])
            if not local:
                continue
            resolved = (
                root / local.lstrip("/")
                if local.startswith("/")
                else path.parent / local
            )
            if not resolved.exists():
                yield rel, target


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root", default=Path(__file__).resolve().parents[1], type=Path
    )
    root = parser.parse_args().root.resolve()
    broken = list(broken_links(root))
    for rel, target in broken:
        print(f"BROKEN: {rel} -> {target}")
    if broken:
        print(f"FAIL: {len(broken)} broken internal link(s)", file=sys.stderr)
        return 1
    print("PASS: internal Markdown links resolve (external URLs not checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
