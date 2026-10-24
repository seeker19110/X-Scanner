import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/storage/document_store.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/p1_migration.dart';
import 'package:x_scanner/ui/library_controller.dart';
import 'package:x_scanner/ui/library_screen.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 1, 8);

const String _documentScreenTitle = 'Màn tài liệu';

/// [LibraryStore] whose [list] fails while [fail] is set.
class _FlakyLibrary extends LibraryStore {
  _FlakyLibrary(super.root);

  bool fail = false;

  @override
  Future<List<LibraryEntry>> list() async {
    if (fail) throw const FileSystemException('list failed');
    return super.list();
  }
}

/// `dd/MM/yyyy HH:mm` of [time] in device time.
String _local(DateTime time) {
  final t = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} '
      '${two(t.hour)}:${two(t.minute)}';
}

void main() {
  late Directory tmp;
  late Directory root;
  late _FlakyLibrary library;
  late List<(DocumentStore, ScanDocument)> opened;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('library_screen_test');
    root = Directory('${tmp.path}/documents');
    library = _FlakyLibrary(root);
    opened = [];
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  String id(int n) => newPageId(Random(n));

  /// Writes [json] as the manifest of folder [docId].
  void writeFolder(String docId, String json) {
    final dir = Directory('${root.path}/$docId')..createSync(recursive: true);
    File('${dir.path}/document.json').writeAsStringSync(json);
  }

  /// Writes a document folder by hand; pages need no originals to be
  /// listed.
  ScanDocument writeDocument(
    int n, {
    required String title,
    DateTime? updatedAt,
    int pages = 0,
  }) {
    final document = ScanDocument(
      id: id(n),
      title: title,
      createdAt: _t0,
      updatedAt: updatedAt ?? _t0,
      pages: [
        for (var i = 0; i < pages; i++)
          ScanPage(
            id: id(100 * n + i),
            originalPath: 'originals/${id(100 * n + i)}.jpg',
          ),
      ],
    );
    writeFolder(document.id, encodeDocument(document));
    return document;
  }

  Widget app(LibraryController controller) => MaterialApp(
    home: LibraryScreen(
      controller: controller,
      documentScreen: (context, store, document) {
        opened.add((store, document));
        return Scaffold(
          appBar: AppBar(title: const Text(_documentScreenTitle)),
          body: Text('Mở: ${document.title}'),
        );
      },
      themeMode: ThemeMode.dark,
      onToggleTheme: () {},
    ),
  );

  /// Runs real I/O until [done], then settles frames when [settle].
  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() done, {
    bool settle = true,
  }) async {
    for (var i = 0; i < 500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
    // Builds the frame for the state [done] saw.
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  Future<LibraryController> open(
    WidgetTester tester, {
    Future<MigrationOutcome> Function()? migrate,
  }) async {
    final controller = LibraryController(
      library: library,
      migrate: migrate,
      now: () => DateTime.utc(2026, 10, 12, 1, 2),
    );
    await tester.pumpWidget(app(controller));
    await pumpUntil(tester, () => controller.status != LibraryStatus.loading);
    return controller;
  }

  group('library shows every state (AC-11)', () {
    testWidgets('loading while migrating, then empty', (tester) async {
      final hold = Completer<MigrationOutcome>();
      final controller = LibraryController(
        library: library,
        migrate: () => hold.future,
      );
      await tester.pumpWidget(app(controller));
      await pumpUntil(tester, () => controller.migrating, settle: false);
      expect(find.text('Thư viện'), findsOneWidget);
      expect(find.text('Đang nâng cấp dữ liệu…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tài liệu mới'), findsNothing);

      hold.complete(const MigrationNotNeeded());
      await pumpUntil(tester, () => controller.status == LibraryStatus.ready);
      expect(find.text('Đang nâng cấp dữ liệu…'), findsNothing);
      expect(find.text('Chưa có tài liệu'), findsOneWidget);
      expect(find.text('Tài liệu mới'), findsOneWidget);
      expect(find.byTooltip('Chế độ sáng'), findsOneWidget);
    });

    testWidgets('loading without a migration has a label', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = LibraryController(library: library);
      await tester.pumpWidget(app(controller));
      expect(controller.status, LibraryStatus.loading);
      expect(find.bySemanticsLabel('Đang tải thư viện'), findsOneWidget);
      expect(find.text('Đang nâng cấp dữ liệu…'), findsNothing);
      await pumpUntil(tester, () => controller.status == LibraryStatus.ready);
      handle.dispose();
    });

    testWidgets('listing failure offers a retry that opens the library', (
      tester,
    ) async {
      library.fail = true;
      final controller = await open(tester);
      expect(controller.status, LibraryStatus.failed);
      expect(find.text('Không đọc được thư viện.'), findsOneWidget);
      expect(find.text('Tài liệu mới'), findsNothing);

      library.fail = false;
      writeDocument(1, title: 'Hoá đơn');
      await tester.tap(find.text('Thử lại'));
      await pumpUntil(tester, () => controller.status == LibraryStatus.ready);
      expect(find.text('Không đọc được thư viện.'), findsNothing);
      expect(find.text('Hoá đơn'), findsOneWidget);
    });

    testWidgets('migration failures say why and retry (AC-8)', (tester) async {
      MigrationOutcome next = const MigrationFailed(
        MigrationFailure.insufficientSpace,
      );
      final controller = await open(tester, migrate: () async => next);
      expect(
        find.text(
          'Không đủ bộ nhớ để nâng cấp dữ liệu. '
          'Hãy giải phóng bộ nhớ rồi thử lại.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);

      next = const MigrationFailed(MigrationFailure.io);
      await tester.tap(find.text('Thử lại'));
      await pumpUntil(
        tester,
        () => controller.migrationFailure == MigrationFailure.io,
      );
      expect(
        find.text('Không nâng cấp được dữ liệu. Dữ liệu cũ vẫn còn nguyên.'),
        findsOneWidget,
      );

      next = const MigrationNotNeeded();
      await tester.tap(find.text('Thử lại'));
      await pumpUntil(tester, () => controller.status == LibraryStatus.ready);
      expect(find.text('Chưa có tài liệu'), findsOneWidget);
    });

    testWidgets('documents newest first with pages and date; others closed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final old = writeDocument(1, title: 'Cũ nhất', pages: 1);
      final newest = writeDocument(
        2,
        title: 'Mới nhất',
        updatedAt: _t0.add(const Duration(days: 2, minutes: 7)),
        pages: 3,
      );
      final middle = writeDocument(
        3,
        title: 'Giữa',
        updatedAt: _t0.add(const Duration(days: 1)),
      );
      writeFolder(id(4), '{"schemaVersion":9}');
      writeFolder(id(5), '{garbage');
      await open(tester);

      final titles = ['Mới nhất', 'Giữa', 'Cũ nhất'];
      final ys = [for (final t in titles) tester.getTopLeft(find.text(t)).dy];
      expect(ys, [...ys]..sort());
      expect(
        find.text('3 trang · ${_local(newest.updatedAt)}'),
        findsOneWidget,
      );
      expect(
        find.text('0 trang · ${_local(middle.updatedAt)}'),
        findsOneWidget,
      );
      expect(find.text('1 trang · ${_local(old.updatedAt)}'), findsOneWidget);
      expect(find.byTooltip('Đổi tên'), findsNWidgets(3));
      // One merged label per document.
      expect(
        find.bySemanticsLabel(
          'Mới nhất, 3 trang, sửa lúc ${_local(newest.updatedAt)}',
        ),
        findsOneWidget,
      );

      final needsUpdate = find.text('Cần cập nhật app để mở');
      final unreadable = find.text('Không mở được tài liệu này');
      expect(needsUpdate, findsOneWidget);
      expect(unreadable, findsOneWidget);
      expect(
        tester.getTopLeft(needsUpdate).dy,
        greaterThan(tester.getTopLeft(find.text('Cũ nhất')).dy),
      );
      await tester.tap(needsUpdate);
      await tester.tap(unreadable);
      await tester.pumpAndSettle();
      expect(find.text(_documentScreenTitle), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text('Giữa'));
      await tester.pumpAndSettle();
      expect(find.text(_documentScreenTitle), findsOneWidget);
      expect(opened.single.$2.id, middle.id);
      expect(opened.single.$1, same(library.open(middle.id)));
      handle.dispose();
    });
  });

  testWidgets('library fits 320dp at 200 percent text without overflow '
      '(UX-RESP-001)', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final long = writeDocument(
      1,
      title:
          'Hợp đồng thuê nhà và các phụ lục kèm theo năm 2026 '
          'đã ký giữa hai bên',
      pages: 12,
    );
    writeFolder(id(2), '{"schemaVersion":9}');
    writeFolder(id(3), '{garbage');
    await open(tester);
    expect(tester.takeException(), isNull);

    // Every row and its actions stay reachable within the 320dp width.
    for (final finder in [
      find.textContaining('Hợp đồng thuê nhà'),
      find.byTooltip('Đổi tên'),
      find.text('Cần cập nhật app để mở'),
      find.text('Không mở được tài liệu này'),
      find.byType(FloatingActionButton),
    ]) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$finder');
      expect(rect.right, lessThanOrEqualTo(320), reason: '$finder');
    }
    // Shortened to its icon when the label does not fit, but still named.
    expect(find.byTooltip('Tài liệu mới'), findsOneWidget);
    await tester.tap(find.byTooltip('Đổi tên'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lưu').hitTestable(), findsOneWidget);
    expect(long.pages, hasLength(12));
  });

  testWidgets('new document opens the document screen (AC-12)', (tester) async {
    final controller = await open(tester);
    expect(find.text('Chưa có tài liệu'), findsOneWidget);
    final button = find.ancestor(
      of: find.text('Tài liệu mới'),
      matching: find.byType(FloatingActionButton),
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Tài liệu mới'));
    await pumpUntil(tester, () => opened.isNotEmpty);
    final title = defaultDocumentTitle(
      DateTime.utc(2026, 10, 12, 1, 2).toLocal(),
    );
    expect(find.text(_documentScreenTitle), findsOneWidget);
    expect(find.text('Mở: $title'), findsOneWidget);
    expect(opened.single.$2.pages, isEmpty);

    // Coming back lists the new document.
    await tester.pageBack();
    await pumpUntil(tester, () => find.text(title).evaluate().isNotEmpty);
    expect(find.text('Chưa có tài liệu'), findsNothing);
    expect(controller.entries, hasLength(1));
    expect(
      find.text('0 trang · ${_local(DateTime.utc(2026, 10, 12, 1, 2))}'),
      findsOneWidget,
    );
  });

  testWidgets('new document opens the document screen (AC-12): a document '
      'tapped while it is being created does not open on top', (tester) async {
    writeDocument(1, title: 'Hoá đơn');
    final controller = await open(tester);

    await tester.tap(find.text('Tài liệu mới'));
    // The create is still writing: the list is still there to tap.
    await tester.tap(find.text('Hoá đơn'));
    await tester.pumpAndSettle();
    await pumpUntil(tester, () => controller.entries.length == 2);
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
  });

  testWidgets('rename shows errors in place and saves (AC-12)', (tester) async {
    final doc = writeDocument(1, title: 'Hoá đơn');
    final controller = await open(tester);

    await tester.tap(find.byTooltip('Đổi tên'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Đổi tên'), findsOneWidget);
    final field = find.widgetWithText(TextField, 'Tên tài liệu');
    expect(tester.widget<TextField>(field).controller!.text, 'Hoá đơn');

    await tester.enterText(field, '   ');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên không được để trống'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(field, 'a' * 121);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên tối đa 120 ký tự'), findsOneWidget);

    await tester.enterText(field, 'a\u0007b');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên có ký tự không hợp lệ'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Hoá đơn'), findsOneWidget);
    final saved = decodeDocument(
      File('${root.path}/${doc.id}/document.json').readAsStringSync(),
    );
    expect((saved as DecodedDocument).document.title, 'Hoá đơn');

    await tester.tap(find.byTooltip('Đổi tên'));
    await tester.pumpAndSettle();
    await tester.enterText(field, ' Hoá đơn điện ');
    await tester.tap(find.text('Lưu'));
    await pumpUntil(
      tester,
      () => find.text('Hoá đơn điện').evaluate().isNotEmpty,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Hoá đơn'), findsNothing);
    expect(
      (controller.entries.single as LibraryDocument).document.title,
      'Hoá đơn điện',
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed rename keeps the old title and says so (AC-12)', (
    tester,
  ) async {
    final doc = writeDocument(1, title: 'Hoá đơn');
    await open(tester);
    // A newer app replaced it after the library was listed.
    writeFolder(doc.id, '{"schemaVersion":9}');

    await tester.tap(find.byTooltip('Đổi tên'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên tài liệu'),
      'Mới',
    );
    await tester.tap(find.text('Lưu'));
    await pumpUntil(
      tester,
      () => find.text('Không lưu được').evaluate().isNotEmpty,
    );
    expect(find.text('Mới'), findsNothing);
  });

  testWidgets('unreadable P1 data shows a message (AC-9)', (tester) async {
    writeDocument(1, title: 'Hoá đơn');
    await open(tester, migrate: () async => const MigrationSourceUnreadable());
    expect(
      find.text(
        'Không chuyển được phiên cũ. '
        'Ảnh gốc vẫn được giữ trong bộ nhớ của app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Hoá đơn'), findsOneWidget);
  });
}
