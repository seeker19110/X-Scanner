import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/main.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/p1_migration.dart';
import 'package:x_scanner/storage/pending_pick_store.dart';
import 'package:x_scanner/ui/library_controller.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/pick_import.dart';
import 'package:x_scanner/ui/session_controller.dart';

/// A [PageSource] that never returns an image.
class _NoSource implements PageSource {
  @override
  Future<String?> capture() async => null;

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<String?> retrieveLost() async => null;

  @override
  Future<void> discard(String path) async {}
}

/// A [FileSharer] that shares nothing.
class _NoSharer implements FileSharer {
  @override
  Future<void> share(List<File> files) async {}
}

/// Free space far beyond any test session.
class _RoomyStorage implements Storage {
  @override
  Future<int> freeBytes(Directory dir) async => 1 << 40;
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('app_test'));

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Lets real I/O run until [done], pumping frames.
  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  testWidgets('migrates P1 data, opens the library and the document screen '
      'in dark mode (PR-4b.2 C1)', (tester) async {
    // A P1 session with no pages: the migration still makes one document.
    Directory('${tmp.path}/session').createSync();
    File('${tmp.path}/session/session.json')
        .writeAsStringSync('{"schemaVersion":1,"pages":[]}');
    final source = _NoSource();
    final library = LibraryStore(Directory('${tmp.path}/documents'));
    final pending = PendingPickStore(
      dir: Directory('${tmp.path}/pending-pick'),
      cacheDir: tmp,
      maxBytes: 64,
    );
    final recovery = PickImporter(
      pending: pending,
      source: source,
      decode: (_) async => throw UnsupportedError('no images here'),
    );
    final controller = LibraryController(
      library: library,
      migrate: P1Migration(appRoot: tmp, storage: _RoomyStorage()).run,
      recover: (outcome) => recovery.recover(library, outcome),
    );
    SessionController? opened;
    await tester.pumpWidget(
      XScannerApp(
        library: controller,
        openDocument: (store, ScanDocument document, {after}) =>
            opened = SessionController(
              store: store,
              document: document,
              after: after,
              pending: pending,
              source: source,
              exporter: PageExporter(
                exportDir: Directory('${tmp.path}/exports'),
              ),
              sharer: _NoSharer(),
            ),
      ),
    );
    await settle(tester, () => controller.status == LibraryStatus.ready);
    await tester.pumpAndSettle();

    expect(find.text('Thư viện'), findsOneWidget);
    expect(controller.entries, hasLength(1));
    expect(Directory('${tmp.path}/session.migrated').existsSync(), isTrue);
    final scaffoldContext = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);

    await tester.tap(find.textContaining('0 trang'));
    await tester.pump();
    await settle(tester, () => opened != null && !opened!.busy);
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa có trang nào. Chụp hoặc nhập ảnh để bắt đầu.'),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester, () => controller.status == LibraryStatus.ready);
    await tester.pumpAndSettle();
    expect(find.text('Thư viện'), findsOneWidget);
  });
}
