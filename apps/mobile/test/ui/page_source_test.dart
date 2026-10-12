import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/ui/page_source.dart';

void main() {
  late Directory tmp;
  late Directory cache;
  late ImagePickerPageSource source;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('page_source_test');
    cache = Directory('${tmp.path}/cache')..createSync();
    source = ImagePickerPageSource(cacheDir: cache);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Writes a small synthetic file at [path] and returns it.
  File write(String path) => File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync([1, 2, 3]);

  test('a camera copy directly in the cache is deleted (F-005)', () async {
    final file = write('${cache.path}/image_picker123.jpg');
    await source.discard(file.path);
    expect(file.existsSync(), isFalse);
    expect(cache.existsSync(), isTrue);
  });

  test('a picked copy in cache/{uuid}/ is deleted with its now empty '
      'folder (F-005)', () async {
    final file = write('${cache.path}/0f3c-uuid/scan.jpg');
    await source.discard(file.path);
    expect(file.existsSync(), isFalse);
    expect(file.parent.existsSync(), isFalse);
    expect(cache.existsSync(), isTrue);
  });

  test('a folder that still holds other files is kept (F-005)', () async {
    final file = write('${cache.path}/uuid/scan.jpg');
    final other = write('${cache.path}/uuid/other.jpg');
    await source.discard(file.path);
    expect(file.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
  });

  test('a file in a sibling folder whose name starts with the cache '
      'name is untouched (F-005)', () async {
    final outside = write('${tmp.path}/cache2/scan.jpg');
    final elsewhere = write('${tmp.path}/scan.jpg');
    await source.discard(outside.path);
    await source.discard(elsewhere.path);
    expect(outside.existsSync(), isTrue);
    expect(elsewhere.existsSync(), isTrue);
  });

  test(
    'a path climbing out of the cache with .. is untouched (F-005)',
    () async {
      final outside = write('${tmp.path}/scan.jpg');
      await source.discard('${cache.path}/../scan.jpg');
      expect(outside.existsSync(), isTrue);
    },
  );

  test('without a cache folder nothing is deleted (F-005)', () async {
    final file = write('${cache.path}/scan.jpg');
    await ImagePickerPageSource().discard(file.path);
    expect(file.existsSync(), isTrue);
  });

  test('discarding the cache folder itself deletes nothing (F-005)', () async {
    final file = write('${cache.path}/scan.jpg');
    await source.discard(cache.path);
    await source.discard('${cache.path}/');
    expect(cache.existsSync(), isTrue);
    expect(file.existsSync(), isTrue);
  });

  test('a missing file or cache folder does not throw (F-005)', () async {
    await source.discard('${cache.path}/missing.jpg');
    await source.discard('${cache.path}/gone/missing.jpg');
    final missingCache = ImagePickerPageSource(
      cacheDir: Directory('${tmp.path}/no-cache'),
    );
    await missingCache.discard('${tmp.path}/no-cache/scan.jpg');
    expect(cache.existsSync(), isTrue);
  });
}
