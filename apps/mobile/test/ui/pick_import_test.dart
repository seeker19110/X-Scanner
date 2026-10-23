import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/storage/document_store.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/p1_migration.dart';
import 'package:x_scanner/storage/pending_pick_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/pick_import.dart';

/// [PageSource] whose lost photo is scripted; records probes and discards.
class _Source implements PageSource {
  String? lost;
  int probes = 0;
  final List<String> discarded = [];

  @override
  Future<String?> capture() async => null;

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<String?> retrieveLost() async {
    probes++;
    return lost;
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}

/// [DocumentStore] whose save can fail like a full disk.
class _FlakyStore extends DocumentStore {
  _FlakyStore(super.dir);

  bool failSave = false;

  @override
  Future<void> save(ScanDocument document) => failSave
      ? Future<void>.error(const FileSystemException('disk full'))
      : super.save(document);
}

void main() {
  late Directory tmp;
  late Directory cache;
  late Directory documents;
  late LibraryStore library;
  late PendingPickStore pending;
  late _Source source;
  late PickImporter importer;
  final created = DateTime.utc(2026, 10, 1, 8);
  final now = DateTime.utc(2026, 10, 23, 9);
  var n = 0;

  /// Bytes the fake decoder accepts start with 1; anything else is junk.
  Future<Uint8List> decode(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty || bytes.first != 1) {
      throw const FormatException('not an image');
    }
    return Uint8List.fromList([9, bytes.length]);
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('pick_import_test');
    cache = Directory('${tmp.path}/cache')..createSync();
    documents = Directory('${tmp.path}/documents');
    library = LibraryStore(documents);
    pending = PendingPickStore(
      dir: Directory('${tmp.path}/pending-pick'),
      cacheDir: cache,
      maxBytes: 64,
    );
    source = _Source();
    importer = PickImporter(
      pending: pending,
      source: source,
      decode: decode,
      now: () => now,
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// A picker copy in the cache: [ok] bytes decode, others do not.
  String picked({bool ok = true, int size = 8}) {
    n++;
    final bytes = List<int>.generate(size, (i) => i == 0 ? (ok ? 1 : 0) : n);
    return (File('${cache.path}/pick$n.jpg')..writeAsBytesSync(bytes)).path;
  }

  Future<(DocumentStore, ScanDocument)> newDocument({
    int pages = 0,
    DocumentStore Function(Directory dir)? storeOf,
  }) async {
    final id = newPageId();
    final empty = ScanDocument(
      id: id,
      title: 'A',
      createdAt: created,
      updatedAt: created,
    );
    await library.create(empty);
    final store =
        storeOf?.call(Directory('${documents.path}/$id')) ?? library.open(id);
    await store.load();
    var document = empty;
    for (var i = 0; i < pages; i++) {
      final pageId = newPageId();
      final relative = await store.importOriginal(
        File(picked()),
        id: pageId,
        extension: 'jpg',
      );
      document = ScanDocument(
        id: id,
        title: 'A',
        createdAt: created,
        updatedAt: created,
        pages: [
          ...document.pages,
          ScanPage(id: pageId, originalPath: relative),
        ],
      );
    }
    await store.save(document);
    return (store, document);
  }

  Future<PendingPick> remembered(
    String docId, {
    String? replace,
    bool ok = true,
    int size = 8,
    bool createOwner = false,
  }) async {
    final pick = await pending.begin(
      docId: docId,
      pageId: newPageId(),
      replacePageId: replace,
      createOwner: createOwner,
    );
    return pending.remember(pick, picked(ok: ok, size: size));
  }

  Directory? rejectedDir() {
    final matches = tmp.listSync().whereType<Directory>().where(
      (d) => d.path.contains('pending-pick.rejected-'),
    );
    return matches.isEmpty ? null : matches.single;
  }

  group('importInto', () {
    test('adds the page, saves updatedAt, discards the cache copy and '
        'completes', () async {
      final (store, document) = await newDocument();
      final pick = await remembered(document.id);
      final cachePath = '${cache.path}/${pick.cacheRelativePath}';
      final bytes = File(cachePath).readAsBytesSync();

      final result = await importer.importInto(pick, store, document);

      expect(result, isA<PickImported>());
      final saved = (result as PickImported).document;
      expect(saved.pages.single.id, pick.pageId);
      expect(saved.updatedAt, now);
      expect(saved.title, 'A');
      expect(result.preview, isNotNull);
      expect(
        store.resolve(saved.pages.single.originalPath).readAsBytesSync(),
        bytes,
      );
      final reloaded = await store.load();
      expect(
        (reloaded as DocumentLoaded).document.pages.single.id,
        pick.pageId,
      );
      expect(source.discarded, [cachePath]);
      expect(await pending.load(), isNull);
    });

    test('a retake replaces the page in place', () async {
      final (store, document) = await newDocument(pages: 3);
      final old = document.pages[1];
      final pick = await remembered(document.id, replace: old.id);

      final result = await importer.importInto(pick, store, document);

      final pages = (result as PickImported).document.pages;
      expect(
        [for (final p in pages) p.id],
        [document.pages[0].id, pick.pageId, document.pages[2].id],
      );
      expect(store.resolve(old.originalPath).existsSync(), isFalse);
      expect(await pending.load(), isNull);
    });

    test('a page already committed is only cleaned up', () async {
      final (store, document) = await newDocument();
      final pick = await remembered(document.id);
      final staged = await pending.stage(pick);
      final relative = await store.importOriginal(
        staged,
        id: pick.pageId,
        extension: pick.extension!,
      );
      final committed = ScanDocument(
        id: document.id,
        title: 'A',
        createdAt: created,
        updatedAt: created,
        pages: [ScanPage(id: pick.pageId, originalPath: relative)],
      );
      await store.save(committed);

      final result = await importer.importInto(pick, store, committed);

      expect((result as PickImported).document, same(committed));
      expect(await pending.load(), isNull);
      expect(source.discarded, hasLength(1));
    });

    test('an undecodable image is retained aside and the document is '
        'unchanged', () async {
      final (store, document) = await newDocument(pages: 1);
      final pick = await remembered(document.id, ok: false);
      final bytes = File('${cache.path}/${pick.cacheRelativePath}')
          .readAsBytesSync();

      final result = await importer.importInto(pick, store, document);

      expect(result, isA<PickRejected>());
      expect(await pending.load(), isNull);
      final kept = rejectedDir()!;
      expect(File('${kept.path}/original.jpg').readAsBytesSync(), bytes);
      expect(source.discarded, isEmpty);
      final reloaded = await store.load() as DocumentLoaded;
      expect(reloaded.document.pages, hasLength(1));
    });

    test('an image over the size cap is retained aside', () async {
      final (store, document) = await newDocument();
      final pick = await remembered(document.id, size: 65);

      final result = await importer.importInto(pick, store, document);

      expect(result, isA<PickRejected>());
      expect(rejectedDir(), isNotNull);
      expect(await pending.load(), isNull);
    });

    test(
      'a retake whose page is gone is retained aside, not attached',
      () async {
        final (store, document) = await newDocument(pages: 1);
        final pick = await remembered(document.id, replace: newPageId());

        final result = await importer.importInto(pick, store, document);

        expect(result, isA<PickRejected>());
        final reloaded = await store.load() as DocumentLoaded;
        expect(reloaded.document.pages.single.id, document.pages.single.id);
      },
    );

    test('a failed save keeps the image pending, and a retry reuses the '
        'copied original', () async {
      late _FlakyStore flaky;
      final (_, document) = await newDocument(
        storeOf: (dir) => flaky = _FlakyStore(dir),
      );
      final pick = await remembered(document.id);
      flaky.failSave = true;

      expect(await importer.importInto(pick, flaky, document), isA<PickKept>());
      expect((await pending.load())?.pageId, pick.pageId);
      expect(source.discarded, isEmpty);

      flaky.failSave = false;
      final retry = await importer.importInto(pick, flaky, document);
      expect((retry as PickImported).document.pages.single.id, pick.pageId);
      expect(await pending.load(), isNull);
    });
  });

  group('recover', () {
    test('without a marker or a lost photo changes nothing', () async {
      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.none,
      );
      expect(source.probes, 1);
      expect(await pending.load(), isNull);
      expect(documents.existsSync(), isFalse);
    });

    test('a lost photo without a marker gets a new document', () async {
      source.lost = picked();
      final bytes = File(source.lost!).readAsBytesSync();

      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.added,
      );
      final entries = await library.list();
      final document = (entries.single as LibraryDocument).document;
      expect(document.title, defaultDocumentTitle(now.toLocal()));
      expect(document.createdAt, now);
      final store = library.open(document.id);
      expect(
        store.resolve(document.pages.single.originalPath).readAsBytesSync(),
        bytes,
      );
      expect(await pending.load(), isNull);
    });

    test('an undecodable lost photo creates no document', () async {
      source.lost = picked(ok: false);

      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.rejected,
      );
      expect(await library.list(), isEmpty);
      expect(rejectedDir(), isNotNull);
    });

    test(
      'a lost photo after a migration goes to the migrated document',
      () async {
        final (_, document) = await newDocument(pages: 2);
        source.lost = picked();

        expect(
          await importer.recover(library, MigrationDone(document.id)),
          PickRecovery.added,
        );
        final entries = await library.list();
        final saved = (entries.single as LibraryDocument).document;
        expect(saved.id, document.id);
        expect(saved.pages, hasLength(3));
      },
    );

    test('an empty marker with no lost photo is cancelled', () async {
      final (_, document) = await newDocument();
      await pending.begin(docId: document.id, pageId: newPageId());

      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.none,
      );
      expect(source.probes, 1);
      expect(await pending.load(), isNull);
    });

    test('a marker with a result goes to its owner without a probe', () async {
      final (_, other) = await newDocument();
      final (_, owner) = await newDocument();
      final pick = await remembered(owner.id);

      expect(
        await importer.recover(library, MigrationDone(other.id)),
        PickRecovery.added,
      );
      expect(source.probes, 0);
      final byId = {
        for (final e in await library.list())
          e.docId: (e as LibraryDocument).document,
      };
      expect(byId[owner.id]!.pages.single.id, pick.pageId);
      expect(byId[other.id]!.pages, isEmpty);
    });

    test('a marker whose owner is missing is retained aside', () async {
      await remembered(newPageId());

      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.rejected,
      );
      expect(await pending.load(), isNull);
      expect(rejectedDir(), isNotNull);
      expect(await library.list(), isEmpty);
    });

    test(
      'a stale {docId}.part left by a crash does not block recovery',
      () async {
        final pick = await remembered(newPageId(), createOwner: true);
        final part = Directory('${documents.path}/${pick.docId}.part')
          ..createSync(recursive: true);
        File('${part.path}/document.json').writeAsStringSync('{}');

        expect(
          await importer.recover(library, const MigrationNotNeeded()),
          PickRecovery.added,
        );
        expect(part.existsSync(), isFalse);
        final saved = (await library.list()).single as LibraryDocument;
        expect(saved.document.pages.single.id, pick.pageId);
        expect(await pending.load(), isNull);
      },
    );

    test('runs only once per importer', () async {
      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.none,
      );
      source.lost = picked();
      expect(
        await importer.recover(library, const MigrationNotNeeded()),
        PickRecovery.none,
      );
      expect(source.probes, 1);
    });
  });
}
