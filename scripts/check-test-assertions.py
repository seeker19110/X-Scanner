#!/usr/bin/env python3
"""Every Dart test must assert something (QA-COV-004).

A test()/testWidgets() body passes when it calls expect*/fail, or a helper defined in the same file
whose body does (helpers may call helpers). Tests whose only assertion is implicit are listed in
EXEMPT with the reason. Usage: python3 scripts/check-test-assertions.py [--tests DIR]
"""

import argparse
import re
import sys
from pathlib import Path

TEST = re.compile(r"(?<![\w.])(?:test|testWidgets)\s*\(")
DEF = re.compile(r"(?<![\w.])(\w+)\s*(?:<[^<>()]*>)?\s*\(")
BASE_ASSERT = r"expect\w*|fail"
EXEMPT = {
    # The controller throws on notify after dispose; `await started` rethrows it, failing the test.
    ("ui/library_controller_test.dart", "a disposed controller does not notify"),
}


def skip_literal(src, i):
    """Index just after the string literal or comment starting at i, or i when there is none."""
    if src.startswith("//", i):
        end = src.find("\n", i)
        return len(src) if end < 0 else end
    if src.startswith("/*", i):
        end = src.find("*/", i + 2)
        return len(src) if end < 0 else end + 2
    if src[i] not in "'\"":
        return i
    quote = src[i] * 3 if src.startswith(src[i] * 3, i) else src[i]
    j = i + len(quote)
    raw = i > 0 and src[i - 1] == "r"
    while j < len(src) and not src.startswith(quote, j):
        j += 1 if raw or src[j] != "\\" else 2
    return j + len(quote)


def balanced(src, i):
    """Text from the bracket at i to its matching closer."""
    pairs = {"(": ")", "{": "}"}
    stack, j = [], i
    while j < len(src):
        nxt = skip_literal(src, j)
        if nxt != j:
            j = nxt
            continue
        if src[j] in pairs:
            stack.append(pairs[src[j]])
        elif stack and src[j] == stack[-1]:
            stack.pop()
            if not stack:
                return src[i : j + 1]
        j += 1
    return src[i:]


def helper_bodies(src):
    """name -> text of each function declared in the file (params plus block or arrow body)."""
    bodies = {}
    for match in DEF.finditer(src):
        params = balanced(src, match.end() - 1)
        after = match.end() - 1 + len(params)
        rest = src[after : after + 40]
        head = re.match(r"\s*(?:async\*?|sync\*)?\s*(\{|=>)", rest)
        if not head:
            continue
        start = after + head.start(1)
        body = (
            balanced(src, start)
            if head.group(1) == "{"
            else src[start : src.find(";", start) + 1]
        )
        bodies.setdefault(match.group(1), "")
        bodies[match.group(1)] += params + body
    return bodies


def assertion_pattern(src):
    names, bodies = set(), helper_bodies(src)
    while True:
        pattern = re.compile(
            r"(?<![\w.])(?:"
            + "|".join([BASE_ASSERT, *map(re.escape, sorted(names))])
            + r")\s*[<(]"
        )
        grown = {name for name, body in bodies.items() if pattern.search(body)} - {
            "test",
            "testWidgets",
        }
        if grown <= names:
            return pattern
        names |= grown


def unasserted(tests_dir):
    for path in sorted(tests_dir.rglob("*_test.dart")):
        src = path.read_text(encoding="utf-8")
        rel = path.relative_to(tests_dir).as_posix()
        pattern = assertion_pattern(src)
        for match in TEST.finditer(src):
            call = balanced(src, match.end() - 1)
            name = re.match(r'\(\s*(?:r?([\'"])(.*?)\1)?', call, re.S).group(2) or "?"
            if not pattern.search(call) and (rel, name) not in EXEMPT:
                yield rel, src.count("\n", 0, match.start()) + 1, name


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--tests",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "apps/mobile/test",
    )
    found = list(unasserted(parser.parse_args().tests))
    for rel, line, name in found:
        print(f'FAIL: {rel}:{line} test "{name}" has no expect/fail call')
    if found:
        return 1
    print("PASS: every Dart test calls expect/fail directly or through a local helper")
    return 0


if __name__ == "__main__":
    sys.exit(main())
