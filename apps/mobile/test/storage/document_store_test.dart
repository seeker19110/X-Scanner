import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/storage/document_store.dart';

final PageQuad _skewed = PageQuad(
  topLeft: const Point<double>(0.1, 0.05),
  topRight: const Point<double>(0.93, 0.12),
  bottomRight: const Point<double>(0.88, 0.97),
  bottomLeft: const Point<double>(0.02, 0.9),
);

final DateTime _created = DateTime.utc(2026, 10, 12, 8, 30);

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
      throw UnsupportedError('not used by DocumentStore.load');
}

/// Runs [body] with every `document.json` failing as [_FailingManifest].
Future<T> _withFailingManifest<T>(
  Future<T> Function() body, {
  required bool failRead,
}) {
  final real = _RealIO();
  return IOOverrides.runZoned(
    body,
    createFile: (path) => path.endsWith('/document.json')
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
      throw UnsupportedError('not used by DocumentStore.importOriginal');
}

void main() {
  final docId = newPageId(Random(1000));
  late Directory tmp;
  late Directory dir;
  late Directory sources;
  late DocumentStore store;
  var seed = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('document_store_test');
    dir = Directory('${tmp.path}/documents/$docId')
      ..createSync(recursive: true);
    sources = Directory('${tmp.path}/sources')..createSync();
    store = DocumentStore(dir);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// This folder's document with [pages]; [id] overrides the document id.
  ScanDocument doc(List<ScanPage> pages, {String? id}) => ScanDocument(
    id: id ?? docId,
    title: 'Receipt',
    createdAt: _created,
    updatedAt: _created,
    pages: pages,
  );

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

  File manifest() => File('${dir.path}/document.json');

  List<String> originalNames() =>
      Directory('${dir.path}/originals')
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .toList()
        ..sort();

  Map<String, List<int>> originalBytes() => {
    for (final f in Directory(
      '${dir.path}/originals',
    ).listSync().whereType<File>())
      f.path: f.readAsBytesSync(),
  };

  /// Every entity under the document folder with its bytes (null for
  /// directories), to prove that nothing was created, renamed or deleted.
  Map<String, List<int>?> snapshot() => {
    for (final e in dir.listSync(recursive: true))
      e.path: e is File ? e.readAsBytesSync() : null,
  };

  List<File> corruptCopies() => dir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'document\.corrupt-\d+\.json$').hasMatch(f.path))
      .toList();

  group('constructor', () {
    test('exposes the folder name as docId', () {
      expect(store.docId, docId);
      expect(store.dir.path, dir.path);
    });

    test('rejects a folder name that is not a valid id', () {
      for (final name in ['not-an-id', '$docId.part', docId.toUpperCase()]) {
        expect(
          () => DocumentStore(Directory('${tmp.path}/documents/$name')),
          throwsArgumentError,
          reason: name,
        );
      }
    });
  });

  group('importOriginal', () {
    test('refuses a document folder that does not exist', () async {
      final missing = DocumentStore(
        Directory('${tmp.path}/documents/${newPageId(Random(2000))}'),
      );
      await expectLater(
        missing.importOriginal(
          source(1),
          id: newPageId(Random(1)),
          extension: 'jpg',
        ),
        throwsStateError,
      );
      expect(missing.dir.existsSync(), isFalse);
    });

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
      final originals = Directory('${dir.path}/originals');
      expect(
        originals.existsSync() ? originals.listSync() : <FileSystemEntity>[],
        isEmpty,
      );
    });
  });

  group('resolve', () {
    test('maps a valid relative path under the document folder', () {
      final id = newPageId(Random(1));
      expect(
        store.resolve('originals/$id.jpg').path,
        '${dir.path}/originals/$id.jpg',
      );
    });

    test('rejects traversal and non-canonical paths', () {
      for (final path in [
        '../x',
        '/etc/passwd',
        'originals/../x.jpg',
        'document.json',
        '../$docId/originals/${newPageId(Random(1))}.jpg',
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
        await store.save(doc([p1, p2, p3]));

        // Nothing is cleaned before the document is saved.
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);
        await store.save(doc([p3, p2]));

        expect(store.resolve(p3.originalPath).readAsBytesSync(), _bytes(3));
        expect(store.resolve(p2.originalPath).readAsBytesSync(), _bytes(2));
        expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      },
    );

    test('retake cleans the replaced original only after save', () async {
      final p1 = await importPage(1);
      await store.save(doc([p1]));
      final retake = await importPage(2);
      expect(store.resolve(p1.originalPath).existsSync(), isTrue);
      await store.save(doc([retake]));
      expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      expect(store.resolve(retake.originalPath).readAsBytesSync(), _bytes(2));
    });

    test('never deletes an imported original that was never saved', () async {
      final p1 = await importPage(1);
      await store.save(doc([p1]));
      final pending = await importPage(2);
      await store.save(doc([p1]));
      expect(store.resolve(pending.originalPath).existsSync(), isTrue);
    });
  });

  group('AC-2 reload', () {
    test('a new store on the same folder restores the document', () async {
      final p1 = await importPage(1);
      final p2 = await importPage(2);
      await store.save(doc([p1.withQuad(_skewed).rotatedClockwise(), p2]));

      final result = await DocumentStore(dir).load();
      expect(result, isA<DocumentLoaded>());
      final loaded = (result as DocumentLoaded).document;
      expect(loaded.id, docId);
      expect(loaded.title, 'Receipt');
      expect(loaded.createdAt, _created);
      expect(loaded.pages.map((p) => p.id), [p1.id, p2.id]);
      expect(loaded.pages.map((p) => p.originalPath), [
        p1.originalPath,
        p2.originalPath,
      ]);
      expect(loaded.pages[0].quad, _skewed);
      expect(loaded.pages[0].quarterTurns, 1);
      expect(loaded.pages[0].revision, 2);
      expect(loaded.pages[1].quad, PageQuad.fullFrame);
      expect(loaded.pages[1].revision, 0);
      expect(File('${dir.path}/document.json.tmp').existsSync(), isFalse);
    });

    test('keeps a Vietnamese title with emoji byte for byte (UTF-8)', () async {
      const title = 'Hoá đơn tiền điện tháng 10 · Đà Nẵng 🧾';
      await store.save(
        ScanDocument(
          id: docId,
          title: title,
          createdAt: _created,
          updatedAt: _created,
        ),
      );

      final result = await DocumentStore(dir).load();
      expect((result as DocumentLoaded).document.title, title);
      expect(
        File('${dir.path}/document.json').readAsStringSync(),
        contains(title),
        reason: 'stored as UTF-8 text, not escaped or re-encoded',
      );
    });

    test('load cleans orphan originals and .part files', () async {
      final p1 = await importPage(1);
      await store.save(doc([p1]));
      final orphan = await importPage(2);
      final part = File('${dir.path}/originals/${newPageId()}.jpg.part')
        ..writeAsBytesSync(_bytes(9));

      expect(await DocumentStore(dir).load(), isA<DocumentLoaded>());
      expect(store.resolve(orphan.originalPath).existsSync(), isFalse);
      expect(part.existsSync(), isFalse);
      expect(store.resolve(p1.originalPath).readAsBytesSync(), _bytes(1));
    });

    test('originals remembered by load are cleaned by the next save', () async {
      final p1 = await importPage(1);
      final p2 = await importPage(2);
      await store.save(doc([p1, p2]));

      final fresh = DocumentStore(dir);
      expect(await fresh.load(), isA<DocumentLoaded>());
      await fresh.save(doc([p2]));
      expect(fresh.resolve(p1.originalPath).existsSync(), isFalse);
      expect(fresh.resolve(p2.originalPath).existsSync(), isTrue);
    });
  });

  group('missing document.json', () {
    test('is unrecoverable without a copy and changes nothing', () async {
      final p1 = await importPage(1);
      final orphan = File('${dir.path}/originals/${newPageId()}.jpg.part')
        ..writeAsBytesSync(_bytes(9));
      final before = snapshot();

      final fresh = DocumentStore(dir);
      final result = await fresh.load();
      expect(result, isA<DocumentUnrecoverable>());
      expect((result as DocumentUnrecoverable).corruptCopyPath, isNull);
      expect(snapshot(), before);
      expect(orphan.existsSync(), isTrue);

      // There is no file to replace, so a later save is allowed.
      await fresh.save(doc([p1]));
      final reloaded = await DocumentStore(dir).load();
      expect(reloaded, isA<DocumentLoaded>());
      expect((reloaded as DocumentLoaded).document.pages.single.id, p1.id);
    });
  });

  group('AC-3 unrecoverable manifest', () {
    Future<void> expectUnrecoverable(String content) async {
      final p1 = await importPage(1);
      final orphan = await importPage(2);
      final before = originalBytes();
      manifest().writeAsStringSync(content);

      final result = await DocumentStore(dir).load();
      expect(result, isA<DocumentUnrecoverable>());
      final copyPath = (result as DocumentUnrecoverable).corruptCopyPath;
      expect(copyPath, matches(RegExp(r'^document\.corrupt-\d+\.json$')));
      expect(File('${dir.path}/$copyPath').readAsStringSync(), content);
      expect(corruptCopies(), hasLength(1));
      expect(manifest().existsSync(), isFalse);
      expect(originalBytes(), before);
      expect(store.resolve(p1.originalPath).existsSync(), isTrue);
      expect(store.resolve(orphan.originalPath).existsSync(), isTrue);
    }

    test('garbage manifest', () => expectUnrecoverable('{garbage'));

    test('schemaVersion 1 (session layout) is not a document', () {
      return expectUnrecoverable('{"schemaVersion":1,"pages":[]}');
    });

    test('manifest pointing to a missing original', () {
      final id = newPageId(Random(99));
      final json = encodeDocument(
        doc([ScanPage(id: id, originalPath: 'originals/$id.jpg')]),
      );
      return expectUnrecoverable(json);
    });

    test('document id different from the folder name', () {
      return expectUnrecoverable(
        encodeDocument(doc(const [], id: newPageId(Random(5)))),
      );
    });

    test('invalid UTF-8 manifest', () async {
      await importPage(1);
      manifest().writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
      expect(await store.load(), isA<DocumentUnrecoverable>());
      expect(corruptCopies(), hasLength(1));
    });

    test('a second corruption does not overwrite the first copy', () async {
      manifest().writeAsStringSync('first');
      expect(await store.load(), isA<DocumentUnrecoverable>());
      manifest().writeAsStringSync('second');
      expect(await store.load(), isA<DocumentUnrecoverable>());
      final contents = corruptCopies().map((f) => f.readAsStringSync()).toList()
        ..sort();
      expect(contents, ['first', 'second']);
    });

    test(
      'a later new document never deletes the quarantined originals',
      () async {
        final lost = await importPage(1);
        manifest().writeAsStringSync('{garbage');
        expect(await store.load(), isA<DocumentUnrecoverable>());

        final fresh = DocumentStore(dir);
        final kept = await importPage(2);
        await fresh.save(doc([kept]));
        final reloaded = await DocumentStore(dir).load();

        expect(reloaded, isA<DocumentLoaded>());
        expect(store.resolve(lost.originalPath).readAsBytesSync(), _bytes(1));
        expect(store.resolve(kept.originalPath).readAsBytesSync(), _bytes(2));
      },
    );
  });

  group('AC-4 newer schema', () {
    test('a later load that needs an update forgets what an earlier load '
        'referenced, so a save cannot delete those originals', () async {
      final a = await importPage(1);
      await store.save(doc([a]));
      final fresh = DocumentStore(dir);
      expect(await fresh.load(), isA<DocumentLoaded>());
      manifest().writeAsStringSync('{"schemaVersion":3}');
      expect(await fresh.load(), isA<DocumentNeedsUpdate>());
      manifest().deleteSync();
      await fresh.save(doc([]));
      expect(fresh.resolve(a.originalPath).existsSync(), isTrue);
    });

    test('needs an update: nothing renamed or deleted, save refuses', () async {
      final p1 = await importPage(1);
      await store.save(doc([p1]));
      final orphan = await importPage(2);
      manifest().writeAsStringSync('{"schemaVersion":3,"future":true}');
      final before = snapshot();

      final fresh = DocumentStore(dir);
      expect(await fresh.load(), isA<DocumentNeedsUpdate>());
      expect(snapshot(), before);
      expect(corruptCopies(), isEmpty);
      expect(store.resolve(orphan.originalPath).existsSync(), isTrue);

      await expectLater(fresh.save(doc([p1])), throwsStateError);
      await expectLater(fresh.save(doc(const [])), throwsStateError);
      expect(snapshot(), before);
    });
  });

  group('save', () {
    test(
      'missing original throws StateError and keeps the old manifest',
      () async {
        final p1 = await importPage(1);
        await store.save(doc([p1]));
        final saved = manifest().readAsStringSync();

        final id = newPageId(Random(42));
        final ghost = ScanPage(id: id, originalPath: 'originals/$id.jpg');
        await expectLater(store.save(doc([ghost])), throwsStateError);
        expect(manifest().readAsStringSync(), saved);
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);
        expect(File('${dir.path}/document.json.tmp').existsSync(), isFalse);
      },
    );

    test('invalid original path throws ArgumentError', () async {
      final bad = ScanPage(id: newPageId(), originalPath: '../x.jpg');
      await expectLater(store.save(doc([bad])), throwsArgumentError);
      expect(manifest().existsSync(), isFalse);
    });

    test('a document of another folder throws ArgumentError', () async {
      final p1 = await importPage(1);
      await store.save(doc([p1]));
      final before = snapshot();
      await expectLater(
        store.save(doc([p1], id: newPageId(Random(5)))),
        throwsArgumentError,
      );
      expect(snapshot(), before);

      final empty = DocumentStore(
        Directory('${tmp.path}/documents/${newPageId(Random(6))}'),
      );
      await expectLater(empty.save(doc(const [])), throwsArgumentError);
      expect(empty.dir.existsSync(), isFalse);
    });

    test(
      'a failed write keeps the saved set and removes the tmp file',
      () async {
        final p1 = await importPage(1);
        final p2 = await importPage(2);
        await store.save(doc([p1, p2]));

        // A directory at the target makes the rename fail.
        manifest().deleteSync();
        Directory('${dir.path}/document.json').createSync();
        await expectLater(
          store.save(doc([p2])),
          throwsA(isA<FileSystemException>()),
        );
        expect(File('${dir.path}/document.json.tmp').existsSync(), isFalse);
        expect(store.resolve(p1.originalPath).existsSync(), isTrue);

        // The failed save did not forget p1: a later successful save cleans it.
        Directory('${dir.path}/document.json').deleteSync();
        await store.save(doc([p2]));
        expect(store.resolve(p1.originalPath).existsSync(), isFalse);
      },
    );
  });

  group('(F-001) load failing with an I/O error', () {
    Future<void> expectOriginalsKept({required bool failRead}) async {
      final a = await importPage(1);
      final b = await importPage(2);
      await store.save(doc([a, b]));
      final savedManifest = manifest().readAsBytesSync();
      if (!failRead) {
        // Undecodable, so load quarantines it and the rename fails.
        manifest().writeAsStringSync('{garbage');
      }
      final onDisk = manifest().readAsBytesSync();
      final savedOriginals = originalBytes();

      final broken = DocumentStore(dir);
      await _withFailingManifest(
        () => expectLater(broken.load(), throwsA(isA<FileSystemException>())),
        failRead: failRead,
      );
      final c = await importPage(3);
      await expectLater(broken.save(doc([c])), throwsStateError);
      expect(manifest().readAsBytesSync(), onDisk);
      expect(File('${dir.path}/document.json.tmp').existsSync(), isFalse);

      final next = await DocumentStore(dir).load();
      if (failRead) {
        expect(next, isA<DocumentLoaded>());
        final pages = (next as DocumentLoaded).document.pages;
        expect(pages.map((p) => p.id), [a.id, b.id]);
        expect(manifest().readAsBytesSync(), savedManifest);
      } else {
        expect(next, isA<DocumentUnrecoverable>());
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
      await store.save(doc([a]));
      final fresh = DocumentStore(dir);
      expect(await fresh.load(), isA<DocumentLoaded>());
      final b = await importPage(2);
      await fresh.save(doc([a, b]));
      expect(manifest().readAsStringSync(), contains(b.id));
    });

    test('(F-001) after quarantine the same store never deletes the '
        'quarantined originals', () async {
      final lost = await importPage(1);
      await store.save(doc([lost]));
      manifest().writeAsStringSync('{garbage');
      expect(await store.load(), isA<DocumentUnrecoverable>());
      final kept = await importPage(2);
      await store.save(doc([kept]));
      expect(store.resolve(lost.originalPath).readAsBytesSync(), _bytes(1));
    });
  });

  group('(F-019) importOriginal and load', () {
    test('(F-019) overlapping calls never lose the imported file', () async {
      final a = await importPage(1);
      await store.save(doc([a]));
      final fresh = DocumentStore(dir);

      final loadDone = Completer<void>();
      final loading = fresh.load().whenComplete(loadDone.complete);
      final importing = fresh.importOriginal(
        _PausedCopySource(source(2), loadDone.future),
        id: newPageId(Random(77)),
        extension: 'jpg',
      );
      expect(await loading, isA<DocumentLoaded>());
      final path = await importing;
      expect(fresh.resolve(path).readAsBytesSync(), _bytes(2));
      expect(store.resolve(a.originalPath).readAsBytesSync(), _bytes(1));
    });
  });
}
