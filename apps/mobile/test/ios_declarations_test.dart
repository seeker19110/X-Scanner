import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `<string>` value of [key] in the XML property list [plist], or null.
String? _plistString(String plist, String key) =>
    RegExp('<key>${RegExp.escape(key)}</key>\\s*<string>([^<]*)</string>')
        .firstMatch(plist)
        ?.group(1);

void main() {
  test('Info.plist explains camera and photo access in Vietnamese and asks '
      'for nothing else (PRF-MOB-005)', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final camera = _plistString(plist, 'NSCameraUsageDescription');
    final photos = _plistString(plist, 'NSPhotoLibraryUsageDescription');
    expect(camera, allOf(isNotNull, contains('chụp trang tài liệu')));
    expect(photos, allOf(isNotNull, contains('nhập ảnh tài liệu')));
    for (final text in [camera!, photos!]) {
      expect(text, contains('trên thiết bị'));
    }
    final asked = RegExp(r'<key>(NS\w+UsageDescription)</key>')
        .allMatches(plist)
        .map((m) => m.group(1))
        .toSet();
    expect(asked, {
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
    });
  });

  test('PrivacyInfo.xcprivacy declares no tracking, no collected data and '
      'only the required-reason API the code uses (PRF-MOB-004)', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy')
        .readAsStringSync();
    expect(
      manifest,
      matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
    );
    expect(
      manifest,
      matches(RegExp(r'<key>NSPrivacyTrackingDomains</key>\s*<array/>')),
    );
    expect(
      manifest,
      matches(RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>')),
    );
    final categories = RegExp(r'NSPrivacyAccessedAPICategory\w+')
        .allMatches(manifest)
        .map((m) => m.group(0))
        .toList();
    expect(categories, ['NSPrivacyAccessedAPICategoryFileTimestamp']);
    // C617.1: timestamps of files inside the app container only.
    expect(manifest, contains('<string>C617.1</string>'));

    // The declaration matches the code: the P1 migration reads the
    // modification time of session.json in the app container.
    final usesTimestamps = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .any((f) => f.readAsStringSync().contains('.lastModified('));
    expect(usesTimestamps, isTrue);
  });

  test('the privacy manifest is bundled with the Runner app', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    expect(
      project,
      contains('/* PrivacyInfo.xcprivacy in Resources */,'),
      reason: 'listed in the Resources build phase',
    );
    expect(project, contains('path = PrivacyInfo.xcprivacy;'));
  });
}
