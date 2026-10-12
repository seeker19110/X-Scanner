import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/storage/document_store.dart';
import 'package:x_scanner/storage/library_store.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 1);

/// Synthetic bytes; no real images are used.
List<int> _bytes(int n) => List<int>.generate(64 + n, (i) => (i * 7 + n) % 256);

/// Gives access to the real [File] constructor inside an override zone.
final class _RealIO extends IOOverrides {}

/// A file whose [writeAsString] fails like a full disk.
class _FailingWrite implements File {
  _FailingWrite(this._real);

  final File _real;

  @override
  String get path => _real.path;

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => Future<File>.error(const FileSystemException('write failed'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used by LibraryStore.create');
}

void main() {
  late Directory tmp;
  late Directory root;
  late LibraryStore library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('library_store_test');
    root = Directory('${tmp.path}/documents');
    library = LibraryStore(root);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  ScanDocument doc(String id, {DateTime? updatedAt, List<ScanPage>? pages}) =>
      ScanDocument(
        id: id,
        title: 'Doc',
        createdAt: _t0,
        updatedAt: updatedAt ?? _t0,
        pages: pages ?? const [],
      );

  /// Writes a document folder by hand: [json] as `document.json` (none when
  /// null) and one original, so tests control exactly what is on disk.
  Directory writeFolder(String name, String? json) {
    final dir = Directory('${root.path}/$name')..createSync(recursive: true);
    if (json != null) {
      File('${dir.path}/document.json').writeAsStringSync(json);
    }
    Directory('${dir.path}/originals').createSync();
    File('${dir.path}/originals/${newPageId(Random(name.hashCode))}.jpg')
        .writeAsBytesSync(_bytes(name.length));
    return dir;
  }

  /// Writes a valid document whose folder name equals its id.
  Directory writeDocument(ScanDocument document) {
    final dir = writeFolder(document.id, null);
    File('${dir.path}/document.json')
        .writeAsStringSync(encodeDocument(document));
    return dir;
  }

  /// Every entity under [root] with its bytes (null for directories and
  /// links), to prove that nothing was created, renamed or deleted.
  Map<String, List<int>?> snapshot() => {
    for (final e in root.listSync(recursive: true, followLinks: false))
      e.path: e is File ? e.readAsBytesSync() : null,
  };

  String id(int n) => newPageId(Random(n));

  List<String> ids(List<LibraryEntry> entries) =>
      entries.map((e) => e.docId).toList();

  group('AC-10 list() isolates unreadable documents', () {
    test('a garbage manifest and a mismatched id are unreadable', () async {
      final a = doc(id(1));
      writeDocument(a);
      final b = id(2);
      writeFolder(b, '{garbage');
      final c = id(3);
      writeFolder(c, encodeDocument(doc(id(4))));
      final before = snapshot();

      final entries = await library.list();
      expect(entries, hasLength(3));
      expect(entries.first, isA<LibraryDocument>());
      expect(entries.first.docId, a.id);
      expect((entries.first as LibraryDocument).document.id, a.id);
      final rest = entries.skip(1).toList();
      expect(rest.every((e) => e is LibraryUnreadable), isTrue);
      expect(ids(rest), ([b, c]..sort()));
      expect(snapshot(), before);

      expect(await library.open(a.id).load(), isA<DocumentLoaded>());
    });

    test('invalid UTF-8 is unreadable', () async {
      writeFolder(id(1), null);
      File('${root.path}/${id(1)}/document.json')
          .writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
      final entries = await library.list();
      expect(entries.single, isA<LibraryUnreadable>());
    });

    test('a folder without document.json is unreadable', () async {
      writeFolder(id(1), null);
      final before = snapshot();
      final entries = await library.list();
      expect(entries.single, isA<LibraryUnreadable>());
      expect(entries.single.docId, id(1));
      expect(snapshot(), before);
    });

    test('a directory in place of document.json is unreadable', () async {
      final dir = writeFolder(id(1), null);
      Directory('${dir.path}/document.json').createSync();
      expect((await library.list()).single, isA<LibraryUnreadable>());
    });
  });

  group('AC-4 newer schema', () {
    test('is listed as needing an update and left untouched', () async {
      writeFolder(id(1), '{"schemaVersion":3,"anything":[1,2]}');
      final before = snapshot();
      final entries = await library.list();
      expect(entries.single, isA<LibraryNeedsUpdate>());
      expect(entries.single.docId, id(1));
      expect(snapshot(), before);
    });
  });

  group('list() skips', () {
    test('.part folders, files, other names and links', () async {
      final valid = doc(id(1));
      final target = writeDocument(valid);
      writeDocument(doc(id(2))).renameSync('${root.path}/${id(2)}.part');
      File('${root.path}/${id(3)}').writeAsStringSync('not a folder');
      writeFolder('not-an-id', encodeDocument(doc(id(4))));
      writeFolder(id(5).toUpperCase(), encodeDocument(doc(id(5))));

      final entries = await library.list();
      expect(ids(entries), [valid.id]);

      try {
        Link('${root.path}/${id(6)}').createSync(target.path);
      } on FileSystemException {
        markTestSkipped('this platform cannot create a directory link');
        return;
      }
      expect(ids(await library.list()), [valid.id]);
    });
  });

  group('list() order', () {
    test('newest first, ties by id, unreadable last by id', () async {
      final t1 = _t0.add(const Duration(hours: 1));
      final t2 = _t0.add(const Duration(hours: 2));
      final ids = [for (var n = 10; n < 15; n++) id(n)]..sort();
      // ids[0] < ids[1] < ... ; assign so that the expected order is not
      // simply the id order.
      writeDocument(doc(ids[0], updatedAt: t1));
      writeDocument(doc(ids[3], updatedAt: t2));
      writeDocument(doc(ids[1], updatedAt: t2));
      writeFolder(ids[4], '{garbage');
      writeFolder(ids[2], '{"schemaVersion":9}');

      final entries = await library.list();
      expect(entries.map((e) => e.docId), [
        ids[1],
        ids[3],
        ids[0],
        ids[2],
        ids[4],
      ]);
      expect(entries.take(3).every((e) => e is LibraryDocument), isTrue);
      expect(entries[3], isA<LibraryNeedsUpdate>());
      expect(entries[4], isA<LibraryUnreadable>());
    });

    test('a missing root is empty and is not created', () async {
      expect(await library.list(), isEmpty);
      expect(root.existsSync(), isFalse);
    });

    test('an empty root is empty', () async {
      root.createSync();
      expect(await library.list(), isEmpty);
    });
  });

  group('create', () {
    test('writes an empty document that lists and loads', () async {
      final document = doc(id(1));
      final store = await library.create(document);

      expect(store.docId, document.id);
      expect(store.dir.path, '${root.path}/${document.id}');
      expect(Directory('${root.path}/${document.id}.part').existsSync(), false);
      final json = File('${root.path}/${document.id}/document.json')
          .readAsStringSync();
      expect(json, encodeDocument(document));
      final decoded = decodeDocument(json) as DecodedDocument;
      expect(decoded.document.id, document.id);
      expect(decoded.document.title, document.title);
      expect(decoded.document.createdAt, document.createdAt);
      expect(decoded.document.updatedAt, document.updatedAt);

      final entries = await library.list();
      expect(entries.single, isA<LibraryDocument>());
      expect(entries.single.docId, document.id);

      final loaded = await store.load();
      expect(loaded, isA<DocumentLoaded>());
      expect((loaded as DocumentLoaded).document.pages, isEmpty);
    });

    test('a document with pages throws ArgumentError, creates nothing', () {
      final pageId = id(9);
      final document = doc(
        id(1),
        pages: [ScanPage(id: pageId, originalPath: 'originals/$pageId.jpg')],
      );
      expect(library.create(document), throwsArgumentError);
      expect(root.existsSync(), isFalse);
    });

    test(
      'an existing folder or .part throws StateError, changes nothing',
      () async {
        final taken = doc(id(1));
        writeFolder(taken.id, '{garbage');
        final partial = doc(id(2));
        Directory('${root.path}/${partial.id}.part').createSync();
        final asFile = doc(id(3));
        File('${root.path}/${asFile.id}').writeAsStringSync('x');
        final before = snapshot();

        for (final document in [taken, partial, asFile]) {
          await expectLater(library.create(document), throwsStateError);
        }
        expect(snapshot(), before);
      },
    );

    test('a root that is a file fails and is left unchanged', () async {
      // A file where the root should be makes every step fail.
      tmp.createSync();
      File(root.path).writeAsStringSync('not a folder');
      await expectLater(
        library.create(doc(id(1))),
        throwsA(isA<FileSystemException>()),
      );
      expect(File(root.path).readAsStringSync(), 'not a folder');
    });

    test('a failed manifest write removes the .part folder', () async {
      final document = doc(id(1));
      final real = _RealIO();
      await IOOverrides.runZoned(
        () => expectLater(
          library.create(document),
          throwsA(isA<FileSystemException>()),
        ),
        createFile: (path) => path.endsWith('.part/document.json')
            ? _FailingWrite(real.createFile(path))
            : real.createFile(path),
      );
      expect(root.existsSync(), isTrue);
      expect(root.listSync(), isEmpty);
    });
  });

  group('open', () {
    test('rejects an invalid id and does no I/O', () {
      for (final bad in ['bad', '../x', '${id(1)}.part', '']) {
        expect(() => library.open(bad), throwsArgumentError, reason: bad);
      }
      expect(root.existsSync(), isFalse);
    });

    test('returns a store for the document folder', () {
      final store = library.open(id(1));
      expect(store.docId, id(1));
      expect(store.dir.path, '${root.path}/${id(1)}');
      expect(root.existsSync(), isFalse);
    });
  });
}
