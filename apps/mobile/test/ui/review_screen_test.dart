import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/semantics.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/main.dart';
import 'package:x_scanner/storage/session_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/quad_editor_screen.dart';
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

/// [SessionStore] whose [load] waits for [hold] once [loading] completes.
class HeldStore extends SessionStore {
  HeldStore(super.root);

  final Completer<void> hold = Completer<void>();
  final Completer<void> loading = Completer<void>();

  @override
  Future<SessionLoadResult> load() async {
    loading.complete();
    await hold.future;
    return super.load();
  }
}

/// Renderer returning a few bytes that waits at the 1-based calls in
/// `holds` until [release].
class HeldRenderer {
  HeldRenderer({Set<int> holds = const {}})
    : _holds = {for (final n in holds) n: Completer<void>()};

  final Map<int, Completer<void>> _holds;
  int calls = 0;

  /// Lets call [n] return.
  void release(int n) => _holds[n]!.complete();

  Future<Uint8List> call(
    String path,
    PageQuad quad,
    int turns, {
    RenderFormat format = RenderFormat.jpeg,
  }) async {
    final n = ++calls;
    await _holds[n]?.future;
    return Uint8List.fromList([1, 2, 3]);
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
      // Isolates do not run under the fake clock of widget tests.
      previewer: (bytes, quad, turns) async =>
          renderPageSync(bytes, quad, turns),
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

  testWidgets('a page whose thumbnail fails shows the error tile (F-028)', (
    tester,
  ) async {
    await start(tester, pages: 1);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    // A fresh controller has no cached preview, and its decoder fails.
    controller = SessionController(
      store: SessionStore(Directory('${tmp.path}/session')),
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
      thumbnailer: (_) async => throw const ImageDecodeFailure(),
      previewer: (bytes, quad, turns) async =>
          renderPageSync(bytes, quad, turns),
    );
    await tester.pumpWidget(const SizedBox());
    await start(tester);

    expect(find.text('Trang 1'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final crop = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.crop),
        matching: find.byType(IconButton),
      ),
    );
    expect(crop.onPressed, isNull, reason: 'no preview to edit on');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tapping a failed thumbnail decodes it again (F-020)', (
    tester,
  ) async {
    await start(tester, pages: 1);
    var fail = true;
    controller = SessionController(
      store: SessionStore(Directory('${tmp.path}/session')),
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
      thumbnailer: (path) async => fail
          ? throw const ImageDecodeFailure()
          : thumbnailSync(File(path).readAsBytesSync()),
      previewer: (bytes, quad, turns) async =>
          renderPageSync(bytes, quad, turns),
    );
    await tester.pumpWidget(const SizedBox());
    await start(tester);

    final retry = find.byTooltip('Tải lại ảnh xem trước trang 1');
    expect(retry, findsOneWidget);
    expect(find.byType(Image), findsNothing);
    final target = tester.getRect(
      find.ancestor(of: retry, matching: find.byType(IconButton)),
    );
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));
    final rowTile = tester.getRect(
      find.ancestor(of: retry, matching: find.byType(Card)),
    );
    expect(target.width, lessThanOrEqualTo(72));
    expect(rowTile.contains(target.center), isTrue);
    IconButton crop() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.crop),
        matching: find.byType(IconButton),
      ),
    );
    expect(crop().onPressed, isNull);

    fail = false;
    await tester.tap(retry);
    await settle(tester);

    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(crop().onPressed, isNotNull);
  });

  testWidgets('a retried thumbnail shows a spinner until it decodes, and '
      'only the retry decodes it again (F-047)', (tester) async {
    await start(tester, pages: 2);
    final failPath = controller
        .originalFile(controller.session.pages.first)
        .path;
    var fail = true;
    var failCalls = 0;
    final slow = Completer<void>();
    controller = SessionController(
      store: SessionStore(Directory('${tmp.path}/session')),
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
      thumbnailer: (path) async {
        if (path == failPath) {
          failCalls++;
          if (fail) throw const ImageDecodeFailure();
          await slow.future;
        }
        return thumbnailSync(File(path).readAsBytesSync());
      },
      previewer: (bytes, quad, turns) async =>
          renderPageSync(bytes, quad, turns),
    );
    await tester.pumpWidget(const SizedBox());
    await start(tester);

    final retry = find.byTooltip('Tải lại ảnh xem trước trang 1');
    expect(retry, findsOneWidget);
    expect(failCalls, 1);

    // Another change rebuilds every row; the failed page is not decoded.
    await tester.tap(find.byTooltip('Xoay 90°').last);
    await settle(tester);
    expect(controller.session.pages.last.quarterTurns, 1);
    expect(failCalls, 1);
    expect(retry, findsOneWidget);

    fail = false;
    await tester.tap(retry);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(failCalls, 2);
    final firstRow = find.ancestor(
      of: find.text('Trang 1'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(
        of: firstRow,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);

    slow.complete();
    await settle(tester);
    expect(find.byType(Image), findsNWidgets(2));
    final crop = tester.widget<IconButton>(
      find.ancestor(
        of: find.descendant(of: firstRow, matching: find.byIcon(Icons.crop)),
        matching: find.byType(IconButton),
      ),
    );
    expect(crop.onPressed, isNotNull);
    expect(failCalls, 2);
  });

  /// Replaces [controller] with one that reads the same session and
  /// renders previews with [previewer], and shows it.
  Future<void> restartWith(
    WidgetTester tester,
    Future<Uint8List> Function(Uint8List bytes, PageQuad quad, int turns)
    previewer,
  ) async {
    controller = SessionController(
      store: SessionStore(Directory('${tmp.path}/session')),
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
      thumbnailer: (path) async => thumbnailSync(File(path).readAsBytesSync()),
      previewer: previewer,
    );
    await tester.pumpWidget(const SizedBox());
    await start(tester);
  }

  testWidgets('list shows the cropped preview (XS-13 AC-1)', (tester) async {
    await start(tester, pages: 1);
    await tester.runAsync(
      () => controller.updatePage(
        controller.session.pages.single.rotatedClockwise(),
      ),
    );
    // A recognisable 2 × 1 PNG stands in for the rendered preview.
    final marker = img.encodePng(img.Image(width: 2, height: 1));
    final turnsSeen = <int>[];
    await restartWith(tester, (bytes, quad, turns) async {
      turnsSeen.add(turns);
      return marker;
    });

    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(
      image,
      isA<ResizeImage>().having(
        (r) => (r.imageProvider as MemoryImage).bytes,
        'bytes',
        same(marker),
      ),
    );
    expect(turnsSeen, [1]);
    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(RotatedBox)),
      findsNothing,
      reason: 'the rotation is inside the preview',
    );

    final thumbnail = await tester.runAsync(
      () => controller.thumbnailFor(controller.session.pages.single),
    );
    await tester.tap(find.byTooltip('Chỉnh góc'));
    await tester.pumpAndSettle();
    final editor = tester.widget<QuadEditorScreen>(
      find.byType(QuadEditorScreen),
    );
    expect(editor.thumbnailBytes, same(thumbnail));
    expect(editor.thumbnailBytes, isNot(marker));
  });

  testWidgets('the preview of an older revision is not shown while the new '
      'one renders (XS-13 AC-3)', (tester) async {
    await start(tester, pages: 1);
    final upright = img.encodePng(img.Image(width: 2, height: 1));
    final turned = img.encodePng(img.Image(width: 1, height: 2));
    final pending = Completer<Uint8List>();
    await restartWith(
      tester,
      (bytes, quad, turns) =>
          turns == 0 ? Future<Uint8List>.value(upright) : pending.future,
    );
    Uint8List? shown() {
      final images = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Image),
      );
      if (images.evaluate().isEmpty) return null;
      final image = tester.widget<Image>(images).image as ResizeImage;
      return (image.imageProvider as MemoryImage).bytes;
    }

    expect(shown(), same(upright));

    await tester.tap(find.byTooltip('Xoay 90°'));
    // Not settle(): the tile's spinner keeps animating while it waits.
    for (var i = 0; i < 100 && (controller.busy || i < 5); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(controller.busy, isFalse);
    expect(shown(), isNull, reason: 'revision 0 must not stand in for 1');

    pending.complete(turned);
    await tester.pump();
    await tester.pump();
    expect(shown(), same(turned));
  });

  testWidgets('a failed cropped preview shows the error tile and is '
      'rendered again on retry (XS-13 AC-4)', (tester) async {
    await start(tester, pages: 1);
    var fail = true;
    var calls = 0;
    await restartWith(tester, (bytes, quad, turns) async {
      calls++;
      if (fail) throw const ImageDecodeFailure();
      return renderPageSync(bytes, quad, turns);
    });

    final retry = find.byTooltip('Tải lại ảnh xem trước trang 1');
    expect(retry, findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(calls, 1);

    fail = false;
    await tester.tap(retry);
    await settle(tester);

    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('the thumbnail is decoded at the size of its tile (F-022)', (
    tester,
  ) async {
    await start(tester, pages: 1);
    final image = tester.widget<Image>(find.byType(Image)).image;
    final px = (72 * tester.view.devicePixelRatio).ceil();
    expect(
      image,
      isA<ResizeImage>()
          .having((r) => r.width, 'width', px)
          .having((r) => r.height, 'height', px)
          .having((r) => r.policy, 'policy', ResizeImagePolicy.fit),
    );
  });

  testWidgets('while the session is opening, a loading state replaces the '
      'empty text (F-021)', (tester) async {
    final handle = tester.ensureSemantics();
    final store = HeldStore(Directory('${tmp.path}/session'));
    controller = SessionController(
      store: store,
      source: source,
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: sharer,
    );
    await tester.pumpWidget(XScannerApp(controller: controller));
    for (var i = 0; i < 500 && !store.loading.isCompleted; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    await tester.pump();
    expect(store.loading.isCompleted, isTrue);

    expect(find.text('Đang mở phiên…'), findsOneWidget);
    expect(find.text(_empty), findsNothing);
    expect(find.text('Chụp'), findsNothing);
    expect(find.text('Nhập ảnh'), findsNothing);
    expect(find.bySemanticsLabel('Đang xử lý'), findsOneWidget);

    store.hold.complete();
    await settle(tester);
    expect(find.text('Đang mở phiên…'), findsNothing);
    expect(find.text(_empty), findsOneWidget);
    expect(find.bySemanticsLabel('Đang xử lý'), findsNothing);
    handle.dispose();
  });

  testWidgets('a failed save shows the saveFailed message (F-028)', (
    tester,
  ) async {
    await start(tester, pages: 1);
    // Make the next save fail: the store refuses a page whose original is
    // missing, so remove the original of the page before rotating it.
    await tester.runAsync(
      () => controller.originalFile(controller.session.pages.single).delete(),
    );
    await tester.tap(find.byTooltip('Xoay 90°'));
    await settle(tester);

    expect(
      find.text(
        'Không lưu được (có thể bộ nhớ đầy). Phiên giữ nguyên như trước.',
      ),
      findsOneWidget,
    );
    expect(controller.session.pages.single.quarterTurns, 0);
    expect(find.text('Trang 1'), findsOneWidget);
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

  /// Runs the "Move down" accessibility action of the row of page 1, as
  /// TalkBack does.
  void moveFirstPageDownBySemantics(WidgetTester tester) {
    final label = WidgetsLocalizations.of(tester.element(find.text('Trang 1')))
        .reorderItemDown;
    final action = CustomSemanticsAction.getIdentifier(
      CustomSemanticsAction(label: label),
    );
    // With two pages only the row of page 1 can move down.
    final row = find.semantics.byPredicate(
      (node) =>
          node.getSemanticsData().customSemanticsActionIds?.contains(action) ??
          false,
    );
    expect(row, findsOne, reason: 'row of page 1 offers "$label"');
    tester.semantics.performAction(
      row,
      SemanticsAction.customAction,
      args: action,
    );
  }

  testWidgets('the Move down accessibility action reorders when idle '
      '(F-051)', (tester) async {
    final handle = tester.ensureSemantics();
    await start(tester, pages: 2);
    final [a, b] = [for (final p in controller.session.pages) p.id];

    moveFirstPageDownBySemantics(tester);
    await settle(tester);

    expect([for (final p in controller.session.pages) p.id], [b, a]);
    handle.dispose();
  });

  testWidgets('the Move down accessibility action does nothing while busy '
      '(F-051)', (tester) async {
    final handle = tester.ensureSemantics();
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
    // Lets the format sheet finish closing so the rows are reachable again.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('PNG'), findsNothing);
    expect(sharer.shared, hasLength(1));
    expect(controller.busy, isTrue);

    moveFirstPageDownBySemantics(tester);
    await tester.pump();

    gate.complete();
    await settle(tester);
    expect([for (final p in controller.session.pages) p.id], before);
    handle.dispose();
  });

  testWidgets('export is only offered when there are pages', (tester) async {
    await start(tester);
    expect(find.byTooltip('Xuất'), findsNothing);
  });

  testWidgets('exporting as PDF shares one X-Scanner.pdf (AC-6) (F-029)', (
    tester,
  ) async {
    await start(tester, pages: 2);
    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('JPG'), findsOneWidget);
    expect(find.text('PNG'), findsOneWidget);

    await tester.tap(find.text('PDF'));
    await settle(tester);
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single, ['X-Scanner.pdf']);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('PDF'), findsNothing, reason: 'sheet closed');
  });

  testWidgets('choosing JPG or PNG shares one named image per page (F-029)', (
    tester,
  ) async {
    await start(tester, pages: 2);
    for (final (label, ext) in [('JPG', 'jpg'), ('PNG', 'png')]) {
      await tester.tap(find.byTooltip('Xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await settle(tester);
      expect(sharer.shared.last, [
        'X-Scanner-trang-01.$ext',
        'X-Scanner-trang-02.$ext',
      ]);
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

  testWidgets('LC-1: capture, move a corner, save and export as PDF in one '
      'flow (F-053)', (tester) async {
    await start(tester);
    source.captures.add(png());
    await tester.tap(find.text('Chụp'));
    await settle(tester);
    expect(find.text('Trang 1'), findsOneWidget);
    expect(controller.session.pages.single.quad, PageQuad.fullFrame);

    await tester.tap(find.byTooltip('Chỉnh góc'));
    await tester.pumpAndSettle();
    final corner = find.bySemanticsLabel('Góc trên trái');
    final start0 = tester.getCenter(corner);
    final gesture = await tester.startGesture(start0);
    await gesture.moveTo(start0 + const Offset(20, 30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Góc này làm khung không hợp lệ.'), findsNothing);
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    expect(find.text('Trang 1'), findsOneWidget);
    final quad = controller.session.pages.single.quad;
    expect(quad, isNot(PageQuad.fullFrame));
    expect(quad.topLeft.x, greaterThan(0));
    expect(quad.topLeft.y, greaterThan(0));

    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await settle(tester);
    expect(sharer.shared, [
      ['X-Scanner.pdf'],
    ]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('export shows page progress and can be cancelled (AC-7)', (
    tester,
  ) async {
    final renderer = HeldRenderer(holds: {1, 2});
    // Created outside the fake clock, like in setUp, so its queue runs on
    // the real I/O of start().
    await tester.runAsync(() async {
      controller = SessionController(
        store: SessionStore(Directory('${tmp.path}/session')),
        source: source,
        exporter: PageExporter(
          exportDir: Directory('${tmp.path}/exports'),
          renderer: renderer.call,
        ),
        sharer: sharer,
        thumbnailer: (path) async =>
            thumbnailSync(File(path).readAsBytesSync()),
        previewer: (bytes, quad, turns) async =>
            renderPageSync(bytes, quad, turns),
      );
    });
    await start(tester, pages: 3);

    /// Runs real I/O until the renderer has been called [n] times, then
    /// lets the format sheet finish closing.
    Future<void> waitForRender(int n) async {
      for (var i = 0; i < 500 && renderer.calls < n; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      expect(renderer.calls, n);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    double? progress() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value;

    await tester.tap(find.byTooltip('Xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JPG'));
    await waitForRender(1);
    expect(find.text('Đang xuất trang 1/3'), findsOneWidget);
    expect(progress(), 0);
    expect(find.text('Chụp'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Chụp'), findsNothing);
    expect(controller.busy, isTrue);

    renderer.release(1);
    await waitForRender(2);
    expect(find.text('Đang xuất trang 2/3'), findsOneWidget);
    expect(progress(), closeTo(1 / 3, 1e-9));

    await tester.tap(find.text('Huỷ'));
    await tester.pump();
    // Until the page being rendered is done, the request shows and the
    // button cannot be pressed again for nothing.
    expect(find.text('Đang huỷ…'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    renderer.release(2);
    await settle(tester);

    expect(renderer.calls, 2);
    expect(sharer.shared, isEmpty);
    expect(find.text('Đã huỷ xuất.'), findsOneWidget);
    expect(find.textContaining('Đang xuất trang'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Chụp'), findsOneWidget);
    expect(find.text('Nhập ảnh'), findsOneWidget);
    expect(controller.session.pages, hasLength(3));
  });
}
