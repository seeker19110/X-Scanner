#!/usr/bin/env python3
"""Tests for the repository check scripts added by Work ID 2026-10-24-backlog-ci.

Each check gets at least one fixture that must FAIL (exit 1) and one that must PASS, so a check
that silently stops checking turns this suite red. Run: python3 scripts/test-repo-checks.py
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PY = sys.executable


def run(*args, cwd=None, env=None):
    return subprocess.run(list(args), cwd=cwd, env=env, capture_output=True, text=True)


def script(name, *args, cwd=None, env=None):
    path = ROOT / "scripts" / name
    cmd = ["bash", str(path)] if name.endswith(".sh") else [PY, str(path)]
    return run(*cmd, *args, cwd=cwd, env=env)


def write(base, rel, text):
    path = Path(base) / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def git_repo(base):
    for cmd in (
        ["init", "-q"],
        ["config", "user.email", "t@example.invalid"],
        ["config", "user.name", "t"],
        ["config", "commit.gpgsign", "false"],
    ):
        run("git", "-C", str(base), *cmd)


def commit_all(base, msg="c"):
    run("git", "-C", str(base), "add", "-A")
    out = run(
        "git",
        "-C",
        str(base),
        "-c",
        "core.hooksPath=/dev/null",
        "commit",
        "-q",
        "-m",
        msg,
    )
    assert out.returncode == 0, out.stderr
    return run("git", "-C", str(base), "rev-parse", "HEAD").stdout.strip()


class Tmp(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()


class LinkCheck(Tmp):
    def test_broken_relative_link_fails_and_good_links_pass(self):
        git_repo(self.tmp)
        write(
            self.tmp,
            "docs/a.md",
            "[ok](b.md) [root](/README.md) [web](https://example.invalid/x) "
            "[anchor](#top) `[code](missing.md)`\n```\n[fenced](missing.md)\n```\n",
        )
        write(self.tmp, "docs/b.md", "[back](a.md#h) [space](<c d.md>)\n")
        write(self.tmp, "docs/c d.md", "x\n")
        write(self.tmp, "README.md", "[docs](docs/a.md)\n")
        run("git", "-C", str(self.tmp), "add", "-A")
        self.assertEqual(
            script("check-links.py", "--root", str(self.tmp)).returncode, 0
        )
        write(self.tmp, "docs/b.md", "[gone](nowhere.md)\n")
        out = script("check-links.py", "--root", str(self.tmp))
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        self.assertIn("docs/b.md", out.stdout + out.stderr)


class ArchitectureCheck(Tmp):
    def lib(self, files):
        for rel, text in files.items():
            write(self.tmp, f"lib/{rel}", text)
        return script("check-architecture.py", "--lib", str(self.tmp / "lib"))

    def test_documented_direction_passes(self):
        out = self.lib(
            {
                "core/a.dart": "",
                "imaging/i.dart": "import '../core/a.dart';\n",
                "export/e.dart": "import '../imaging/i.dart';\nimport '../core/a.dart';\n",
                "storage/s.dart": "import '../core/a.dart';\n",
                "ui/u.dart": "import '../export/e.dart';\nimport 'package:x_scanner/storage/s.dart';\n",
                "main.dart": "import 'ui/u.dart';\n",
            }
        )
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_reverse_edge_fails(self):
        out = self.lib(
            {
                "core/a.dart": "import '../ui/u.dart';\n",
                "ui/u.dart": "import '../core/a.dart';\n",
            }
        )
        self.assertEqual(out.returncode, 1)
        self.assertIn("core -> ui", out.stdout + out.stderr)
        self.assertIn("cycle", (out.stdout + out.stderr).lower())

    def test_deep_import_fails(self):
        out = self.lib(
            {
                "core/src/hidden.dart": "",
                "storage/s.dart": "import '../core/src/hidden.dart';\n",
            }
        )
        self.assertEqual(out.returncode, 1)
        self.assertIn("deep import", (out.stdout + out.stderr).lower())

    def test_unknown_module_fails(self):
        out = self.lib({"core/a.dart": "", "net/n.dart": "import '../core/a.dart';\n"})
        self.assertEqual(out.returncode, 1)

    def test_real_app_passes(self):
        out = script("check-architecture.py")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)


class AssertionCheck(Tmp):
    def test_test_without_expect_fails_helper_passes(self):
        write(
            self.tmp,
            "a_test.dart",
            """
void main() {
  Future<void> checked<T>(int v) async {
    await expectLater(Future.value(v), completion(1));
  }
  void expectOne(int v) => expect(v, 1);
  test('direct', () { expect(1, 1); });
  test('helper', () => checked(1));
  testWidgets('named helper', (tester) async { expectOne(1); });
  test('string with ) paren', () { final s = 'x)'; expect(s, isNotEmpty); });
}
""",
        )
        out = script("check-test-assertions.py", "--tests", str(self.tmp))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        write(
            self.tmp,
            "b_test.dart",
            "void main() {\n  test('no assertion', () { print(1); });\n}\n",
        )
        out = script("check-test-assertions.py", "--tests", str(self.tmp))
        self.assertEqual(out.returncode, 1)
        self.assertIn("no assertion", out.stdout + out.stderr)


LCOV = "SF:lib/a.dart\nDA:1,1\nDA:2,{hit}\nLF:2\nLH:{lh}\nBRDA:1,0,0,1\nBRDA:1,0,1,{br}\nBRF:2\nBRH:{brh}\nend_of_record\n"


class CoverageRatchet(Tmp):
    def lcov(self, hit):
        return write(
            self.tmp, "lcov.info", LCOV.format(hit=hit, lh=1 + hit, br=hit, brh=1 + hit)
        )

    def test_drop_fails_equal_passes_update_only_raises(self):
        base = write(
            self.tmp, "baseline.json", json.dumps({"lines": 100.0, "branches": 100.0})
        )
        lcov = self.lcov(0)
        out = script("check-coverage.py", "--lcov", str(lcov), "--baseline", str(base))
        self.assertEqual(out.returncode, 1, out.stdout)
        base.write_text(json.dumps({"lines": 50.0, "branches": 50.0}))
        self.assertEqual(
            script(
                "check-coverage.py", "--lcov", str(lcov), "--baseline", str(base)
            ).returncode,
            0,
        )
        self.lcov(1)
        self.assertEqual(
            script(
                "check-coverage.py",
                "--lcov",
                str(lcov),
                "--baseline",
                str(base),
                "--update",
            ).returncode,
            0,
        )
        self.assertEqual(json.loads(base.read_text())["lines"], 100.0)
        self.lcov(0)
        out = script(
            "check-coverage.py",
            "--lcov",
            str(lcov),
            "--baseline",
            str(base),
            "--update",
        )
        self.assertEqual(out.returncode, 1)
        self.assertEqual(json.loads(base.read_text())["lines"], 100.0)

    def test_missing_branch_data_fails(self):
        lcov = write(self.tmp, "lcov.info", "SF:a\nDA:1,1\nLF:1\nLH:1\nend_of_record\n")
        base = write(self.tmp, "baseline.json", json.dumps({"lines": 0, "branches": 0}))
        self.assertEqual(
            script(
                "check-coverage.py", "--lcov", str(lcov), "--baseline", str(base)
            ).returncode,
            1,
        )


ADR = "# ADR-0009: x\n\n- **Trạng thái:** {status}\n\n## Quyết định\n\n{body}\n"


class AdrImmutable(Tmp):
    def setUp(self):
        super().setUp()
        git_repo(self.tmp)
        write(
            self.tmp,
            "docs/adr/0009-x.md",
            ADR.format(status="Đã chấp nhận", body="Dùng A."),
        )
        write(
            self.tmp, "docs/adr/0010-y.md", ADR.format(status="Đề xuất", body="Dùng B.")
        )
        write(
            self.tmp,
            "docs/adr/0001-z.md",
            "Date: 2026-10-11. Status: Accepted.\n\nBody.\n",
        )
        self.base = commit_all(self.tmp, "base")

    def check(self):
        return script("check-adr-immutable.py", "--base", self.base, cwd=self.tmp)

    def test_status_change_and_proposed_edit_pass(self):
        write(
            self.tmp,
            "docs/adr/0009-x.md",
            ADR.format(status="Đã thay thế bởi ADR-0012", body="Dùng A."),
        )
        write(
            self.tmp, "docs/adr/0010-y.md", ADR.format(status="Đề xuất", body="Dùng C.")
        )
        commit_all(self.tmp)
        out = self.check()
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_body_edit_of_accepted_fails(self):
        write(
            self.tmp,
            "docs/adr/0009-x.md",
            ADR.format(status="Đã chấp nhận", body="Dùng Z."),
        )
        commit_all(self.tmp)
        out = self.check()
        self.assertEqual(out.returncode, 1)
        self.assertIn("0009-x.md", out.stdout + out.stderr)

    def test_english_accepted_and_deletion_fail(self):
        write(
            self.tmp,
            "docs/adr/0001-z.md",
            "Date: 2026-10-11. Status: Accepted.\n\nOther.\n",
        )
        commit_all(self.tmp)
        self.assertEqual(self.check().returncode, 1)
        run("git", "-C", str(self.tmp), "reset", "-q", "--hard", self.base)
        (self.tmp / "docs/adr/0009-x.md").unlink()
        commit_all(self.tmp)
        self.assertEqual(self.check().returncode, 1)


BODY = "## Summary\n\nx\n\n- Work ID: {wid}\n\n## Validation\n\ny\n\n## Risk, rollout and rollback\n\nz\n"


class PrPolicy(Tmp):
    def setUp(self):
        super().setUp()
        write(self.tmp, "docs/work/2026-10-24-x/working.md", "w\n")

    def pr(
        self,
        title,
        body=BODY.format(wid="2026-10-24-x"),
        files=("lib/a.dart",),
        author="someone",
    ):
        body_file = write(self.tmp, "body.md", body)
        files_file = write(self.tmp, "files.txt", "\n".join(files) + "\n")
        return script(
            "check-pr-policy.py",
            "--root",
            str(self.tmp),
            "--title",
            title,
            "--body-file",
            str(body_file),
            "--changed-files",
            str(files_file),
            "--author",
            author,
        )

    def test_good_pr_passes(self):
        out = self.pr("ci(gate): add repository checks")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_bad_title_fails(self):
        self.assertEqual(self.pr("Add checks").returncode, 1)
        self.assertEqual(self.pr("feat: " + "x" * 80).returncode, 1)

    def test_body_needs_sections_and_existing_work_id(self):
        self.assertEqual(self.pr("docs: x", body="## Summary\n").returncode, 1)
        self.assertEqual(
            self.pr("docs: x", body=BODY.format(wid="2026-10-24-missing")).returncode, 1
        )
        self.assertEqual(
            self.pr(
                "chore(deps): bump x", body="Bumps x.", author="dependabot[bot]"
            ).returncode,
            0,
        )

    def test_fix_needs_test_change(self):
        self.assertEqual(self.pr("fix(storage): keep originals").returncode, 1)
        out = self.pr(
            "fix(storage): keep originals",
            files=("lib/a.dart", "apps/mobile/test/a_test.dart"),
        )
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_commit_msg_mode(self):
        good = write(self.tmp, "msg", "# comment\nci: add check\n\nbody\n")
        bad = write(self.tmp, "msg2", "added stuff\n")
        merge = write(self.tmp, "msg3", "Merge branch 'main' into x\n")
        self.assertEqual(
            script("check-pr-policy.py", "--commit-msg-file", str(good)).returncode, 0
        )
        self.assertEqual(
            script("check-pr-policy.py", "--commit-msg-file", str(bad)).returncode, 1
        )
        self.assertEqual(
            script("check-pr-policy.py", "--commit-msg-file", str(merge)).returncode, 0
        )


class ApkSize(Tmp):
    def test_over_budget_fails(self):
        apk = write(self.tmp, "a.apk", "x" * 100)
        budget = write(self.tmp, "b.json", json.dumps({"max_bytes": 150}))
        self.assertEqual(
            script(
                "check-apk-size.py", "--apk", str(apk), "--budget", str(budget)
            ).returncode,
            0,
        )
        budget.write_text(json.dumps({"max_bytes": 99}))
        self.assertEqual(
            script(
                "check-apk-size.py", "--apk", str(apk), "--budget", str(budget)
            ).returncode,
            1,
        )
        self.assertEqual(
            script(
                "check-apk-size.py",
                "--apk",
                str(self.tmp / "none.apk"),
                "--budget",
                str(budget),
            ).returncode,
            1,
        )


class EolCheck(Tmp):
    def data(self, temurin_eol, flutter_minor_date):
        d = self.tmp / "data"
        write(
            d, "eclipse-temurin.json", json.dumps([{"cycle": "21", "eol": temurin_eol}])
        )
        write(d, "gradle.json", json.dumps([{"cycle": "9", "eol": False}]))
        write(d, "kotlin.json", json.dumps([{"cycle": "2.4", "eol": False}]))
        write(
            d,
            "flutter-releases.json",
            json.dumps(
                {
                    "releases": [
                        {
                            "channel": "stable",
                            "version": "3.49.0",
                            "release_date": flutter_minor_date + "T00:00:00Z",
                        },
                        {
                            "channel": "stable",
                            "version": "3.47.7",
                            "release_date": "2026-10-08T00:00:00Z",
                        },
                        {
                            "channel": "beta",
                            "version": "3.50.0-0.1.pre",
                            "release_date": "2020-01-01T00:00:00Z",
                        },
                    ]
                }
            ),
        )
        return d

    def eol(self, d):
        return script("eol-check.py", "--data", str(d), "--today", "2026-10-24")

    def test_supported_passes_with_warning(self):
        out = self.eol(self.data("2029-12-31", "2026-10-20"))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("WARN", out.stdout)

    def test_eol_runtime_fails(self):
        self.assertEqual(self.eol(self.data("2026-10-01", "2026-10-20")).returncode, 1)

    def test_eol_within_90_days_fails_within_180_warns(self):
        self.assertEqual(self.eol(self.data("2026-12-31", "2026-10-20")).returncode, 1)
        out = self.eol(self.data("2027-03-01", "2026-10-20"))
        self.assertEqual(out.returncode, 0, out.stdout)
        self.assertIn("WARN: eclipse-temurin", out.stdout)

    def test_superseded_flutter_minor_fails(self):
        self.assertEqual(self.eol(self.data("2029-12-31", "2026-06-01")).returncode, 1)


class LicenseCheck(Tmp):
    MIT = "Permission is hereby granted, free of charge, to any person obtaining a copy"
    GPL = "GNU GENERAL PUBLIC LICENSE Version 3"

    def setUp(self):
        super().setUp()
        self.cache = self.tmp / "pub-cache"
        self.flutter = self.tmp / "flutter"
        write(
            self.flutter,
            "LICENSE",
            "Redistribution and use in source and binary forms ... Neither the name",
        )
        write(self.cache, "hosted/pub.dev/good-1.0.0/LICENSE", self.MIT)
        write(self.cache, "hosted/pub.dev/bad-2.0.0/LICENSE", self.GPL)
        self.policy = write(
            self.tmp,
            "policy.json",
            json.dumps({"allow": ["MIT", "BSD-3-Clause"], "exceptions": []}),
        )

    def lock(self, *pkgs):
        text = "packages:\n"
        for name, source, version in pkgs:
            text += (
                f"  {name}:\n    dependency: transitive\n    description:\n      name: {name}\n"
                f'    source: {source}\n    version: "{version}"\n'
            )
        return write(self.tmp, "pubspec.lock", text + 'sdks:\n  dart: ">=3.0.0"\n')

    def check(self, lock, *extra):
        return script(
            "check-licenses.py",
            "--lock",
            str(lock),
            "--policy",
            str(self.policy),
            "--pub-cache",
            str(self.cache),
            "--flutter-root",
            str(self.flutter),
            "--gradle-lock",
            "",
            *extra,
        )

    def test_allowed_passes_and_writes_sbom(self):
        lock = self.lock(("good", "hosted", "1.0.0"), ("flutter", "sdk", "0.0.0"))
        sbom = self.tmp / "sbom.cdx.json"
        out = self.check(lock, "--sbom", str(sbom))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        doc = json.loads(sbom.read_text())
        self.assertEqual(doc["bomFormat"], "CycloneDX")
        comps = {c["name"]: c for c in doc["components"]}
        self.assertEqual(comps["good"]["purl"], "pkg:pub/good@1.0.0")
        self.assertEqual(comps["good"]["licenses"][0]["license"]["id"], "MIT")

    def test_denied_and_unknown_fail(self):
        self.assertEqual(
            self.check(self.lock(("bad", "hosted", "2.0.0"))).returncode, 1
        )
        self.assertEqual(
            self.check(self.lock(("missing", "hosted", "9.9.9"))).returncode, 1
        )

    def test_exception_must_not_be_expired(self):
        lock = self.lock(("bad", "hosted", "2.0.0"))
        exc = {
            "package": "bad",
            "reason": "test",
            "approved_by": "owner",
            "expires": "2999-01-01",
        }
        self.policy.write_text(json.dumps({"allow": ["MIT"], "exceptions": [exc]}))
        self.assertEqual(self.check(lock).returncode, 0)
        exc["expires"] = "2000-01-01"
        self.policy.write_text(json.dumps({"allow": ["MIT"], "exceptions": [exc]}))
        self.assertEqual(self.check(lock).returncode, 1)

    def test_maven_runtime_licenses_from_pom_or_parent(self):
        cache = self.tmp / "m2"
        lic = "<licenses><license><name>{}</name></license></licenses>"
        write(
            cache,
            "g/parent/1/h/parent-1.pom",
            "<project>" + lic.format("MIT License") + "</project>",
        )
        write(
            cache,
            "g/child/1/h/child-1.pom",
            "<project><parent><groupId>g</groupId><artifactId>parent</artifactId>"
            "<version>1</version></parent></project>",
        )
        write(
            cache,
            "g/gpl/1/h/gpl-1.pom",
            "<project>" + lic.format("GNU General Public License") + "</project>",
        )
        gradle = write(
            self.tmp,
            "gradle.lockfile",
            "g:child:1=releaseRuntimeClasspath\ng:gpl:1=debugUnitTestRuntimeClasspath\n",
        )
        lock = self.lock(("good", "hosted", "1.0.0"))
        args = [
            "--lock",
            str(lock),
            "--policy",
            str(self.policy),
            "--pub-cache",
            str(self.cache),
            "--flutter-root",
            str(self.flutter),
            "--gradle-cache",
            str(cache),
            "--gradle-lock",
            str(gradle),
        ]
        out = script("check-licenses.py", *args)
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        gradle.write_text(
            "g:gpl:1=releaseRuntimeClasspath\ng:none:1=releaseRuntimeClasspath\n"
        )
        out = script("check-licenses.py", *args)
        self.assertEqual(out.returncode, 1)
        self.assertIn("g:gpl", out.stdout)
        self.assertIn("g:none", out.stdout)


class TreeGuard(Tmp):
    def test_secret_and_large_file_fail(self):
        git_repo(self.tmp)
        write(self.tmp, "ok.txt", "hello\n")
        commit_all(self.tmp)
        self.assertEqual(script("check-repo-tree.sh", cwd=self.tmp).returncode, 0)
        write(
            self.tmp, "conf.txt", "k=AKIA" + "ABCDEFGHIJKLMNOP" + "\n"
        )  # built at runtime, not a literal key
        run("git", "-C", str(self.tmp), "add", "-A")
        self.assertEqual(script("check-repo-tree.sh", cwd=self.tmp).returncode, 1)
        run("git", "-C", str(self.tmp), "rm", "-q", "--cached", "conf.txt")
        write(self.tmp, "big.bin", "x" * (1024 * 1024 + 1))
        run("git", "-C", str(self.tmp), "add", "-A")
        self.assertEqual(script("check-repo-tree.sh", cwd=self.tmp).returncode, 1)


class RepoConfig(unittest.TestCase):
    """Configuration invariants that an edit could silently undo."""

    def workflows(self):
        return sorted((ROOT / ".github/workflows").glob("*.yml"))

    def test_every_action_pinned_by_sha_with_version_comment(self):
        for wf in self.workflows():
            for line in wf.read_text().splitlines():
                if re.match(r"\s*-?\s*uses:", line) and not line.split("uses:", 1)[
                    1
                ].strip().startswith("./"):
                    with self.subTest(workflow=wf.name, line=line.strip()):
                        self.assertRegex(
                            line, r"uses: [\w.-]+/[\w./-]+@[0-9a-f]{40} # v\d+(\.\d+)*$"
                        )

    def test_flutter_version_single_source(self):
        ci = (ROOT / ".github/workflows/ci.yml").read_text()
        self.assertNotRegex(ci, r'FLUTTER_VERSION:\s*[\d"\']')
        self.assertIn("scripts/flutter-version.sh", ci)
        out = script("flutter-version.sh")
        self.assertEqual(out.returncode, 0, out.stderr)
        pubspec = (ROOT / "apps/mobile/pubspec.yaml").read_text()
        self.assertIn(f"flutter: {out.stdout.strip()}", pubspec)

    def test_dependabot_covers_every_ecosystem(self):
        text = (ROOT / ".github/dependabot.yml").read_text()
        for eco in ("pub", "github-actions", "gradle"):
            with self.subTest(ecosystem=eco):
                self.assertIn(f"package-ecosystem: {eco}", text)
        self.assertEqual(
            text.count("package-ecosystem:"), text.count("open-pull-requests-limit:")
        )


if __name__ == "__main__":
    os.environ.setdefault("GIT_CONFIG_NOSYSTEM", "1")
    unittest.main(verbosity=1)
