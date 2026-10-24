#!/usr/bin/env python3
"""PR and commit message policy (BASE-REPO-005, STD-PROC-004, WF-REVIEW-002, QA-STRAT-005, FE-TEST-006).

PR mode: title is a Conventional Commit subject (<= 72 chars); body has the template sections
Summary/Validation/Risk and a `Work ID:` naming docs/work/<id>/ (bot authors are exempt from the body
rule); a `fix` PR changes at least one test file; a PR by a person that changes a dependency manifest has a
"## Dependencies" section saying how new dependencies were vetted (BASE-DEP-006); every commit subject in
--commits is conventional.
Commit-msg mode (git hook): the first non-comment line is a Conventional Commit subject.
Usage: check-pr-policy.py --title T --body-file F --changed-files F [--commits F] [--author A] [--root DIR]
       check-pr-policy.py --commit-msg-file F
"""

import argparse
import re
import sys
from pathlib import Path

TYPES = "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
SUBJECT = re.compile(rf"^(?:{TYPES})(?:\([\w./,-]+\))?!?: \S")
EXEMPT_SUBJECT = re.compile(r'^(?:Merge |Revert "|fixup! |squash! )')
SECTIONS = ("## Summary", "## Validation", "## Risk")
WORK_ID = re.compile(r"Work ID:\s*`?(\d{4}-\d{2}-\d{2}-[a-z0-9][a-z0-9-]*)")
TEST_FILE = re.compile(
    r"(^|/)(test|tests)/|_test\.(dart|kt|py)$|(^|/)src/test/|(^|/)scripts/test-"
)
BOTS = ("dependabot[bot]", "github-actions[bot]")
MANIFEST = re.compile(r"(^|/)(pubspec\.yaml|build\.gradle(\.kts)?|settings\.gradle(\.kts)?)$")


def subject_errors(subject, label, max_len=72):
    if EXEMPT_SUBJECT.match(subject):
        return []
    errors = []
    if not SUBJECT.match(subject):
        errors.append(
            f'{label} is not a Conventional Commit subject ({TYPES}): "{subject}"'
        )
    length = len(re.sub(r" \(#\d+\)$", "", subject))  # GitHub appends " (#N)" on squash
    if length > max_len:
        errors.append(f'{label} is {length} chars (max {max_len}): "{subject}"')
    return errors


def pr_errors(args):
    title = args.title.strip()
    max_len = 200 if args.author in BOTS else 72  # bot titles name long dependency paths
    errors = subject_errors(title, "PR title", max_len)
    body = args.body_file.read_text(encoding="utf-8") if args.body_file else ""
    if args.author not in BOTS:
        errors += [f'PR body misses section "{s}"' for s in SECTIONS if s not in body]
        match = WORK_ID.search(body)
        if not match:
            errors.append('PR body misses "Work ID: YYYY-MM-DD-slug"')
        elif not any(
            (args.root / "docs/work" / match.group(1) / f).is_file()
            for f in ("working.md", "done.md")
        ):
            errors.append(
                f"Work ID {match.group(1)}: docs/work/{match.group(1)}/working.md or done.md not found"
            )
    files = (
        args.changed_files.read_text(encoding="utf-8").split()
        if args.changed_files
        else []
    )
    if re.match(r"^fix(\(|!|:)", title) and not any(TEST_FILE.search(f) for f in files):
        errors.append(
            "fix PR changes no test file (add the red-first regression test, CLAUDE.md §3.6)"
        )
    if (
        args.author not in BOTS
        and any(MANIFEST.search(f) for f in files)
        and "## Dependencies" not in body
    ):
        errors.append(
            'PR changes a dependency manifest but has no "## Dependencies" section (BASE-DEP-006)'
        )
    if args.commits:
        for subject in args.commits.read_text(encoding="utf-8").splitlines():
            errors += (
                subject_errors(subject.strip(), "commit", max_len) if subject.strip() else []
            )
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--commit-msg-file", type=Path)
    parser.add_argument("--title", default="")
    parser.add_argument("--body-file", type=Path)
    parser.add_argument("--changed-files", type=Path)
    parser.add_argument("--commits", type=Path)
    parser.add_argument("--author", default="")
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    args = parser.parse_args()
    if args.commit_msg_file:
        lines = [
            l
            for l in args.commit_msg_file.read_text(encoding="utf-8").splitlines()
            if not l.startswith("#")
        ]
        errors = subject_errors(
            next((l for l in lines if l.strip()), ""), "commit subject"
        )
    else:
        errors = pr_errors(args)
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    if errors:
        return 1
    print(
        "PASS: conventional subject"
        + ("" if args.commit_msg_file else ", PR body and fix/test policy")
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
