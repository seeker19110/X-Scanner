#!/usr/bin/env python3
"""Dependency license policy and SBOM (BASE-DEP-005, CMP-LIC-002, CMP-LIC-003, CMP-LIC-004).

Every dependency, direct and transitive, must have a known license in the allow-list of
docs/ops/license-policy.json, or an unexpired exception (package, reason, approved_by, expires).
- Pub packages (apps/mobile/pubspec.lock): the LICENSE text in the pub cache, classified by fixed
  phrases; SDK packages use the Flutter SDK LICENSE.
- Maven packages that ship in the release APK (releaseRuntimeClasspath in gradle.lockfile): the
  <licenses> of the POM (or its parent POM) in the Gradle cache, or a license_overrides entry.
Unknown, copyleft and source-available licenses fail unless an exception covers them.
--sbom writes a CycloneDX 1.6 JSON SBOM of the same components with their licenses.
Run after `flutter pub get` and a Gradle build (the gate's build step fills both caches).
"""

import argparse
import datetime as dt
import fnmatch
import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT_RULES = [  # (SPDX id, pattern) on LICENSE text; a file may match several
    (
        "Apache-2.0",
        r"Apache License,?\s+Version 2\.0|apache\.org/licenses/LICENSE-2\.0",
    ),
    ("MIT", r"Permission is hereby granted, free of charge"),
    (
        "BSD-3-Clause",
        r"Redistribution and use in source and binary forms(?=[\s\S]*(Neither the name|names of (its|the) contributors))",
    ),
    (
        "BSD-2-Clause",
        r"Redistribution and use in source and binary forms(?![\s\S]*(Neither the name|names of (its|the) contributors))",
    ),
    ("Zlib", r"provided ['‘]as-is['’], without any express or implied\s+warranty"),
    (
        "ISC",
        r"Permission to use, copy, modify, and/or distribute this software for any",
    ),
    ("AGPL-3.0", r"GNU AFFERO GENERAL PUBLIC LICENSE"),
    ("LGPL", r"GNU LESSER GENERAL PUBLIC LICENSE"),
    ("GPL", r"GNU GENERAL PUBLIC LICENSE"),
    ("MPL-2.0", r"Mozilla Public License"),
    ("BUSL-1.1", r"Business Source License"),
    ("SSPL-1.0", r"Server Side Public License"),
    ("Elastic-2.0", r"Elastic License"),
    ("Commons-Clause", r"Commons Clause"),
]
NAME_RULES = [  # (SPDX id, pattern) on a POM <license><name>/<url>
    ("Apache-2.0", r"Apache.*2\.0|Apache-2\.0|LICENSE-2\.0"),
    ("MIT", r"\bMIT\b"),
    ("BSD-3-Clause", r"BSD[- ]3|New BSD|Modified BSD"),
    ("BSD-2-Clause", r"BSD[- ]2|Simplified BSD"),
    ("EPL-1.0", r"Eclipse Public License.*1\.0|EPL-1\.0"),
    ("EPL-2.0", r"Eclipse Public License.*2\.0|EPL-2\.0"),
    ("LGPL", r"LGPL|Lesser General Public"),
    ("GPL", r"\bGPL\b|General Public License"),
]


def classify(text, rules):
    return sorted({spdx for spdx, pattern in rules if re.search(pattern, text, re.I)})


def pub_packages(lock_path):
    """(name, version, source) from pubspec.lock without a YAML dependency."""
    name = None
    for line in lock_path.read_text(encoding="utf-8").splitlines():
        if re.match(r"^  \w+:$", line):
            name, source = line.strip()[:-1], None
        elif name and (m := re.match(r"^    source: (\w+)", line)):
            source = m.group(1)
        elif name and (m := re.match(r'^    version: "([^"]+)"', line)):
            yield name, m.group(1), source
            name = None


def pub_licenses(name, version, source, pub_cache, flutter_root):
    if source == "sdk":
        files = [flutter_root / "LICENSE"]
    else:
        package_dir = pub_cache / "hosted" / "pub.dev" / f"{name}-{version}"
        files = sorted(package_dir.glob("LICENSE*")) + sorted(
            package_dir.glob("COPYING*")
        )
    text = "\n".join(
        f.read_text(encoding="utf-8", errors="replace") for f in files if f.is_file()
    )
    return classify(text, TEXT_RULES) if text else []


def maven_packages(gradle_lock):
    for line in gradle_lock.read_text(encoding="utf-8").splitlines():
        coords, _, configs = line.partition("=")
        if "releaseRuntimeClasspath" in configs.split(",") and coords.count(":") == 2:
            yield tuple(coords.split(":"))


def find_pom(cache, group, artifact, version):
    return next(
        iter(
            sorted(
                (cache / group / artifact / version).glob(f"*/{artifact}-{version}.pom")
            )
        ),
        None,
    )


def maven_licenses(group, artifact, version, cache, depth=0):
    pom = find_pom(cache, group, artifact, version)
    if pom is None or depth > 5:
        return []
    text = pom.read_text(encoding="utf-8", errors="replace")
    block = re.search(r"<licenses>(.*?)</licenses>", text, re.S)
    if block:
        return classify(block.group(1), NAME_RULES) or ["UNKNOWN"]
    parent = re.search(r"<parent>(.*?)</parent>", text, re.S)
    if parent:
        get = lambda tag: re.search(
            rf"<{tag}>\s*(.*?)\s*</{tag}>", parent.group(1)
        ).group(1)
        return maven_licenses(
            get("groupId"), get("artifactId"), get("version"), cache, depth + 1
        )
    return []


def evaluate(components, policy, today):
    allow = set(policy["allow"])
    exceptions = {e["package"]: e for e in policy.get("exceptions", [])}
    errors = []
    for comp in components:
        exc = exceptions.get(comp["key"])
        if exc and dt.date.fromisoformat(exc["expires"]) >= today:
            continue
        if exc:
            errors.append(f"{comp['key']}: exception expired on {exc['expires']}")
        elif not comp["licenses"]:
            errors.append(
                f"{comp['key']}: license unknown (no LICENSE/POM license found)"
            )
        elif not set(comp["licenses"]) <= allow:
            errors.append(
                f"{comp['key']}: {', '.join(comp['licenses'])} not in allow-list"
            )
    return errors


def sbom(components, app_version):
    return {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "version": 1,
        "metadata": {
            "component": {
                "type": "application",
                "name": "x_scanner",
                "version": app_version,
            }
        },
        "components": [
            {
                "type": "library",
                "name": c["name"],
                "version": c["version"],
                "purl": c["purl"],
                **({"group": c["group"]} if c.get("group") else {}),
                "licenses": [{"license": {"id": spdx}} for spdx in c["licenses"]]
                or [{"license": {"name": "NOASSERTION"}}],
            }
            for c in components
        ],
    }


def default_flutter_root():
    flutter = shutil.which("flutter")
    return (
        Path(os.path.realpath(flutter)).parents[1]
        if flutter
        else Path("flutter-sdk-not-found")
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", type=Path, default=ROOT / "apps/mobile/pubspec.lock")
    parser.add_argument(
        "--gradle-lock",
        default=str(ROOT / "apps/mobile/android/app/gradle.lockfile"),
        help="'' skips Maven packages",
    )
    parser.add_argument(
        "--policy", type=Path, default=ROOT / "docs/ops/license-policy.json"
    )
    parser.add_argument(
        "--pub-cache",
        type=Path,
        default=Path(os.environ.get("PUB_CACHE", Path.home() / ".pub-cache")),
    )
    parser.add_argument(
        "--gradle-cache",
        type=Path,
        default=Path(os.environ.get("GRADLE_USER_HOME", Path.home() / ".gradle"))
        / "caches/modules-2/files-2.1",
    )
    parser.add_argument("--flutter-root", type=Path, default=default_flutter_root())
    parser.add_argument("--sbom", type=Path)
    parser.add_argument("--today", type=dt.date.fromisoformat, default=dt.date.today())
    args = parser.parse_args()
    policy = json.loads(args.policy.read_text(encoding="utf-8"))
    overrides = policy.get("license_overrides", [])
    components = []
    for name, version, source in pub_packages(args.lock):
        components.append(
            {
                "key": name,
                "name": name,
                "version": version,
                "purl": f"pkg:pub/{name}@{version}",
                "licenses": pub_licenses(
                    name, version, source, args.pub_cache, args.flutter_root
                ),
            }
        )
    if args.gradle_lock:
        for group, artifact, version in maven_packages(Path(args.gradle_lock)):
            key = f"{group}:{artifact}"
            override = next(
                (o for o in overrides if fnmatch.fnmatch(key, o["package"])), None
            )
            licenses = (
                [override["license"]]
                if override
                else maven_licenses(group, artifact, version, args.gradle_cache)
            )
            components.append(
                {
                    "key": key,
                    "name": artifact,
                    "group": group,
                    "version": version,
                    "purl": f"pkg:maven/{group}/{artifact}@{version}",
                    "licenses": licenses,
                }
            )
    errors = evaluate(components, policy, args.today)
    if args.sbom:
        app_version = re.search(
            r"^version: *(\S+)", (ROOT / "apps/mobile/pubspec.yaml").read_text(), re.M
        ).group(1)
        args.sbom.write_text(
            json.dumps(sbom(components, app_version), indent=2) + "\n", encoding="utf-8"
        )
    for error in errors:
        print(f"FAIL: {error}")
    if errors:
        print(
            f"{len(errors)} license violation(s); policy: {args.policy}",
            file=sys.stderr,
        )
        return 1
    print(
        f"PASS: {len(components)} dependencies have allowed licenses ({args.policy.name})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
