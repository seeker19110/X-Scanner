#!/usr/bin/env python3
"""Module dependency rules for apps/mobile/lib (ARC-MOD-004, ARC-MOD-005).

Direction documented in CODEMAP.md: ui -> export, storage, imaging, core (and app theme);
export -> imaging, core; imaging -> core; storage -> core; core and app import no other module.
Files directly in lib/ (main.dart) compose everything and are not restricted.
Fails on: an edge outside that direction, a module cycle, an unknown module, or a deep import
(a cross-module import must target a top-level file of the module, never a nested path such as src/).
Usage: python3 scripts/check-architecture.py [--lib DIR]
"""

import argparse
import re
import sys
from pathlib import Path, PurePosixPath

ALLOWED = {
    "core": set(),
    "app": set(),
    "imaging": {"core"},
    "storage": {"core"},
    "export": {"imaging", "core"},
    "ui": {"export", "storage", "imaging", "core", "app"},
}
PACKAGE = "x_scanner"
DIRECTIVE = re.compile(r"^\s*(?:import|export|part)\s+'([^']+)'", re.M)


def module_of(rel):
    parts = PurePosixPath(rel).parts
    return parts[0] if len(parts) > 1 else None


def resolve(source_rel, uri):
    if uri.startswith(f"package:{PACKAGE}/"):
        return uri[len(f"package:{PACKAGE}/") :]
    if ":" in uri:
        return None  # dart:, package:other
    parts = []
    for part in (PurePosixPath(source_rel).parent / uri).parts:
        if part == "..":
            if not parts:
                return None
            parts.pop()
        elif part != ".":
            parts.append(part)
    return "/".join(parts)


def find_cycle(graph):
    state = {}

    def visit(node, path):
        state[node] = 1
        for nxt in sorted(graph.get(node, ())):
            if state.get(nxt) == 1:
                return path[path.index(nxt) :] + [nxt]
            if nxt not in state:
                found = visit(nxt, path + [nxt])
                if found:
                    return found
        state[node] = 2
        return None

    for node in sorted(graph):
        if node not in state:
            found = visit(node, [node])
            if found:
                return found
    return None


def check(lib):
    errors, graph = [], {}
    for path in sorted(lib.rglob("*.dart")):
        rel = path.relative_to(lib).as_posix()
        source = module_of(rel)
        if source and source not in ALLOWED:
            errors.append(
                f'{rel}: unknown module "{source}" (add it to CODEMAP direction and ALLOWED)'
            )
        for uri in DIRECTIVE.findall(path.read_text(encoding="utf-8")):
            target_rel = resolve(rel, uri)
            target = module_of(target_rel) if target_rel else None
            if not source or not target or target == source:
                continue
            graph.setdefault(source, set()).add(target)
            if target not in ALLOWED.get(source, set()):
                errors.append(
                    f"{rel}: {source} -> {target} is against the documented direction ({uri})"
                )
            if len(PurePosixPath(target_rel).parts) != 2:
                errors.append(
                    f"{rel}: deep import into {target}: {uri} (import a top-level file of the module)"
                )
    cycle = find_cycle(graph)
    if cycle:
        errors.append("module cycle: " + " -> ".join(cycle))
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--lib",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "apps/mobile/lib",
    )
    errors = check(parser.parse_args().lib)
    for error in errors:
        print(f"FAIL: {error}")
    if errors:
        return 1
    print("PASS: lib modules follow CODEMAP direction; no cycles or deep imports")
    return 0


if __name__ == "__main__":
    sys.exit(main())
