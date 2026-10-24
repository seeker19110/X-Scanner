import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/storage/document_store.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/pending_pick_store.dart';
import 'package:x_scanner/ui/library_controller.dart';
import 'package:x_scanner/ui/library_screen.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/session_controller.dart';

import 'document_test_app.dart';

/// [PageSource] that hands out the queued capture paths.
class _Source implements PageSource {
  final List<String?> captures = [];

  @override
  Future<String?> capture() async => captures.removeAt(0);

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<String?> retrieveLost() async => null;

  @override
  Future<void> discard(String path) async {}
}

/// [FileSharer] that is never reached in these tests.
class _Sharer implements FileSharer {
  @override
  Future<void> share(List<File> files) async {}
}

/// Presses Tab until the focused node is inside [target]; fails if focus
/// never gets there (a focus trap or an unreachable control, UX-A11Y-003).
Future<void> _tabTo(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  for (var i = 0; i < 40; i++) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        find
            .descendant(
              of: target,
              matching: find.byElementPredicate((e) => identical(e, focused)),
            )
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Tab never reached $target');
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('keyboard_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Runs real I/O until [done], then settles frames.
  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
    // Thumbnails and previews also complete on the real event loop.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the library works with Tab, Enter and Escape only '
      '(UX-A11Y-003)', (tester) async {
    final root = Directory('${tmp.path}/documents');
    final created = DateTime.utc(2026, 10, 1);
    final document = ScanDocument(
      id: newPageId(Random(1)),
      title: 'Hoá đơn điện',
      createdAt: created,
      updatedAt: created,
    );
    Directory('${root.path}/${document.id}').createSync(recursive: true);
    File('${root.path}/${document.id}/document.json')
        .writeAsStringSync(encodeDocument(document));
    final opened = <String>[];
    final controller = LibraryController(library: LibraryStore(root));
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryScreen(
          controller: controller,
          documentScreen: (context, store, document) {
            opened.add(document.title);
            return Scaffold(appBar: AppBar(title: const Text('Màn tài liệu')));
          },
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
        ),
      ),
    );
    await pumpUntil(tester, () => controller.status == LibraryStatus.ready);

    // Open the document, then come back with the Back button.
    await _tabTo(
      tester,
      find.ancestor(
        of: find.text(document.title),
        matching: find.byType(InkWell),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, [document.title]);
    await _tabTo(tester, find.byType(BackButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpUntil(tester, () => find.text('Thư viện').evaluate().isNotEmpty);

    // Rename opens a dialog that Escape closes without renaming.
    await _tabTo(tester, find.byTooltip('Đổi tên'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tên khác');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(document.title), findsOneWidget);

    // The new document button creates and opens a document.
    await _tabTo(tester, find.byType(FloatingActionButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpUntil(tester, () => opened.length == 2);
    expect(find.text('Màn tài liệu'), findsOneWidget);
  });

  testWidgets('the document screen works with Tab, Enter and Escape only '
      '(UX-A11Y-003)', (tester) async {
    final document = testDocument(tmp);
    final source = _Source();
    final thumb = img.encodePng(img.Image(width: 8, height: 6));
    final controller = (await tester.runAsync(() async {
      final c = SessionController(
        store: DocumentStore(documentDir(tmp, document)),
        document: document,
        pending: PendingPickStore(
          dir: Directory('${tmp.path}/pending-pick'),
          cacheDir: tmp,
          maxBytes: maxOriginalBytes,
        ),
        source: source,
        exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
        sharer: _Sharer(),
        thumbnailer: (_) async => thumb,
        previewer: (bytes, quad, turns) async =>
            renderPageSync(bytes, quad, turns),
      );
      await c.restore();
      for (var i = 0; i < 2; i++) {
        final file = File('${tmp.path}/p$i.png')..writeAsBytesSync(thumb);
        source.captures.add(file.path);
        await c.capture();
      }
      return c;
    }))!;
    final pages = controller.session.pages;
    expect(pages, hasLength(2));
    await tester.pumpWidget(
      DocumentTestApp(controller: controller, restore: false),
    );
    await pumpUntil(tester, () => !controller.busy);

    // Delete: Enter opens the dialog, Escape cancels it.
    await _tabTo(tester, find.byTooltip('Xoá trang').first);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Xoá trang 1?'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.session.pages, pages);

    // Export: Enter opens the format sheet, Escape closes it.
    await _tabTo(tester, find.byTooltip('Xuất'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Chọn định dạng'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Chọn định dạng'), findsNothing);

    // Clear all: Tab reaches the confirm button inside the dialog.
    await _tabTo(tester, find.byTooltip('Xoá tất cả trang'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await _tabTo(tester, find.widgetWithText(FilledButton, 'Xoá tất cả'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpUntil(tester, () => controller.session.pages.isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
