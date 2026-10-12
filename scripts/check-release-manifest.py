#!/usr/bin/env python3
"""Fail the gate when the merged release AndroidManifest.xml widens the app's attack surface.

Usage: check-release-manifest.py PATH | --self-test
Checks (F-008): only allowed permissions, only allowed exported components, allowBackup="false".
"""

import argparse
import sys
import unittest
import xml.etree.ElementTree as ET

ANDROID = "{http://schemas.android.com/apk/res/android}"
PERMISSION_TAGS = ("uses-permission", "uses-permission-sdk-23")
COMPONENT_TAGS = ("activity", "activity-alias", "service", "receiver", "provider")
ALLOWED_PERMISSIONS = frozenset(
    {"org.xscanner.x_scanner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"}
)
# Exported component name -> android:permission it must carry (None: no requirement).
ALLOWED_EXPORTED = {
    "org.xscanner.x_scanner.MainActivity": None,
    "androidx.profileinstaller.ProfileInstallReceiver": "android.permission.DUMP",
}


def violations(root):
    """Return a list of human-readable violations for a parsed <manifest> element."""
    found = []
    for tag in PERMISSION_TAGS:
        for element in root.iter(tag):
            name = element.get(ANDROID + "name", "<unnamed>")
            if name not in ALLOWED_PERMISSIONS:
                found.append(f"{tag} not allowed: {name}")
    for tag in COMPONENT_TAGS:
        for element in root.iter(tag):
            if element.get(ANDROID + "exported") != "true":
                continue
            name = element.get(ANDROID + "name", "<unnamed>")
            if name not in ALLOWED_EXPORTED:
                found.append(f"exported {tag} not allowed: {name}")
                continue
            required = ALLOWED_EXPORTED[name]
            if required is not None and element.get(ANDROID + "permission") != required:
                found.append(
                    f'exported {tag} {name} must require android:permission="{required}"'
                )
    application = root.find("application")
    if application is None or application.get(ANDROID + "allowBackup") != "false":
        found.append('application must set android:allowBackup="false"')
    return found


def check(path):
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as error:
        print(f"FAIL: cannot read merged release manifest ({type(error).__name__})")
        return 1
    if root.tag != "manifest":
        print("FAIL: root element is not <manifest>")
        return 1
    found = violations(root)
    if found:
        for item in found:
            print(f"FAIL: {item}")
        return 1
    print(
        'PASS: release manifest has only allowed permissions/exported components and allowBackup="false".'
    )
    return 0


CLEAN = """<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="org.xscanner.x_scanner">
  <uses-permission android:name="org.xscanner.x_scanner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"/>
  <application android:allowBackup="false">
    <activity android:name="org.xscanner.x_scanner.MainActivity" android:exported="true"/>
    <provider android:name="dev.example.FileProvider" android:exported="false"/>
    <receiver android:name="androidx.profileinstaller.ProfileInstallReceiver" android:exported="true"
        android:permission="android.permission.DUMP"/>
  </application>
</manifest>"""


class ReleaseManifestTests(unittest.TestCase):
    def run_on(self, text):
        return violations(ET.fromstring(text))

    def test_clean_manifest_passes(self):
        self.assertEqual(self.run_on(CLEAN), [])

    def test_internet_permission_fails(self):
        text = CLEAN.replace(
            "<application",
            '<uses-permission android:name="android.permission.INTERNET"/>\n  <application',
        )
        self.assertEqual(
            self.run_on(text),
            ["uses-permission not allowed: android.permission.INTERNET"],
        )

    def test_sdk23_permission_fails(self):
        text = CLEAN.replace(
            "<application",
            '<uses-permission-sdk-23 android:name="android.permission.CAMERA"/>\n  <application',
        )
        self.assertEqual(len(self.run_on(text)), 1)

    def test_exported_provider_fails(self):
        text = CLEAN.replace(
            'android:name="dev.example.FileProvider" android:exported="false"',
            'android:name="dev.example.FileProvider" android:exported="true"',
        )
        self.assertEqual(
            self.run_on(text),
            ["exported provider not allowed: dev.example.FileProvider"],
        )

    def test_profile_receiver_without_dump_fails(self):
        text = CLEAN.replace('android:permission="android.permission.DUMP"', "")
        self.assertEqual(len(self.run_on(text)), 1)

    def test_backup_enabled_or_missing_fails(self):
        self.assertEqual(
            len(
                self.run_on(CLEAN.replace('allowBackup="false"', 'allowBackup="true"'))
            ),
            1,
        )
        self.assertEqual(
            len(self.run_on(CLEAN.replace(' android:allowBackup="false"', ""))), 1
        )

    def test_unreadable_path_fails(self):
        self.assertEqual(check("/nonexistent/AndroidManifest.xml"), 1)


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("path", nargs="?", help="merged release AndroidManifest.xml")
    group.add_argument(
        "--self-test", action="store_true", help="run built-in unit tests"
    )
    args = parser.parse_args(argv)
    if args.self_test:
        result = unittest.main(argv=[sys.argv[0]], exit=False, verbosity=2).result
        return 0 if result.wasSuccessful() else 1
    return check(args.path)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
