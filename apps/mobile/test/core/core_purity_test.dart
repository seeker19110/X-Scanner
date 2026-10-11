import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core library does not import Flutter (spec FR-3)', () {
    final files = Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        file.readAsStringSync(),
        isNot(contains('package:flutter')),
        reason: file.path,
      );
    }
  });
}
