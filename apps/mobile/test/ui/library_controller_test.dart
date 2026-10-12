import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/p1_migration.dart';
import 'package:x_scanner/ui/library_controller.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 1, 8);

/// [LibraryStore] whose [list] fails like an unreadable folder while
/// [fail] is set, and counts its calls.
class _FlakyLibrary extends LibraryStore {
  _FlakyLibrary(super.root);

  bool fail = false;
  int lists = 0;

  @override
  Future<List<LibraryEntry>> list() async {
    lists++;
    if (fail) throw const FileSystemException('list failed');
    return super.list();
  }
}

void main() {
  late Directory tmp;
  late Directory root;
  late _FlakyLibrary library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('library_controller_test');
    root = Directory('${tmp.path}/documents');
    library = _FlakyLibrary(root);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  String id(int n) => newPageId(Random(n));

  /// Writes a valid document folder by hand.
  ScanDocument writeDocument(int n, {DateTime? updatedAt, String? title}) {
    final document = ScanDocument(
      id: id(n),
      title: title ?? 'Doc $n',
      createdAt: _t0,
      updatedAt: updatedAt ?? _t0,
    );
    Directory('${root.path}/${document.id}').createSync(recursive: true);
    File('${root.path}/${document.id}/document.json')
        .writeAsStringSync(encodeDocument(document));
    return document;
  }

  File manifestOf(String docId) => File('${root.path}/$docId/document.json');

  /// Every entity under [root] with its bytes, to prove nothing changed.
  Map<String, List<int>?> snapshot() => {
    for (final e in root.listSync(recursive: true, followLinks: false))
      e.path: e is File ? e.readAsBytesSync() : null,
  };

  List<String> ids(List<LibraryEntry> entries) =>
      entries.map((e) => e.docId).toList();

  test('titleErrorOf classifies typed titles', () {
    expect(titleErrorOf(''), TitleError.empty);
    expect(titleErrorOf('   \t '), TitleError.empty);
    expect(titleErrorOf('a' * 121), TitleError.tooLong);
    // 121 code points, 242 UTF-16 units.
    expect(titleErrorOf('😀' * 121), TitleError.tooLong);
    expect(titleErrorOf('😀' * 120), isNull);
    expect(titleErrorOf('  ${'a' * 120}  '), isNull, reason: 'trimmed first');
    expect(titleErrorOf('a\nb'), TitleError.invalid);
    expect(titleErrorOf('a\u007fb'), TitleError.invalid);
    expect(titleErrorOf(' Hoá đơn '), isNull);
  });

  test('starts loading and without a migration step lists', () async {
    final controller = LibraryController(library: library);
    expect(controller.status, LibraryStatus.loading);
    expect(controller.entries, isEmpty);
    await controller.start();
    expect(controller.status, LibraryStatus.ready);
    expect(controller.migrating, isFalse);
    expect(controller.entries, isEmpty);
    expect(controller.takeNotice(), isNull);
  });

  test('start migrates then lists', () async {
    final a = writeDocument(1, updatedAt: _t0);
    final b = writeDocument(2, updatedAt: _t0.add(const Duration(hours: 1)));
    final hold = Completer<MigrationOutcome>();
    var listsDuringMigration = -1;
    late final LibraryController controller;
    controller = LibraryController(
      library: library,
      migrate: () {
        expect(controller.migrating, isTrue);
        listsDuringMigration = library.lists;
        return hold.future;
      },
    );
    final started = controller.start();
    await pumpEventQueue();
    expect(controller.status, LibraryStatus.loading);
    expect(controller.migrating, isTrue);
    hold.complete(MigrationDone(b.id));
    await started;

    expect(listsDuringMigration, 0);
    expect(controller.migrating, isFalse);
    expect(controller.status, LibraryStatus.ready);
    expect(ids(controller.entries), [b.id, a.id]);
    expect(ids(controller.entries), ids(await library.list()));
    expect(controller.takeNotice(), isNull);
  });

  test('migration failure keeps the library closed (AC-8)', () async {
    writeDocument(1);
    MigrationOutcome next = const MigrationFailed(
      MigrationFailure.insufficientSpace,
    );
    final controller = LibraryController(
      library: library,
      migrate: () async => next,
    );
    await controller.start();
    expect(controller.status, LibraryStatus.failed);
    expect(controller.migrationFailure, MigrationFailure.insufficientSpace);
    expect(controller.entries, isEmpty);
    expect(library.lists, 0);

    // Nothing may list past a failed migration.
    await controller.refresh();
    expect(controller.status, LibraryStatus.failed);
    expect(library.lists, 0);

    next = const MigrationFailed(MigrationFailure.io);
    await controller.start();
    expect(controller.migrationFailure, MigrationFailure.io);

    next = MigrationDone(id(9));
    await controller.start();
    expect(controller.status, LibraryStatus.ready);
    expect(controller.migrationFailure, isNull);
    expect(ids(controller.entries), [id(1)]);
  });

  test('migration failure keeps the library closed (AC-8): an unexpected '
      'error is an io failure, not an endless loading', () async {
    writeDocument(1);
    final controller = LibraryController(
      library: library,
      migrate: () async => throw StateError('bug'),
    );
    await controller.start();
    expect(controller.status, LibraryStatus.failed);
    expect(controller.migrating, isFalse);
    expect(controller.migrationFailure, MigrationFailure.io);
    expect(library.lists, 0);
  });

  test('unreadable P1 data is reported and the library opens (AC-9)', () async {
    writeDocument(1);
    var notified = 0;
    final controller = LibraryController(
      library: library,
      migrate: () async => const MigrationSourceUnreadable(),
    )..addListener(() => notified++);
    await controller.start();
    expect(notified, greaterThan(0));
    expect(controller.status, LibraryStatus.ready);
    expect(ids(controller.entries), [id(1)]);
    expect(controller.takeNotice(), LibraryNotice.migrationSourceUnreadable);
    expect(controller.takeNotice(), isNull);
  });

  test('listing failure fails the library', () async {
    library.fail = true;
    final controller = LibraryController(
      library: library,
      migrate: () async => const MigrationNotNeeded(),
    );
    await controller.start();
    expect(controller.status, LibraryStatus.failed);
    expect(controller.migrationFailure, isNull);
    expect(controller.entries, isEmpty);

    library.fail = false;
    writeDocument(1);
    await controller.start();
    expect(controller.status, LibraryStatus.ready);
    expect(ids(controller.entries), [id(1)]);

    // A failing refresh fails the library too, and a later one reopens it.
    library.fail = true;
    await controller.refresh();
    expect(controller.status, LibraryStatus.failed);
    expect(controller.migrationFailure, isNull);
    library.fail = false;
    await controller.refresh();
    expect(controller.status, LibraryStatus.ready);
  });

  test('overlapping start and refresh run one at a time in order', () async {
    final hold = Completer<MigrationOutcome>();
    var migrations = 0;
    final controller = LibraryController(
      library: library,
      migrate: () {
        migrations++;
        return migrations == 1
            ? hold.future
            : Future.value(const MigrationNotNeeded());
      },
    );
    final first = controller.start();
    final refreshed = controller.refresh();
    final second = controller.start();
    await pumpEventQueue();
    expect(migrations, 1);
    expect(library.lists, 0, reason: 'refresh waits for the migration');

    writeDocument(1);
    hold.complete(const MigrationNotNeeded());
    await Future.wait([first, refreshed, second]);
    expect(migrations, 2);
    expect(library.lists, 3);
    expect(controller.status, LibraryStatus.ready);
    expect(ids(controller.entries), [id(1)]);
  });

  test('new document has the default title (AC-12)', () async {
    final now = DateTime.utc(2026, 10, 12, 1, 2, 3);
    final docId = id(7);
    final controller = LibraryController(
      library: library,
      now: () => now,
      newId: () => docId,
    );
    await controller.start();

    final created = await controller.createDocument();
    expect(created, isNotNull);
    final (store, document) = created!;
    expect(store, same(library.open(docId)));
    expect(document.id, docId);
    expect(document.title, defaultDocumentTitle(now.toLocal()));
    expect(document.createdAt, now);
    expect(document.updatedAt, now);
    expect(document.createdAt.isUtc, isTrue);
    expect(document.pages, isEmpty);
    expect(ids(controller.entries), [docId]);
    expect(
      (controller.entries.single as LibraryDocument).document.title,
      document.title,
    );
    expect(controller.takeNotice(), isNull);
  });

  test('new document converts a local clock to UTC (AC-12)', () async {
    final now = DateTime(2026, 10, 12, 23, 59);
    final controller = LibraryController(
      library: library,
      now: () => now,
      newId: () => id(8),
    );
    await controller.start();
    final (_, document) = (await controller.createDocument())!;
    expect(document.title, 'Tài liệu 12/10/2026 23:59');
    expect(document.createdAt, now.toUtc());
    expect(document.createdAt.isUtc, isTrue);
  });

  test('new document failure is reported and adds nothing', () async {
    writeDocument(1);
    final controller = LibraryController(
      library: library,
      // The folder already exists, so create refuses.
      newId: () => id(1),
    );
    await controller.start();
    final before = snapshot();
    expect(await controller.createDocument(), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(snapshot(), before);
    expect(ids(controller.entries), [id(1)]);
  });

  test('rename validates and saves (AC-12)', () async {
    final doc = writeDocument(1, title: 'Cũ');
    var clock = _t0.add(const Duration(days: 1));
    final controller = LibraryController(library: library, now: () => clock);
    await controller.start();
    final before = manifestOf(doc.id).readAsBytesSync();

    expect(await controller.rename(doc.id, '   '), TitleError.empty);
    expect(await controller.rename(doc.id, 'a' * 121), TitleError.tooLong);
    expect(await controller.rename(doc.id, 'a\nb'), TitleError.invalid);
    expect(manifestOf(doc.id).readAsBytesSync(), before);
    expect(controller.takeNotice(), isNull);

    expect(await controller.rename(doc.id, ' Mới '), isNull);
    final saved = decodeDocument(manifestOf(doc.id).readAsStringSync());
    final document = (saved as DecodedDocument).document;
    expect(document.title, 'Mới');
    expect(document.updatedAt, clock);
    expect(document.createdAt, _t0);
    final entry = controller.entries.single as LibraryDocument;
    expect(entry.document.title, 'Mới');
    expect(entry.document.updatedAt, clock);
    expect(controller.takeNotice(), isNull);

    // A clock behind createdAt never makes updatedAt earlier than it.
    clock = _t0.subtract(const Duration(days: 1));
    expect(await controller.rename(doc.id, 'Lùi giờ'), isNull);
    final again = decodeDocument(manifestOf(doc.id).readAsStringSync());
    expect((again as DecodedDocument).document.updatedAt, _t0);
  });

  test('rename of an unreadable document writes nothing (AC-12)', () async {
    final docId = id(2);
    Directory('${root.path}/$docId').createSync(recursive: true);
    manifestOf(docId).writeAsStringSync('{garbage');
    final newer = id(3);
    Directory('${root.path}/$newer').createSync(recursive: true);
    manifestOf(newer).writeAsStringSync('{"schemaVersion":9}');
    final controller = LibraryController(library: library);
    await controller.start();
    final before = snapshot();

    expect(await controller.rename(docId, 'Mới'), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(await controller.rename(newer, 'Mới'), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(await controller.rename('not-an-id', 'Mới'), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(snapshot(), before);
    expect(controller.entries, hasLength(2));
  });

  test('rename of an unreadable document writes nothing (AC-12): a page '
      'whose original is missing is not loaded', () async {
    final pageId = id(20);
    final document = ScanDocument(
      id: id(4),
      title: 'Thiếu ảnh',
      createdAt: _t0,
      updatedAt: _t0,
      pages: [ScanPage(id: pageId, originalPath: 'originals/$pageId.jpg')],
    );
    Directory('${root.path}/${document.id}').createSync(recursive: true);
    manifestOf(document.id).writeAsStringSync(encodeDocument(document));
    final controller = LibraryController(library: library);
    await controller.start();
    expect(controller.entries.single, isA<LibraryDocument>());
    final before = snapshot();

    expect(await controller.rename(document.id, 'Mới'), isNull);

    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(snapshot(), before, reason: 'the manifest is not quarantined');
    expect(controller.entries.single, isA<LibraryDocument>());
  });

  test('new document failure is reported and adds nothing: not before '
      'the library has opened', () async {
    final controller = LibraryController(
      library: library,
      migrate: () async => const MigrationFailed(MigrationFailure.io),
    );
    expect(await controller.createDocument(), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    await controller.start();
    expect(await controller.createDocument(), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(root.existsSync() && root.listSync().isNotEmpty, isFalse);
  });

  test('rename of a document needing an app update is refused', () async {
    final doc = writeDocument(1);
    final controller = LibraryController(library: library);
    await controller.start();
    // Replaced by a newer app after the library was listed.
    manifestOf(doc.id).writeAsStringSync('{"schemaVersion":9}');
    final before = snapshot();

    expect(await controller.rename(doc.id, 'Mới'), isNull);
    expect(controller.takeNotice(), LibraryNotice.saveFailed);
    expect(snapshot(), before);
    expect(controller.entries.single, isA<LibraryNeedsUpdate>());
  });

  test('a disposed controller does not notify', () async {
    final hold = Completer<MigrationOutcome>();
    final controller = LibraryController(
      library: library,
      migrate: () => hold.future,
    );
    final started = controller.start();
    await pumpEventQueue();
    controller.dispose();
    hold.complete(const MigrationSourceUnreadable());
    // A notify after dispose would throw here.
    await started;
  });
}
