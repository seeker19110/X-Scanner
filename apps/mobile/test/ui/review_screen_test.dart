import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/main.dart';
import 'package:x_scanner/storage/session_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/session_controller.dart';

/// Scripted [PageSource]: each call takes the next queued result;
/// [discarded] records every [discard] call.
class FakeSource implements PageSource {
  final List<String> discarded = [];
  final List<String?> captures = [];
  final List<String?> gallery = [];

  @override
  Future<String?> capture() async => captures.removeAt(0);

  @override
  Future<String?> pickFromGallery() async => gallery.removeAt(0);

  @override
  Future<String?> retrieveLost() async => null;

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

/// [FileSharer] that records shared file names and can be made to fail.
class FakeSharer implements FileSharer {
  final List<List<String>> shared = [];
  bool fail = false;

  /// When set, sharing waits for it to complete.
  Completer<void>? gate;

  @override
  Future<void> share(List<File> files) async {
    shared.add([for (final f in files) f.path.split('/').last]);
    await gate?.future;
    if (fail) throw StateError('share failed');
  }
}

const String _empty = 'Chưa có trang nào. Chụp hoặc nhập ảnh để bắt đầu.';

void main() {
  late Directory tmp;
  late Directory picks;
  late FakeSource source;
  late FakeSharer sharer;
  late SessionController controller;
  var n = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('review_screen_test');
    picks = Directory('${tmp.path}/picks')..createSync();
    source = FakeSource();
    sharer = FakeSharer();
    controller = SessionController(
      store: SessionStore(Directory('${tmp.path}/session')..createSync()),
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
      // Decoded in the test isolate; real file I/O runs under runAsync.
      thumbnailer: (path) async => thumbnailSync(File(path).readAsBytesSync()),
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Writes a synthetic PNG and returns its path.
  String png() {
    n++;
    final image = img.Image(width: 6 + n, height: 4 + n);
    return (File(
      '${picks.path}/p$n.png',
    )..writeAsBytesSync(img.encodePng(image))).path;
  }

  /// Lets queued controller work with real I/O finish, then settles frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 500; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
      if (!controller.busy) break;
    }
    expect(controller.busy, isFalse);
    // Thumbnails also decode with real I/O.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester, {int pages = 0}) async {
    await tester.runAsync(() async {
      for (var i = 0; i < pages; i++) {
        source.captures.add(png());
        await controller.capture();
      }
    });
    await tester.pumpWidget(XScannerApp(controller: controller));
    await settle(tester);
  }

  testWidgets('empty session offers capture and import', (tester) async {
    await start(tester);
    expect(find.text('X-Scanner'), findsOneWidget);
    expect(find.text(_empty), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Chụp'), findsOneWidget);
    expect(find.text('Nhập ảnh'), findsOneWidget);
  });

  testWidgets('cancelled capture adds no page (AC-7)', (tester) async {
    await start(tester);
    source.captures.add(null);
    await tester.tap(find.text('Chụp'));
    await settle(tester);
    expect(find.text(_empty), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(controller.session.pages, isEmpty);
  });

  testWidgets('captured image appears as a page', (tester) async {
    await start(tester);
    source.captures.add(png());
    await tester.tap(find.text('Chụp'));
    await settle(tester);
    expect(find.text(_empty), findsNothing);
    expect(find.text('Trang 1'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('undecodable image shows a message and keeps pages (AC-7)', (
    tester,
  ) async {
    await start(tester, pages: 1);
    expect(find.text('Trang 1'), findsOneWidget);
    final junk = File('${picks.path}/junk.jpg')..writeAsBytesSync([1, 2, 3]);
    source.gallery.add(junk.path);

    await tester.tap(find.text('Nhập ảnh'));
    await settle(tester);

    expect(
      find.text('Không đọc được ảnh này. Chưa thêm trang nào.'),
      findsOneWidget,
    );
    expect(find.text('Trang 1'), findsOneWidget);
    expect(find.text('Trang 2'), findsNothing);
    expect(controller.session.pages, hasLength(1));
  });

  testWidgets('a corrupt saved session shows restoreFailed', (tester) async {
    File('${tmp.path}/session/session.json')
        .writeAsStringSync('{"schemaVersion": 99}');
    await start(tester);
    expect(
      find.text(
        'Không khôi phục được phiên trước. '
        'Ảnh gốc vẫn được giữ trong bộ nhớ của app.',
      ),
      findsOneWidget,
    );
    expect(find.text(_empty), findsOneWidget);
  });

  testWidgets('theme button switches between dark and light', (tester) async {
    await start(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(brightness(), Brightness.dark);

    await tester.tap(find.byTooltip('Chế độ sáng'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(find.byTooltip('Chế độ tối'), findsOneWidget);

    await tester.tap(find.byTooltip('Chế độ tối'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
  });

  testWidgets('deleting a page needs confirmation', (tester) async {
    await start(tester, pages: 2);
    final second = controller.session.pages[1].id;

    await tester.tap(find.byTooltip('Xoá trang').first);
    await tester.pumpAndSettle();
    expect(find.text('Xoá trang 1?'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await settle(tester);
    expect(controller.session.pages, hasLength(2));
    expect(find.text('Trang 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Xoá trang').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await settle(tester);
    expect([for (final p in controller.session.pages) p.id], [second]);
    expect(find.text('Trang 1'), findsOneWidget);
    expect(find.text('Trang 2'), findsNothing);
  });

  testWidgets('clearing all pages needs confirmation', (tester) async {
    await start(tester, pages: 2);

    await tester.tap(find.byTooltip('Xoá tất cả trang'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá tất cả trang?'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await settle(tester);
    expect(controller.session.pages, hasLength(2));

    await tester.tap(find.byTooltip('Xoá tất cả trang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá tất cả'));
    await settle(tester);
    expect(controller.session.pages, isEmpty);
    expect(find.text(_empty), findsOneWidget);
    expect(find.byTooltip('Xoá tất cả trang'), findsNothing);
  });

  testWidgets('retake needs confirmation and replaces the page', (
    tester,
  ) async {
    await start(tester, pages: 1);
    final before = controller.session.pages.single.id;

    await tester.tap(find.byTooltip('Chụp lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chụp lại trang 1? Ảnh cũ sẽ bị thay.'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await settle(tester);
    expect(controller.session.pages.single.id, before);

    source.captures.add(png());
    await tester.tap(find.byTooltip('Chụp lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Chụp lại'));
    await settle(tester);
    expect(controller.session.pages.single.id, isNot(before));
  });

  testWidgets('rotate button turns the page', (tester) async {
    await start(tester, pages: 1);
    await tester.tap(find.byTooltip('Xoay 90°'));
    await settle(tester);
    expect(controller.session.pages.single.quarterTurns, 1);
  });

  testWidgets('crop button opens the editor and saves its result', (
    tester,
  ) async {
    await start(tester, pages: 1);
    await tester.tap(find.byTooltip('Chỉnh góc'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu'), findsOneWidget);
    await tester.tap(find.text('Xoay 90°'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Trang 1'), findsOneWidget);
    expect(controller.session.pages.single.quarterTurns, 1);
  });

  testWidgets('dragging a page down reorders the session', (tester) async {
    await start(tester, pages: 2);
    final [a, b] = [for (final p in controller.session.pages) p.id];
    final first = tester.getCenter(find.text('Trang 1'));
    final second = tester.getCenter(find.text('Trang 2'));

    final gesture = await tester.startGesture(first);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    final step = Offset(0, (second.dy - first.dy) * 1.5 / 10);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(step);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    // The drop animation must end before the reorder callback fires.
    for (var i = 0; i < 50 && !controller.busy; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.busy, isTrue);
    await settle(tester);

    expect([for (final p in controller.session.pages) p.id], [b, a]);
  });

  testWidgets('dragging a page while busy does not reorder (F-007)', (
    tester,
  ) async {
    await start(tester, pages: 2);
    final before = [for (final p in controller.session.pages) p.id];
    // Keep the controller busy with an export held at the share step.
    final gate = sharer.gate = Completer<void>();
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PNG'));
    for (var i = 0; i < 500 && sharer.shared.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    await tester.pump();
    expect(controller.busy, isTrue);

    final first = tester.getCenter(find.text('Trang 1'));
    final second = tester.getCenter(find.text('Trang 2'));
    final gesture = await tester.startGesture(first);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    final step = Offset(0, (second.dy - first.dy) * 1.5 / 10);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(step);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    // Let any drop animation, and so any reorder callback, finish.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    gate.complete();
    await settle(tester);
    expect([for (final p in controller.session.pages) p.id], before);
  });

  testWidgets('export is only offered when there are pages', (tester) async {
    await start(tester);
    expect(find.byTooltip('Xuất'), findsNothing);
  });

  testWidgets('exporting as PDF shares one .pdf file (AC-6)', (tester) async {
    await start(tester, pages: 2);
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('JPG'), findsOneWidget);
    expect(find.text('PNG'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await settle(tester);
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single, hasLength(1));
    expect(sharer.shared.single.single, endsWith('.pdf'));
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('PDF'), findsNothing, reason: 'sheet closed');
  });

  testWidgets('choosing JPG or PNG shares one image per page', (tester) async {
    await start(tester, pages: 2);
    for (final (label, ext) in [('JPG', '.jpg'), ('PNG', '.png')]) {
      await tester.tap(find.byTooltip('Xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await settle(tester);
      expect(sharer.shared.last, hasLength(2));
      expect(sharer.shared.last, everyElement(endsWith(ext)));
    }
  });

  testWidgets('a failed share shows exportFailed and keeps the pages', (
    tester,
  ) async {
    await start(tester, pages: 1);
    sharer.fail = true;
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await settle(tester);
    expect(
      find.text('Không xuất được tài liệu. Bản gốc vẫn còn nguyên.'),
      findsOneWidget,
    );
    expect(find.text('Trang 1'), findsOneWidget);
    expect(controller.session.pages, hasLength(1));
  });

  testWidgets('dismissing the format sheet exports nothing', (tester) async {
    await start(tester, pages: 1);
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(find.text('PDF'), findsNothing);
    expect(sharer.shared, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the export button is disabled while busy', (tester) async {
    await start(tester, pages: 1);
    final gate = sharer.gate = Completer<void>();
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    for (var i = 0; i < 500 && sharer.shared.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    await tester.pump();
    expect(controller.busy, isTrue);
    IconButton exportButton() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      ),
    );
    expect(exportButton().onPressed, isNull);

    gate.complete();
    await settle(tester);
    expect(exportButton().onPressed, isNotNull);
  });
}
