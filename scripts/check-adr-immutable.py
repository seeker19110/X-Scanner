#!/usr/bin/env python3
"""Accepted ADRs are immutable (ARC-ADR-004).

Compares docs/adr/*.md between --base and --head. For an ADR whose base version is Accepted
("Status: Accepted" / "Trạng thái: Đã chấp nhận"), only the status line and supersede links may
change; any other edit, or deleting/renaming the file, fails. Decisions change through a new ADR.
Usage: python3 scripts/check-adr-immutable.py --base <ref> [--head <ref>]
"""

import argparse
import re
import subprocess
import sys

ACCEPTED = re.compile(r"(?:Status|Trạng thái)\W*\s*(?:Accepted|Đã chấp nhận)", re.I)
ALLOWED_LINE = re.compile(r"Status|Trạng thái|superseded by|thay thế bởi", re.I)


def git(*args):
    return subprocess.run(
        ["git", *args], capture_output=True, text=True, check=True
    ).stdout


def accepted(ref, path):
    head = "\n".join(git("show", f"{ref}:{path}").splitlines()[:20])
    return bool(ACCEPTED.search(head))


def violations(base, head):
    changed = git(
        "diff", "--name-status", "--no-renames", base, head, "--", "docs/adr/*.md"
    ).splitlines()
    for entry in changed:
        status, path = entry.split("\t", 1)
        if status == "A" or not accepted(base, path):
            continue
        if status == "D":
            yield f"{path}: accepted ADR deleted"
            continue
        diff = git("diff", "-U0", base, head, "--", path).splitlines()
        for line in diff:
            if (
                line[:1] in "+-"
                and not line.startswith(("+++", "---"))
                and line[1:].strip()
            ):
                if not ALLOWED_LINE.search(line):
                    yield f"{path}: accepted ADR content changed: {line[:120]}"
                    break


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", default="HEAD")
    args = parser.parse_args()
    found = list(violations(args.base, args.head))
    for item in found:
        print(f"FAIL: {item}")
    if found:
        print(
            'Write a new ADR and only change the old status line to "superseded by".',
            file=sys.stderr,
        )
        return 1
    print("PASS: no accepted ADR content changed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
