import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/storage/pending_pick_store.dart';

const _docA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _docB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _pageA = '11111111111111111111111111111111';
const _pageB = '22222222222222222222222222222222';
const _oldPage = '33333333333333333333333333333333';
const _smallBytes = [17, 23, 41, 59];

/// An abrupt process stop: intentionally not caught as an I/O exception.
final class _Killed extends Error {}

final class _RealIO extends IOOverrides {}

/// Observes finite filesystem operations without a production fault hook.
class _Disk {
  _Disk({
    this.failAt,
    this.kill = true,
    this.growSource,
    this.shrinkSource,
    this.pauseSource,
  });

  final int? failAt;
  final bool kill;
  final String? growSource;
  final String? shrinkSource;
  final String? pauseSource;
  final entered = Completer<void>();
  final release = Completer<void>();
  final List<String> operations = [];
  int maximumPartBytes = 0;
  bool grew = false;
  bool shrank = false;

  void hit(String operation, String path, String phase) {
    operations.add('$phase $operation ${path.split('/').last}');
    if (operations.length == failAt) {
      if (kill) throw _Killed();
      throw FileSystemException('private injected failure', path);
    }
  }

  Future<void> beforeSourceRead(File real) async {
    if (real.path == growSource && !grew) {
      grew = true;
      real.writeAsBytesSync([83], mode: FileMode.append, flush: true);
    }
    if (real.path == shrinkSource && !shrank) {
      shrank = true;
      real.writeAsBytesSync([17, 23], flush: true);
    }
    if (real.path == pauseSource) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
  }

  Future<T> changing<T>(
    String operation,
    String path,
    Future<T> Function() action,
  ) async {
    hit(operation, path, 'before');
    final result = await action();
    hit(operation, path, 'after');
    return result;
  }
}

class _ObservedHandle implements RandomAccessFile {
  _ObservedHandle(this.real, this.disk, this.filePath);

  final RandomAccessFile real;
  final _Disk disk;
  final String filePath;

  @override
  String get path => real.path;

  @override
  Future<Uint8List> read(int count) {
    if (filePath.endsWith('/intent.json')) {
      expect(count, lessThanOrEqualTo(8193));
    }
    return real.read(count);
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) {
    if (filePath.endsWith('/intent.json')) {
      expect((end ?? buffer.length) - start, lessThanOrEqualTo(8193));
    }
    return real.readInto(buffer, start, end);
  }

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await disk.changing('write', filePath, () async {
      await real.writeFrom(buffer, start, end);
      if (filePath.endsWith('.part')) {
        final length = await real.length();
        if (length > disk.maximumPartBytes) disk.maximumPartBytes = length;
      }
    });
    return this;
  }

  @override
  Future<RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    await disk.changing(
      'write',
      filePath,
      () => real.writeString(string, encoding: encoding),
    );
    return this;
  }

  @override
  Future<RandomAccessFile> flush() async {
    await disk.changing('flush', filePath, real.flush);
    return this;
  }

  @override
  Future<int> length() => real.length();

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    await real.setPosition(position);
    return this;
  }

  @override
  Future<int> position() => real.position();

  @override
  Future<void> close() => real.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unobserved handle operation');
}

class _ObservedFile implements File {
  _ObservedFile(this.real, this.disk);

  final File real;
  final _Disk disk;

  @override
  String get path => real.path;

  @override
  Uri get uri => real.uri;

  @override
  Directory get parent => _ObservedDirectory(real.parent, disk);

  @override
  File get absolute => _ObservedFile(real.absolute, disk);

  @override
  Future<bool> exists() => real.exists();

  @override
  Future<FileStat> stat() => real.stat();

  @override
  Future<int> length() => real.length();

  @override
  Future<String> resolveSymbolicLinks() => real.resolveSymbolicLinks();

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    await disk.changing(
      'create',
      path,
      () => real.create(recursive: recursive, exclusive: exclusive),
    );
    return this;
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    if (mode == FileMode.read) {
      await disk.beforeSourceRead(real);
      return _ObservedHandle(await real.open(mode: mode), disk, path);
    }
    disk.hit('open-write', path, 'before');
    final handle = await real.open(mode: mode);
    try {
      disk.hit('open-write', path, 'after');
    } catch (_) {
      // Emulate the OS releasing a handle when the injected process dies.
      await handle.close();
      rethrow;
    }
    return _ObservedHandle(handle, disk, path);
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    if (path.endsWith('/intent.json')) {
      expect(end, isNotNull, reason: 'journal reads must be bounded');
      expect(end! - (start ?? 0), lessThanOrEqualTo(8193));
    }
    return Stream.fromFuture(disk.beforeSourceRead(real))
        .asyncExpand((_) => real.openRead(start, end));
  }

  @override
  Future<Uint8List> readAsBytes() =>
      throw UnsupportedError('whole-file reads are outside the contract');

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      throw UnsupportedError('whole-file reads are outside the contract');

  @override
  Future<File> copy(String newPath) =>
      throw UnsupportedError('unbounded copy is outside the contract');

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => disk.changing(
    'write',
    path,
    () => real.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    ),
  );

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => disk.changing(
    'write',
    path,
    () => real.writeAsBytes(bytes, mode: mode, flush: flush),
  );

  @override
  Future<File> rename(String newPath) async => _ObservedFile(
    await disk.changing('rename', path, () => real.rename(newPath)),
    disk,
  );

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      disk.changing('delete', path, () => real.delete(recursive: recursive));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unobserved file operation');
}

class _ObservedDirectory implements Directory {
  _ObservedDirectory(this.real, this.disk);

  final Directory real;
  final _Disk disk;

  @override
  String get path => real.path;

  @override
  Uri get uri => real.uri;

  @override
  Directory get parent => _ObservedDirectory(real.parent, disk);

  @override
  Directory get absolute => _ObservedDirectory(real.absolute, disk);

  @override
  Future<bool> exists() => real.exists();

  @override
  Future<FileStat> stat() => real.stat();

  @override
  Future<String> resolveSymbolicLinks() => real.resolveSymbolicLinks();

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => real
      .list(recursive: recursive, followLinks: followLinks)
      .map(
        (entity) => switch (entity) {
          File() => _ObservedFile(entity, disk),
          Directory() => _ObservedDirectory(entity, disk),
          _ => entity,
        },
      );

  @override
  Future<Directory> create({bool recursive = false}) async {
    await disk.changing('mkdir', path, () => real.create(recursive: recursive));
    return this;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      disk.changing('delete', path, () => real.delete(recursive: recursive));

  @override
  Future<Directory> rename(String newPath) async => _ObservedDirectory(
    await disk.changing('rename', path, () => real.rename(newPath)),
    disk,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unobserved directory operation');
}

Future<T> _observed<T>(_Disk disk, Future<T> Function() body) {
  final real = _RealIO();
  return IOOverrides.runZoned(
    body,
    createFile: (path) => _ObservedFile(real.createFile(path), disk),
    createDirectory: (path) =>
        _ObservedDirectory(real.createDirectory(path), disk),
  );
}

void main() {
  late Directory root;
  late Directory cache;
  late Directory pendingDir;

  setUp(() {
    root = Directory.systemTemp.createTempSync('pending_pick_test');
    cache = Directory('${root.path}/cache')..createSync();
    pendingDir = Directory('${root.path}/support/pending_pick');
  });

  tearDown(() => root.deleteSync(recursive: true));

  PendingPickStore store({int maxBytes = 64}) => PendingPickStore(
    dir: Directory(pendingDir.path),
    cacheDir: Directory(cache.path),
    maxBytes: maxBytes,
  );

  File write(String path, [List<int> bytes = _smallBytes]) => File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes, flush: true);

  File source([String name = 'camera.jpg']) => write('${cache.path}/$name');

  File journal() => File('${pendingDir.path}/intent.json');

  Map<String, Object?> value({
    String docId = _docA,
    String pageId = _pageA,
    String? replacePageId,
    bool createOwner = false,
    String? cachePath,
    String? extension,
  }) => {
    'version': 1,
    'docId': docId,
    'pageId': pageId,
    'replacePageId': replacePageId,
    'createOwner': createOwner,
    'cacheRelativePath': cachePath,
    'extension': extension,
  };

  void writeJournal(Map<String, Object?> fields) =>
      write(journal().path, utf8.encode(jsonEncode(fields)));

  Map<String, Object?> snapshot() => {
    for (final entity in root.listSync(recursive: true, followLinks: false))
      entity.path.substring(root.path.length): switch (entity) {
        File() => entity.readAsBytesSync(),
        Link() => 'link:${entity.targetSync()}',
        _ => null,
      },
  };

  Map<String, Object?> tree(Directory dir) => {
    for (final entity in dir.listSync(recursive: true, followLinks: false))
      entity.path.substring(dir.path.length): switch (entity) {
        File() => entity.readAsBytesSync(),
        Link() => 'link:${entity.targetSync()}',
        _ => null,
      },
  };

  Directory rejected() => Directory('${pendingDir.path}.rejected-$_pageA');

  Future<PendingPick> reserve({
    PendingPickStore? using,
    String pageId = _pageA,
    String? replacePageId,
    bool createOwner = false,
  }) => (using ?? store()).begin(
    docId: _docA,
    pageId: pageId,
    replacePageId: replacePageId,
    createOwner: createOwner,
  );

  Future<PendingPick> remembered({PendingPickStore? using}) async {
    final s = using ?? store();
    final pick = await reserve(using: s);
    return s.remember(pick, source().path);
  }

  Future<void> closed<T>(Future<T> Function() action) async {
    await expectLater(action(), throwsA(isA<PendingPickFailure>()));
  }

  Future<void> classified<T>(
    Future<T> Function() action, {
    required bool sizeRejected,
  }) async {
    await expectLater(
      action(),
      throwsA(
        isA<PendingPickFailure>().having(
          (failure) => failure.sizeRejected,
          'sizeRejected',
          sizeRejected,
        ),
      ),
    );
  }

  group('closed failure classification (FR-4)', () {
    for (final bytes in [
      <int>[],
      [1, 2, 3, 4, 5],
    ]) {
      test(
        'source byte-size rejection is classified: ${bytes.length}',
        () async {
          final s = store(maxBytes: 4);
          final raw = write('${cache.path}/camera.jpg', bytes);
          final intent = await reserve(using: s);
          final pick = await s.remember(intent, raw.path);
          await classified(() => s.stage(pick), sizeRejected: true);
          expect(raw.readAsBytesSync(), bytes);
        },
      );

      test(
        'staged original byte-size rejection is classified: ${bytes.length}',
        () async {
          final s = store(maxBytes: 4);
          final pick = await remembered(using: s);
          write('${pendingDir.path}/original.jpg', bytes);
          await classified(() => s.stage(pick), sizeRejected: true);
          expect(
            File('${pendingDir.path}/original.jpg').readAsBytesSync(),
            bytes,
          );
        },
      );
    }

    test('actual copied bytes over the cap are a size rejection', () async {
      final s = store(maxBytes: 4);
      final pick = await remembered(using: s);
      final disk = _Disk(growSource: '${cache.path}/camera.jpg');
      await _observed(
        disk,
        () => classified(() => s.stage(pick), sizeRejected: true),
      );
      expect(disk.grew, isTrue);
      expect(disk.maximumPartBytes, lessThanOrEqualTo(4));
    });

    test(
      'a source shortened during copy remains a retryable storage failure',
      () async {
        final s = store(maxBytes: 4);
        final pick = await remembered(using: s);
        final disk = _Disk(shrinkSource: '${cache.path}/camera.jpg');
        await _observed(
          disk,
          () => classified(() => s.stage(pick), sizeRejected: false),
        );
        expect(disk.shrank, isTrue);
        expect(journal().existsSync(), isTrue);
        expect(File('${pendingDir.path}/original.jpg.part').readAsBytesSync(), [
          17,
          23,
        ]);
      },
    );

    test('an I/O failure is not reclassified as rejected input', () async {
      final s = store();
      final pick = await remembered(using: s);
      final disk = _Disk(failAt: 1, kill: false);
      await _observed(
        disk,
        () => classified(() => s.stage(pick), sizeRejected: false),
      );
      expect(disk.operations, isNotEmpty);
      expect(File('${cache.path}/camera.jpg').readAsBytesSync(), _smallBytes);
    });

    test(
      'identity, journal and path failures are never size rejections',
      () async {
        final s = store();
        final stale = await reserve(using: s);
        await s.cancel(stale);
        final current = await reserve(using: s, pageId: _pageB);
        await classified(() => s.stage(stale), sizeRejected: false);
        final outside = write('${root.path}/outside.jpg');
        await classified(
          () => s.remember(current, outside.path),
          sizeRejected: false,
        );
        write(journal().path, utf8.encode('private invalid JSON'));
        await classified(() => s.load(), sizeRejected: false);
      },
    );
  });

  group('identity and journal (AC-1)', () {
    test('a truly empty location loads without creating files', () async {
      final before = snapshot();
      expect(await store().load(), isNull);
      expect(snapshot(), before);
    });

    test('begin durably reserves one immutable destination', () async {
      final pick = await reserve(replacePageId: _oldPage);
      expect(pick.docId, _docA);
      expect(pick.pageId, _pageA);
      expect(pick.replacePageId, _oldPage);
      expect(pick.createOwner, isFalse);
      expect(pick.cacheRelativePath, isNull);
      final restored = await store().load();
      expect(restored, isNotNull);
      expect(restored!.docId, _docA);
      expect(restored.pageId, _pageA);
      expect(restored.replacePageId, _oldPage);
      expect(
        jsonDecode(journal().readAsStringSync()),
        value(replacePageId: _oldPage),
      );
    });

    test(
      'bootstrap reservation persists its explicit create-owner flag',
      () async {
        await reserve(createOwner: true);
        expect((await store().load())!.createOwner, isTrue);
      },
    );

    test(
      'an existing reservation cannot be overwritten by another owner',
      () async {
        await reserve();
        final before = snapshot();
        await closed(() => store().begin(docId: _docB, pageId: _pageB));
        expect(snapshot(), before);
      },
    );

    test('queued begin calls permit only the first reservation', () async {
      final s = store();
      final first = reserve(using: s);
      final second = expectLater(
        s.begin(docId: _docB, pageId: _pageB),
        throwsA(isA<PendingPickFailure>()),
      );
      await first;
      await second;
      expect((await s.load())!.docId, _docA);
    });

    for (final bad in ['', 'ABC', '../$_docA', 'A' * 32, 'a' * 31]) {
      test('invalid document or page id is rejected: ${bad.length}', () async {
        final before = snapshot();
        await closed(() => store().begin(docId: bad, pageId: _pageA));
        await closed(() => store().begin(docId: _docA, pageId: bad));
        expect(snapshot(), before);
      });
    }

    test(
      'retake validates its old id and cannot create a missing owner',
      () async {
        await closed(() => reserve(replacePageId: '../bad'));
        await closed(() => reserve(replacePageId: _pageA));
        await closed(() => reserve(replacePageId: _oldPage, createOwner: true));
        expect(journal().existsSync(), isFalse);
      },
    );

    for (final maxBytes in [0, -1]) {
      test('nonpositive byte cap is rejected: $maxBytes', () {
        expect(() => store(maxBytes: maxBytes), throwsArgumentError);
      });
    }

    final invalidFields = <String, Map<String, Object?>>{
      'future version': value()..['version'] = 2,
      'noninteger version': value()..['version'] = 1.0,
      'missing owner': value()..remove('docId'),
      'bad owner': value()..['docId'] = '../outside',
      'bad page': value()..['pageId'] = null,
      'nonboolean flag': value()..['createOwner'] = 1,
      'missing flag': value()..remove('createOwner'),
      'same old and new id': value(replacePageId: _pageA),
      'bootstrap retake': value(replacePageId: _oldPage, createOwner: true),
      'unpaired path': value(cachePath: 'camera.jpg'),
      'unpaired extension': value(extension: 'jpg'),
      'bad extension': value(cachePath: 'camera.jpg', extension: '../jpg'),
    };
    for (final entry in invalidFields.entries) {
      test('invalid journal is preserved: ${entry.key}', () async {
        writeJournal(entry.value);
        final before = snapshot();
        await closed(() => store().load());
        await closed(() => reserve());
        expect(snapshot(), before);
      });
    }

    for (final path in [
      '/outside.jpg',
      '../outside.jpg',
      'uuid/../photo.jpg',
      'uuid/./photo.jpg',
      'uuid//photo.jpg',
      r'uuid\photo.jpg',
      'uuid/\u0000photo.jpg',
      'p' * 2049,
    ]) {
      test(
        'an injected relative cache path is not followed: ${jsonEncode(path)}',
        () async {
          writeJournal(value(cachePath: path, extension: 'jpg'));
          final before = snapshot();
          await closed(() => store().load());
          expect(snapshot(), before);
        },
      );
    }

    for (final (index, bytes) in [
      [255, 254],
      utf8.encode('{broken private payload'),
      utf8.encode('[]'),
      List<int>.filled(8193, 32),
    ].indexed) {
      test(
        'unreadable or oversized journal is bounded and untouched: $index',
        () async {
          write(journal().path, bytes);
          final before = snapshot();
          await _observed(_Disk(), () => closed(() => store().load()));
          expect(snapshot(), before);
        },
      );
    }

    test('a valid journal at exactly 8192 bytes is accepted', () async {
      final text = jsonEncode(value());
      write(journal().path, utf8.encode(text.padRight(8192)));
      final pick = await _observed(_Disk(), () => store().load());
      expect(pick!.pageId, _pageA);
    });

    for (final name in [
      'intent.json.tmp',
      'original.jpg.part',
      'unknown.bin',
    ]) {
      test(
        'orphan state is kept and blocks a fresh reservation: $name',
        () async {
          write('${pendingDir.path}/$name');
          final before = snapshot();
          await closed(() => store().load());
          await closed(() => reserve());
          expect(snapshot(), before);
        },
      );
    }

    test('journal and pending-directory symlinks are not followed', () async {
      final outside = write(
        '${root.path}/private.json',
        utf8.encode(jsonEncode(value())),
      );
      pendingDir.createSync(recursive: true);
      Link(journal().path).createSync(outside.path);
      final before = snapshot();
      await closed(() => store().load());
      expect(snapshot(), before);
      Link(journal().path).deleteSync();
      pendingDir.deleteSync();
      final target = Directory('${root.path}/private')..createSync();
      write('${target.path}/original.jpg');
      Link(pendingDir.path).createSync(target.path);
      final linked = snapshot();
      await closed(() => reserve());
      expect(snapshot(), linked);
    });

    test('a file at the pending-directory path is not replaced', () async {
      write(pendingDir.path, [71, 73]);
      final before = snapshot();
      await closed(() => store().load());
      await closed(() => reserve());
      expect(snapshot(), before);
    });
  });

  group('cache boundary and bounded copy (AC-2)', () {
    test(
      'an oversized escaped cache path cannot create an unreadable journal',
      () async {
        final s = store();
        final pick = await reserve(using: s);
        final segments = List.generate(10, (i) => 'p$i${'\u0001' * 180}');
        final relative = '${segments.join('/')}/photo.jpg';
        expect(relative.length, lessThanOrEqualTo(2048));
        final raw = source(relative);
        final before = snapshot();
        await closed(() => s.remember(pick, raw.path));
        expect(snapshot(), before);
        expect((await store().load())!.cacheRelativePath, isNull);
      },
    );

    for (final name in [
      'camera.JPG',
      'uuid/photo.PNG',
      'no_extension',
      'odd.longer',
    ]) {
      test(
        'remembers only a relative path and stages exact bytes: $name',
        () async {
          final s = store(maxBytes: 4);
          final raw = source(name);
          final pick = await reserve(using: s);
          final saved = await s.remember(pick, raw.path);
          expect(saved.cacheRelativePath, name);
          expect(saved.extension, name.endsWith('.PNG') ? 'png' : 'jpg');
          expect(journal().readAsStringSync(), isNot(contains(root.path)));
          final recovered = await store(maxBytes: 4).load();
          final staged = await _observed(
            _Disk(),
            () => store(maxBytes: 4).stage(recovered!),
          );
          expect(File(staged.path).readAsBytesSync(), _smallBytes);
          expect(raw.readAsBytesSync(), _smallBytes);
          expect(staged.path.startsWith('${pendingDir.path}/'), isTrue);
          expect(File('${staged.path}.part').existsSync(), isFalse);
        },
      );
    }

    test(
      'same remembered source is idempotent; a different source is refused',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        final before = snapshot();
        final same = await s.remember(pick, '${cache.path}/camera.jpg');
        expect(same.cacheRelativePath, 'camera.jpg');
        expect(snapshot(), before);
        final other = source('another.jpg');
        final beforeOther = snapshot();
        await closed(() => s.remember(pick, other.path));
        expect(snapshot(), beforeOther);
      },
    );

    test(
      'cache root, sibling prefix and traversal outside are refused',
      () async {
        final s = store();
        final pick = await reserve(using: s);
        final outside = write('${root.path}/cache-other/photo.jpg');
        for (final path in [
          cache.path,
          outside.path,
          '${cache.path}/../cache-other/photo.jpg',
          '${root.path}/missing.jpg',
        ]) {
          final before = snapshot();
          await closed(() => s.remember(pick, path));
          expect(snapshot(), before);
        }
      },
    );

    test('source link escapes and changed source links are refused', () async {
      final s = store();
      final outside = write('${root.path}/outside.jpg');
      final link = Link('${cache.path}/linked.jpg')..createSync(outside.path);
      final pick = await reserve(using: s);
      final before = snapshot();
      await closed(() => s.remember(pick, link.path));
      expect(snapshot(), before);
      final raw = source();
      final saved = await s.remember(pick, raw.path);
      raw.deleteSync();
      Link(raw.path).createSync(outside.path);
      final changed = snapshot();
      await closed(() => s.stage(saved));
      expect(snapshot(), changed);
    });

    test(
      'a symlinked source ancestor cannot escape the cache boundary',
      () async {
        final s = store();
        final pick = await reserve(using: s);
        final outside = write('${root.path}/outside/secret.jpg');
        final link = Link('${cache.path}/uuid')
          ..createSync(outside.parent.path);
        final before = snapshot();
        await closed(() => s.remember(pick, '${link.path}/secret.jpg'));
        expect(snapshot(), before);
      },
    );

    for (final name in [
      'original.jpg',
      'original.jpg.part',
      'intent.json.tmp',
    ]) {
      test('output links cannot overwrite outside files: $name', () async {
        final s = store();
        final pick = await remembered(using: s);
        final outside = write('${root.path}/outside.jpg', [99]);
        Link('${pendingDir.path}/$name').createSync(outside.path);
        final before = snapshot();
        await closed(() => s.stage(pick));
        expect(snapshot(), before);
      });
    }

    for (final bytes in [
      <int>[],
      [1, 2, 3, 4, 5],
    ]) {
      test(
        'empty and one-byte-over-cap source are kept without staged output: ${bytes.length}',
        () async {
          final s = store(maxBytes: 4);
          final raw = write('${cache.path}/camera.jpg', bytes);
          final pick = await reserve(using: s);
          final saved = await s.remember(pick, raw.path);
          await closed(() => s.stage(saved));
          expect(raw.readAsBytesSync(), bytes);
          expect(journal().existsSync(), isTrue);
          expect(File('${pendingDir.path}/original.jpg').existsSync(), isFalse);
        },
      );
    }

    test(
      'a source growing after the length check cannot cause over-cap writes',
      () async {
        final s = store(maxBytes: 4);
        final pick = await remembered(using: s);
        final disk = _Disk(growSource: '${cache.path}/camera.jpg');
        await _observed(
          disk,
          () => closed(() => store(maxBytes: 4).stage(pick)),
        );
        expect(
          disk.grew,
          isTrue,
          reason: 'the test must reach the source read',
        );
        expect(disk.maximumPartBytes, lessThanOrEqualTo(4));
        expect(File('${cache.path}/camera.jpg').lengthSync(), 5);
        expect(journal().existsSync(), isTrue);
      },
    );

    test('a queued load waits until an in-flight stage has finished', () async {
      final s = store();
      final pick = await remembered(using: s);
      final disk = _Disk(pauseSource: '${cache.path}/camera.jpg');
      await _observed(disk, () async {
        final copying = s.stage(pick);
        try {
          await disk.entered.future.timeout(const Duration(seconds: 2));
          var loaded = false;
          final reading = s.load().then((value) {
            loaded = true;
            return value;
          });
          await Future<void>.delayed(Duration.zero);
          expect(loaded, isFalse);
          disk.release.complete();
          final staged = await copying;
          expect((await reading)!.pageId, _pageA);
          expect(staged.path, '${pendingDir.path}/original.jpg');
        } finally {
          if (!disk.release.isCompleted) disk.release.complete();
          await copying;
        }
      });
    });

    test(
      'a staged original survives cache eviction and is reused unchanged',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        final staged = await s.stage(pick);
        File('${cache.path}/camera.jpg').deleteSync();
        final before = snapshot();
        final reloaded = await store().load();
        final reused = await store().stage(reloaded!);
        expect(reused.path, staged.path);
        expect(reused.readAsBytesSync(), _smallBytes);
        expect(snapshot(), before);
      },
    );
  });

  group('retry, cleanup and fault retention (AC-3)', () {
    test(
      'a configured trailing separator still retains into a sibling',
      () async {
        final s = PendingPickStore(
          dir: Directory('${pendingDir.path}/'),
          cacheDir: cache,
          maxBytes: 64,
        );
        final pick = await remembered(using: s);
        await s.stage(pick);
        final before = tree(pendingDir);
        await s.retainRejected(pick);
        expect(pendingDir.existsSync(), isFalse);
        expect(tree(rejected()), before);
      },
    );

    test(
      'empty intent can cancel; a remembered result cannot cancel',
      () async {
        final s = store();
        final empty = await reserve(using: s);
        await s.cancel(empty);
        expect(await s.load(), isNull);
        final pick = await remembered(using: s);
        final before = snapshot();
        await closed(() => s.cancel(pick));
        expect(snapshot(), before);
      },
    );

    test(
      'stale handles cannot remember, stage, cancel or complete a newer intent',
      () async {
        final s = store();
        final old = await reserve(using: s);
        await s.cancel(old);
        await reserve(using: s, pageId: _pageB);
        final raw = source();
        final before = snapshot();
        await closed(() => s.remember(old, raw.path));
        await closed(() => s.stage(old));
        await closed(() => s.cancel(old));
        await closed(() => s.complete(old));
        await closed(() => s.retainRejected(old));
        expect(snapshot(), before);
      },
    );

    test('a sole partial copy is preserved when the source has gone', () async {
      final s = store();
      final pick = await remembered(using: s);
      write('${pendingDir.path}/original.jpg.part', [17, 23]);
      File('${cache.path}/camera.jpg').deleteSync();
      final before = snapshot();
      final restored = await store().load();
      expect(restored!.pageId, pick.pageId);
      await closed(() => store().stage(restored));
      expect(snapshot(), before);
    });

    test(
      'known partial is restaged only while valid source bytes remain',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        write('${pendingDir.path}/original.jpg.part', [17]);
        final staged = await store().stage(pick);
        expect(staged.readAsBytesSync(), _smallBytes);
        expect(File('${cache.path}/camera.jpg').readAsBytesSync(), _smallBytes);
      },
    );

    test(
      'complete deletes only known pending files; cache and document stay',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        await s.stage(pick);
        final original = write(
          '${root.path}/documents/$_docA/originals/$_pageA.jpg',
        );
        await s.complete(pick); // caller acknowledgement of a durable manifest
        expect(await store().load(), isNull);
        expect(original.readAsBytesSync(), _smallBytes);
        expect(File('${cache.path}/camera.jpg').readAsBytesSync(), _smallBytes);
        expect(File('${pendingDir.path}/original.jpg').existsSync(), isFalse);
      },
    );

    test('unknown files block complete and remain untouched', () async {
      final s = store();
      final pick = await remembered(using: s);
      await s.stage(pick);
      write('${pendingDir.path}/unknown.bin', [77]);
      final before = snapshot();
      await closed(() => s.complete(pick));
      expect(snapshot(), before);
    });

    test(
      'public failures never expose journal, raw path or OS payload',
      () async {
        write(journal().path, utf8.encode('private-payload: not JSON'));
        try {
          await store().load();
          fail('invalid journal must not be treated as empty');
        } on PendingPickFailure catch (error) {
          expect(error.toString(), isNot(contains(root.path)));
          expect(error.toString(), isNot(contains('private-payload')));
        }
      },
    );

    test(
      'a rejected staged input keeps all bytes and permits a fresh capture',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        await s.stage(pick);
        write('${pendingDir.path}/original.jpg.part', [17]);
        final before = tree(pendingDir);
        await s.retainRejected(pick);
        expect(pendingDir.existsSync(), isFalse);
        expect(rejected().existsSync(), isTrue);
        expect(tree(rejected()), before);
        expect(File('${cache.path}/camera.jpg').readAsBytesSync(), _smallBytes);
        expect(await store().load(), isNull);
        await reserve(using: s, pageId: _pageB);
        expect((await store().load())!.pageId, _pageB);
        expect(tree(rejected()), before);
      },
    );

    test(
      'a rejected staged original is retained after OS cache eviction',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        await s.stage(pick);
        File('${cache.path}/camera.jpg').deleteSync();
        final before = tree(pendingDir);
        await s.retainRejected(pick);
        expect(tree(rejected()), before);
        expect(
          File('${rejected().path}/original.jpg').readAsBytesSync(),
          _smallBytes,
        );
        expect(await store().load(), isNull);
      },
    );

    test(
      'an unstaged oversized rejection retains cache and its journal',
      () async {
        final s = store(maxBytes: 4);
        final raw = write('${cache.path}/camera.jpg', [1, 2, 3, 4, 5]);
        final pick = await reserve(using: s);
        final saved = await s.remember(pick, raw.path);
        await closed(() => s.stage(saved));
        final before = tree(pendingDir);
        await s.retainRejected(saved);
        expect(tree(rejected()), before);
        expect(raw.readAsBytesSync(), [1, 2, 3, 4, 5]);
        expect(await store().load(), isNull);
        await reserve(using: s, pageId: _pageB);
        expect((await store().load())!.pageId, _pageB);
      },
    );

    test('empty and ambiguous rejected intents are never parked', () async {
      final s = store();
      final empty = await reserve(using: s);
      final beforeEmpty = snapshot();
      await closed(() => s.retainRejected(empty));
      expect(snapshot(), beforeEmpty);
      final pick = await s.remember(empty, source().path);
      write('${pendingDir.path}/original.jpg.part', [17]);
      File('${cache.path}/camera.jpg').deleteSync();
      final beforeMissing = snapshot();
      await closed(() => s.retainRejected(pick));
      expect(snapshot(), beforeMissing);
      expect(rejected().existsSync(), isFalse);
    });

    test(
      'unknown active state blocks rejected retention without deleting it',
      () async {
        final s = store();
        final pick = await remembered(using: s);
        await s.stage(pick);
        write('${pendingDir.path}/unknown.bin', [79]);
        final before = snapshot();
        await closed(() => s.retainRejected(pick));
        expect(snapshot(), before);
      },
    );

    for (final targetKind in ['directory', 'file', 'link']) {
      test(
        'rejected target collision is never overwritten: $targetKind',
        () async {
          final s = store();
          final pick = await remembered(using: s);
          switch (targetKind) {
            case 'directory':
              rejected().createSync();
            case 'file':
              write(rejected().path, [97]);
            case 'link':
              final outside = Directory('${root.path}/private')..createSync();
              write('${outside.path}/kept.bin', [89]);
              Link(rejected().path).createSync(outside.path);
          }
          final before = snapshot();
          await closed(() => s.retainRejected(pick));
          expect(snapshot(), before);
        },
      );
    }

    for (final phase in [
      'begin',
      'remember',
      'stage',
      'cancel',
      'complete',
      'retainRejected',
    ]) {
      for (final kill in [true, false]) {
        test('every observed $phase mutation retains recoverable state '
            'after ${kill ? 'kill' : 'I/O failure'}', () async {
          Future<void> prepare() async {
            if (pendingDir.existsSync()) pendingDir.deleteSync(recursive: true);
            // Give every begin attempt the same absent-parent fixture as
            // the baseline, so recursive mkdir fault indices stay stable.
            if (phase == 'begin' && pendingDir.parent.existsSync()) {
              pendingDir.parent.deleteSync(recursive: true);
            }
            if (phase == 'retainRejected' && rejected().existsSync()) {
              rejected().deleteSync(recursive: true);
            }
            source();
            if (phase == 'begin') return;
            final s = store();
            final pick = await reserve(using: s);
            if (phase == 'remember' || phase == 'cancel') return;
            final saved = await s.remember(pick, '${cache.path}/camera.jpg');
            if (phase == 'complete') await s.stage(saved);
          }

          Future<void> operation() async {
            final s = store();
            if (phase == 'begin') {
              await reserve(using: s);
              return;
            }
            final pick = (await s.load())!;
            switch (phase) {
              case 'remember':
                await s.remember(pick, '${cache.path}/camera.jpg');
              case 'stage':
                await s.stage(pick);
              case 'complete':
                await s.complete(pick);
              case 'cancel':
                await s.cancel(pick);
              case 'retainRejected':
                await s.retainRejected(pick);
            }
          }

          await prepare();
          final observation = _Disk();
          await _observed(observation, operation);
          expect(
            observation.operations,
            isNotEmpty,
            reason: 'fault coverage must observe actual disk mutations',
          );
          for (var at = 1; at <= observation.operations.length; at++) {
            await prepare();
            final disk = _Disk(failAt: at, kill: kill);
            try {
              await _observed(disk, operation);
            } on _Killed {
              // Process stop: no cleanup runs in production.
            } on PendingPickFailure {
              // Sanitized failure may have kept an earlier durable stage.
            }
            expect(
              disk.operations.length,
              greaterThanOrEqualTo(at),
              reason: 'injection must be reached',
            );
            expect(
              File('${cache.path}/camera.jpg').readAsBytesSync(),
              _smallBytes,
            );
            final beforeReload = snapshot();
            try {
              final restored = await store().load();
              if (restored != null) {
                expect(restored.docId, _docA);
                expect(restored.pageId, _pageA);
              }
            } on PendingPickFailure {
              // Ambiguous temp/partial is preserved, never guessed empty.
            }
            expect(
              snapshot(),
              beforeReload,
              reason: 'load must never delete ambiguous state',
            );
          }
        });
      }
    }
  });
}
