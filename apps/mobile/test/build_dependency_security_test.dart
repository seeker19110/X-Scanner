import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<RegExpMatch> _guavaEntries(String path) => RegExp(
  r'^com\.google\.guava:guava:([^=]+)=(.+)$',
  multiLine: true,
).allMatches(File(path).readAsStringSync()).toList();

void main() {
  for (final path in [
    'android/settings-gradle.lockfile',
    'android/app/gradle.lockfile',
  ]) {
    test('$path locks Guava at the CVE-2026-102554 patched floor', () {
      final entries = _guavaEntries(path);
      expect(
        entries,
        isNotEmpty,
        reason: 'build-tool Guava must remain locked',
      );
      for (final entry in entries) {
        final version = entry.group(1)!;
        final parsed = RegExp(r'^(\d+)\.(\d+)\.(\d+)-jre$').firstMatch(version);
        expect(
          parsed,
          isNotNull,
          reason: 'stable JRE build-tool version: $version',
        );
        final major = int.parse(parsed!.group(1)!);
        final minor = int.parse(parsed.group(2)!);
        final patch = int.parse(parsed.group(3)!);
        expect(
          major > 33 || major == 33 && (minor > 7 || minor == 7 && patch >= 2),
          isTrue,
          reason: '$path has vulnerable Guava $version; minimum is 33.7.2-jre',
        );
      }
    });
  }

  test('full Guava stays on build tools and outside release runtime', () {
    final settings = _guavaEntries('android/settings-gradle.lockfile');
    expect(settings, isNotEmpty);
    expect(settings.every((entry) => entry.group(2) == 'classpath'), isTrue);

    final app = _guavaEntries('android/app/gradle.lockfile');
    expect(app, isNotEmpty);
    final configurations = app
        .expand((entry) => entry.group(2)!.split(','))
        .toSet();
    expect(configurations, contains('androidLintTool'));
    expect(
      configurations.every(
        (name) =>
            name == 'androidLintTool' ||
            name.startsWith('_internal-unified-test-platform-'),
      ),
      isTrue,
      reason: 'Guava belongs only to resolved build-tool configurations',
    );
    expect(configurations, isNot(contains('releaseRuntimeClasspath')));
  });
}
