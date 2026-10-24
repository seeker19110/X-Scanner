#!/usr/bin/env python3
"""Toolchain end-of-life check (OPS-MAINT-003, BASE-DEP-003), run weekly by supply-chain.yml.

Versions come from the repository: .java-version (JDK), gradle-wrapper.properties (Gradle),
settings.gradle.kts (Kotlin Gradle plugin) and apps/mobile/pubspec.yaml (Flutter, which bundles Dart).
- JDK (eclipse-temurin), Gradle, Kotlin: endoflife.date API. FAIL when the cycle is EOL or EOL is less
  than 90 days away (BASE-DEP-003), WARN when it is less than 180 days away.
- Flutter has no endoflife.date entry; the official release list is used. Flutter fixes only the
  latest stable, so: WARN when any newer stable exists, FAIL when a newer minor line has been stable
  for more than 90 days.
- Android Gradle Plugin has no machine-readable EOL source; Dependabot (gradle) tracks it.
Usage: python3 scripts/eol-check.py [--data DIR (offline JSON fixtures)] [--today YYYY-MM-DD]
"""

import argparse
import datetime as dt
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EOL_API = "https://endoflife.date/api/{}.json"
FLUTTER_RELEASES = (
    "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
)
FAIL_DAYS, WARN_DAYS, FLUTTER_GRACE_DAYS = 90, 180, 90


def pinned():
    android = ROOT / "apps/mobile/android"
    wrapper = (android / "gradle/wrapper/gradle-wrapper.properties").read_text()
    settings = (android / "settings.gradle.kts").read_text()
    return {
        "eclipse-temurin": (ROOT / ".java-version").read_text().strip(),
        "gradle": re.search(r"gradle-([\d.]+)-(?:all|bin)\.zip", wrapper).group(1),
        "kotlin": re.search(
            r'id\("org\.jetbrains\.kotlin\.android"\) version "([\d.]+)"', settings
        ).group(1),
        "flutter": re.search(
            r"^  flutter: *([\d.]+)",
            (ROOT / "apps/mobile/pubspec.yaml").read_text(),
            re.M,
        ).group(1),
    }


def load(data_dir, name, url):
    if data_dir:
        return json.loads((data_dir / name).read_text(encoding="utf-8"))
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def cycle_of(product, version):
    parts = re.split(r"[.+]", version)
    return parts[0] if product in ("eclipse-temurin", "gradle") else ".".join(parts[:2])


def check_eol_product(product, version, data, today):
    cycle = cycle_of(product, version)
    entry = next((e for e in data if str(e.get("cycle")) == cycle), None)
    if entry is None:
        return "FAIL", f"{product} {version}: cycle {cycle} not found on endoflife.date"
    eol = entry.get("eol")
    if eol is True:
        return "FAIL", f"{product} {version}: cycle {cycle} is end-of-life"
    if not eol:
        return "OK", f"{product} {version}: cycle {cycle} supported, no EOL date"
    days = (dt.date.fromisoformat(eol) - today).days
    if days < FAIL_DAYS:
        return "FAIL", f"{product} {version}: cycle {cycle} EOL on {eol} ({days} days, minimum {FAIL_DAYS})"
    if days < WARN_DAYS:
        return "WARN", f"{product} {version}: cycle {cycle} EOL on {eol} ({days} days)"
    return "OK", f"{product} {version}: cycle {cycle} supported until {eol}"


def check_flutter(version, releases, today):
    key = lambda v: tuple(int(x) for x in v.split("."))
    stable = [
        r
        for r in releases["releases"]
        if r.get("channel") == "stable" and re.fullmatch(r"[\d.]+", r["version"])
    ]
    newer = [r for r in stable if key(r["version"]) > key(version)]
    if not newer:
        return "OK", f"flutter {version}: latest stable"
    minor = key(version)[:2]
    newer_lines = [r for r in newer if key(r["version"])[:2] > minor]
    if newer_lines:
        first = min(dt.date.fromisoformat(r["release_date"][:10]) for r in newer_lines)
        if (today - first).days > FLUTTER_GRACE_DAYS:
            return (
                "FAIL",
                f"flutter {version}: a newer minor line has been stable since {first}; upgrade",
            )
    latest = max(newer, key=lambda r: key(r["version"]))["version"]
    return (
        "WARN",
        f"flutter {version}: newer stable {latest} exists (only the latest stable gets fixes)",
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path)
    parser.add_argument("--today", type=dt.date.fromisoformat, default=dt.date.today())
    args = parser.parse_args()
    results = []
    for product, version in pinned().items():
        try:
            if product == "flutter":
                results.append(
                    check_flutter(
                        version,
                        load(args.data, "flutter-releases.json", FLUTTER_RELEASES),
                        args.today,
                    )
                )
            else:
                data = load(args.data, f"{product}.json", EOL_API.format(product))
                results.append(check_eol_product(product, version, data, args.today))
        except (OSError, ValueError, KeyError) as error:
            results.append(
                ("FAIL", f"{product} {version}: cannot read lifecycle data: {error}")
            )
    for level, message in results:
        print(f"{level}: {message}")
    return 1 if any(level == "FAIL" for level, _ in results) else 0


if __name__ == "__main__":
    sys.exit(main())
