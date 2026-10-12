import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/storage/session_store.dart';

final PageQuad _skewed = PageQuad(
  topLeft: const Point<double>(0.1, 0.05),
  topRight: const Point<double>(0.93, 0.12),
  bottomRight: const Point<double>(0.88, 0.97),
  bottomLeft: const Point<double>(0.02, 0.9),
);

/// Synthetic, distinct bytes for page [n]; no real images are used.
List<int> _bytes(int n) => List<int>.generate(64 + n, (i) => (i * 7 + n) % 256);

/// Gives access to the real [File] constructor inside an override zone.
final class _RealIO extends IOOverrides {}

/// The manifest as seen through a failing disk: [readAsBytes] (when
/// [failRead]) and [rename] throw like an I/O error; [exists] is real.
class _FailingManifest implements File {
  _FailingManifest(this._real, {required this.failRead});

  final File _real;
  final bool failRead;

  @override
  String get path => _real.path;

  @override
  Future<bool> exists() => _real.exists();

  @override
  Future<Uint8List> readAsBytes() => failRead
      ? Future<Uint8List>.error(const FileSystemException('read failed'))
      : _real.readAsBytes();

  @override
  Future<File> rename(String newPath) =>
      Future<File>.error(const FileSystemException('rename failed'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used by SessionStore.load');
}

/// Runs [body] with every `session.json` failing as [_FailingManifest].
Future<T> _withFailingManifest<T>(
  Future<T> Function() body, {
  required bool failRead,
}) {
  final real = _RealIO();
  return IOOverrides.runZoned(
    body,
    createFile: (path) => path.endsWith('/session.json')
        ? _FailingManifest(real.createFile(path), failRead: failRead)
        : real.createFile(path),
  );
}

/// A source whose copy pauses after writing until [release] completes,
/// so other store calls can run while the copy is unfinished.
class _PausedCopySource implements File {
  _PausedCopySource(this._real, this.release);

  final File _real;
  final Future<void> release;

  @override
  String get path => _real.path;

  @override
  Future<File> copy(String newPath) async {
    final copied = await _real.copy(newPath);
    await release;
    return copied;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used by SessionStore.importOriginal');
}

void main() {
  late Directory tmp;
  late Directory root;
  late Directory sources;
  late SessionStore store;
  var seed = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('session_store_test');
    root = Directory('${tmp.path}/session')..createSync();
    sources = Directory('${tmp.path}/sources')..createSync();
    store = SessionStore(root);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  File source(int n) =>
      File('${sources.path}/src$n.jpg')..writeAsBytesSync(_bytes(n));

  /// Imports a synthetic original for page [n] and returns its page.
  Future<ScanPage> importPage(int n) async {
    final id = newPageId(Random(seed++));
    final path = await store.importOriginal(
      source(n),
      id: id,
      extension: 'jpg',
    );
    return ScanPage(id: id, originalPath: path);
  }

  File manifest() => File('${root.path}/session.json');

  List<String> originalNames() =>
      Directory('${root.path}/originals')
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .toList()
        ..sort();

  Map<String, List<int>> originalBytes() => {
    for (final f in Directory(
      '${root.path}/originals',
    ).listSync().whereType<File>())
      f.path: f.readAsBytesSync(),
  };

  List<File> corruptCopies() => root
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'session\.corrupt-\d+\.json$').hasMatch(f.path))
      .toList();

  group('importOriginal', () {
    test('copies bytes and returns the relative path', () async {
      final id = newPageId(Random(1));
      final src = source(1);
      final path = await store.importOriginal(src, id: id, extension: 'JPG');
      expect(path, 'originals/$id.jpg');
      expect(store.resolve(path).readAsBytesSync(), _bytes(1));
      expect(src.readAsBytesSync(), _bytes(1));
      expect(originalNames(), ['$id.jpg']);
    });

    test('refuses to overwrite and keeps the old bytes', () async {
      final id = newPageId(Random(1));
      await store.importOriginal(source(1), id: id, extension: 'jpg');
      await expectLater(
        store.importOriginal(source(2), id: id, extension: 'jpg'),
        throwsStateError,
      );
      expect(store.resolve('originals/$id.jpg').readAsBytesSync(), _bytes(1));
      expect(originalNames(), ['$id.jpg']);
    });

    test('rejects invalid id and extension', () async {
      final id = newPageId(Random(1));
      for (final ext in ['', 'abcdef', 'j/g', '..', 'jp g']) {
        await expectLater(
          store.importOriginal(source(1), id: id, extension: ext),
          throwsArgumentError,
          reason: ext,
        );
      }
      await expectLater(
        store.importOriginal(source(1), id: '../x', extension: 'jpg'),
        throwsArgumentError,
      );
    });

    test('a failed copy leaves no partial file and rethrows', () async {
      final id = newPageId(Random(1));
      final missing = File('${sources.path}/missing.jpg');
      await expectLater(
        store.importOriginal(missing, id: id, extension: 'jpg'),
        throwsA(isA<FileSystemException>()),
      );
      final dir = Directory('${root.path}/originals');
      expect(dir.existsSync() ? dir.listSync() : <FileSystemEntity>[], isEmpty);
    });
  });

  group('resolve', () {
    test('maps a valid relative path under root', () {
      final id = newPageId(Random(1));
      expect(
        store.resolve('originals/$id.jpg').path,
        '${root.path}/originals/$id.jpg',
      );
    });

    test('rejects traversal and non-canonical paths', () {
      for (final path in [
        '../x',
        '/etc/passwd',
        'originals/../x.jpg',
        'session.json',
        'originals/${newPageId(Random(1))}.jpg.part',
      ]) {
        expect(() => store.resolve(path), throwsArgumentError, reason: path);
      }
    });
  });

  group('AC-1 reorder and delete', () {
    test(
      'keeps original bytes and cleans the deleted page after save',
      () async {
        final p1 = await importPage(1);
        final p2 = await importPage(2);
        final p3 = await importPage(3);
        var session = ScanSession(pages: [p1, p2, p3]);
        await store.save(session);

        session = session.moved(2, 0);
        expect(session.pages.map((p) => p.id), [p3.id, p1.id, p2.id]);
        session = session.removed(session.pages[1].id);
        expect(session.pages.map((p) => p.id), [p3.id, p2.id]);

        // Nothing is cleaned before the session is saved.
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);
        await store.save(session);

        expect(store.resolve(p3.originalPath).readAsBytesSync(), _bytes(3));
        expect(store.resolve(p2.originalPath).readAsBytesSync(), _bytes(2));
        expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      },
    );

    test('retake cleans the replaced original only after save', () async {
      final p1 = await importPage(1);
      await store.save(ScanSession(pages: [p1]));
      final retake = await importPage(2);
      final session = ScanSession(pages: [p1]).replaced(p1.id, retake);
      expect(store.resolve(p1.originalPath).existsSync(), isTrue);
      await store.save(session);
      expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      expect(store.resolve(retake.originalPath).readAsBytesSync(), _bytes(2));
    });

    test('never deletes an imported original that was never saved', () async {
      final p1 = await importPage(1);
      await store.save(ScanSession(pages: [p1]));
      final pending = await importPage(2);
      await store.save(ScanSession(pages: [p1]));
      expect(store.resolve(pending.originalPath).existsSync(), isTrue);
    });
  });

  group('AC-2 reload', () {
    test('a new store on the same root restores pages and edits', () async {
      final p1 = await importPage(1);
      final p2 = await importPage(2);
      final session = ScanSession(
        pages: [p1.withQuad(_skewed).rotatedClockwise(), p2],
      );
      await store.save(session);

      final result = await SessionStore(root).load();
      expect(result, isA<SessionLoaded>());
      final loaded = (result as SessionLoaded).session;
      expect(loaded.pages.map((p) => p.id), [p1.id, p2.id]);
      expect(loaded.pages.map((p) => p.originalPath), [
        p1.originalPath,
        p2.originalPath,
      ]);
      expect(loaded.pages[0].quad, _skewed);
      expect(loaded.pages[0].quarterTurns, 1);
      expect(loaded.pages[1].quad, PageQuad.fullFrame);
      expect(loaded.pages[1].quarterTurns, 0);
      expect(File('${root.path}/session.json.tmp').existsSync(), isFalse);
    });

    test('no manifest yet is empty', () async {
      expect(await store.load(), isA<SessionEmpty>());
    });

    test('load cleans orphan originals and .part files', () async {
      final p1 = await importPage(1);
      await store.save(ScanSession(pages: [p1]));
      final orphan = await importPage(2);
      final part = File('${root.path}/originals/${newPageId()}.jpg.part')
        ..writeAsBytesSync(_bytes(9));

      final fresh = SessionStore(root);
      expect(await fresh.load(), isA<SessionLoaded>());
      expect(store.resolve(orphan.originalPath).existsSync(), isFalse);
      expect(part.existsSync(), isFalse);
      expect(store.resolve(p1.originalPath).readAsBytesSync(), _bytes(1));
    });

    test('originals remembered by load are cleaned by the next save', () async {
      final p1 = await importPage(1);
      final p2 = await importPage(2);
      await store.save(ScanSession(pages: [p1, p2]));

      final fresh = SessionStore(root);
      final loaded = (await fresh.load() as SessionLoaded).session;
      await fresh.save(loaded.removed(p1.id));
      expect(fresh.resolve(p1.originalPath).existsSync(), isFalse);
      expect(fresh.resolve(p2.originalPath).existsSync(), isTrue);
    });
  });

  group('AC-3 unrecoverable manifest', () {
    Future<void> expectUnrecoverable(String content) async {
      final p1 = await importPage(1);
      final orphan = await importPage(2);
      final before = originalBytes();
      manifest().writeAsStringSync(content);

      final result = await SessionStore(root).load();
      expect(result, isA<SessionUnrecoverable>());
      final copy = File(
        '${root.path}/${(result as SessionUnrecoverable).corruptCopyPath}',
      );
      expect(copy.readAsStringSync(), content);
      expect(corruptCopies(), hasLength(1));
      expect(manifest().existsSync(), isFalse);
      expect(originalBytes(), before);
      expect(store.resolve(p1.originalPath).existsSync(), isTrue);
      expect(store.resolve(orphan.originalPath).existsSync(), isTrue);
    }

    test('garbage manifest', () => expectUnrecoverable('{garbage'));

    test('schemaVersion 2', () {
      return expectUnrecoverable('{"schemaVersion":2,"pages":[]}');
    });

    test('manifest pointing to a missing original', () {
      final id = newPageId(Random(99));
      return expectUnrecoverable(
        '{"schemaVersion":1,"pages":[{"id":"$id",'
        '"original":"originals/$id.jpg",'
        '"quad":[0,0,1,0,1,1,0,1],"quarterTurns":0}]}',
      );
    });

    test('invalid UTF-8 manifest', () async {
      await importPage(1);
      manifest().writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
      expect(await store.load(), isA<SessionUnrecoverable>());
      expect(corruptCopies(), hasLength(1));
    });

    test('a second corruption does not overwrite the first copy', () async {
      manifest().writeAsStringSync('first');
      expect(await store.load(), isA<SessionUnrecoverable>());
      manifest().writeAsStringSync('second');
      expect(await store.load(), isA<SessionUnrecoverable>());
      final contents = corruptCopies().map((f) => f.readAsStringSync()).toList()
        ..sort();
      expect(contents, ['first', 'second']);
    });

    test(
      'a later new session never deletes the quarantined originals',
      () async {
        final lost = await importPage(1);
        manifest().writeAsStringSync('{garbage');
        expect(await store.load(), isA<SessionUnrecoverable>());

        final fresh = SessionStore(root);
        final kept = await importPage(2);
        await fresh.save(ScanSession(pages: [kept]));
        final reloaded = await SessionStore(root).load();

        expect(reloaded, isA<SessionLoaded>());
        expect(store.resolve(lost.originalPath).readAsBytesSync(), _bytes(1));
        expect(store.resolve(kept.originalPath).readAsBytesSync(), _bytes(2));
      },
    );
  });

  group('save', () {
    test(
      'missing original throws StateError and keeps the old manifest',
      () async {
        final p1 = await importPage(1);
        await store.save(ScanSession(pages: [p1]));
        final saved = manifest().readAsStringSync();

        final id = newPageId(Random(42));
        final ghost = ScanPage(id: id, originalPath: 'originals/$id.jpg');
        await expectLater(
          store.save(ScanSession(pages: [ghost])),
          throwsStateError,
        );
        expect(manifest().readAsStringSync(), saved);
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);
        expect(File('${root.path}/session.json.tmp').existsSync(), isFalse);
      },
    );

    test('invalid original path throws ArgumentError', () async {
      final bad = ScanPage(id: newPageId(), originalPath: '../x.jpg');
      await expectLater(
        store.save(ScanSession(pages: [bad])),
        throwsArgumentError,
      );
      expect(manifest().existsSync(), isFalse);
    });

    test(
      'a failed write keeps the saved set and removes the tmp file',
      () async {
        final p1 = await importPage(1);
        final p2 = await importPage(2);
        await store.save(ScanSession(pages: [p1, p2]));

        // A directory at the target makes the rename fail.
        manifest().deleteSync();
        Directory('${root.path}/session.json').createSync();
        await expectLater(
          store.save(ScanSession(pages: [p2])),
          throwsA(isA<FileSystemException>()),
        );
        expect(File('${root.path}/session.json.tmp').existsSync(), isFalse);
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);

        // The failed save did not forget p1: a later successful save cleans it.
        Directory('${root.path}/session.json').deleteSync();
        await store.save(ScanSession(pages: [p2]));
        expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      },
    );
  });

  group('(F-001) load failing with an I/O error', () {
    Future<void> expectOriginalsKept({required bool failRead}) async {
      final a = await importPage(1);
      final b = await importPage(2);
      await store.save(ScanSession(pages: [a, b]));
      final savedManifest = manifest().readAsBytesSync();
      if (!failRead) {
        // Undecodable, so load quarantines it and the rename fails.
        manifest().writeAsStringSync('{garbage');
      }
      final onDisk = manifest().readAsBytesSync();
      final savedOriginals = originalBytes();

      final broken = SessionStore(root);
      await _withFailingManifest(
        () => expectLater(broken.load(), throwsA(isA<FileSystemException>())),
        failRead: failRead,
      );
      final c = await importPage(3);
      await expectLater(broken.save(ScanSession(pages: [c])), throwsStateError);
      expect(manifest().readAsBytesSync(), onDisk);
      expect(File('${root.path}/session.json.tmp').existsSync(), isFalse);

      final next = await SessionStore(root).load();
      if (failRead) {
        expect(next, isA<SessionLoaded>());
        final pages = (next as SessionLoaded).session.pages;
        expect(pages.map((p) => p.id), [a.id, b.id]);
        expect(manifest().readAsBytesSync(), savedManifest);
      } else {
        expect(next, isA<SessionUnrecoverable>());
      }
      for (final entry in savedOriginals.entries) {
        expect(File(entry.key).readAsBytesSync(), entry.value);
      }
    }

    test('(F-001) unreadable manifest: save refuses and A,B survive', () {
      return expectOriginalsKept(failRead: true);
    });

    test('(F-001) failed quarantine rename: save refuses, originals kept', () {
      return expectOriginalsKept(failRead: false);
    });

    test('(F-001) a store that loaded successfully may save', () async {
      final a = await importPage(1);
      await store.save(ScanSession(pages: [a]));
      final fresh = SessionStore(root);
      expect(await fresh.load(), isA<SessionLoaded>());
      final b = await importPage(2);
      await fresh.save(ScanSession(pages: [a, b]));
      expect(manifest().readAsStringSync(), contains(b.id));
    });

    test('(F-001) after quarantine the same store never deletes the '
        'quarantined originals', () async {
      final lost = await importPage(1);
      await store.save(ScanSession(pages: [lost]));
      manifest().writeAsStringSync('{garbage');
      expect(await store.load(), isA<SessionUnrecoverable>());
      final kept = await importPage(2);
      await store.save(ScanSession(pages: [kept]));
      expect(store.resolve(lost.originalPath).readAsBytesSync(), _bytes(1));
    });
  });

  group('(F-019) importOriginal and load', () {
    test('(F-019) overlapping calls never lose the imported file', () async {
      final a = await importPage(1);
      await store.save(ScanSession(pages: [a]));
      final fresh = SessionStore(root);

      final loadDone = Completer<void>();
      final loading = fresh.load().whenComplete(loadDone.complete);
      final importing = fresh.importOriginal(
        _PausedCopySource(source(2), loadDone.future),
        id: newPageId(Random(77)),
        extension: 'jpg',
      );
      expect(await loading, isA<SessionLoaded>());
      final path = await importing;
      expect(fresh.resolve(path).readAsBytesSync(), _bytes(2));
      expect(store.resolve(a.originalPath).readAsBytesSync(), _bytes(1));
    });
  });
}
