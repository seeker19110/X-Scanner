import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/app/theme.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/export/export_job.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/storage/session_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/quad_editor_screen.dart';
import 'package:x_scanner/ui/review_screen.dart';
import 'package:x_scanner/ui/session_controller.dart';

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

/// [SessionStore] whose [load] waits for [hold] once [loading] completes.
class _HeldStore extends SessionStore {
  _HeldStore(super.root);

  final Completer<void> hold = Completer<void>();
  final Completer<void> loading = Completer<void>();

  @override
  Future<SessionLoadResult> load() async {
    loading.complete();
    await hold.future;
    return super.load();
  }
}

/// A synthetic 40 × 30 PNG used as every thumbnail; no real images.
final Uint8List _thumb = img.encodePng(
  img.fill(img.Image(width: 40, height: 30), color: img.ColorRgb8(90, 90, 90)),
);

/// Renders the cropped preview in the test isolate: isolates do not run
/// under the fake clock of widget tests.
Future<Uint8List> _preview(Uint8List bytes, PageQuad quad, int turns) async =>
    renderPageSync(bytes, quad, turns);

/// Runs Android tap target, labelled tap target and text contrast checks.
Future<void> _expectGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('a11y_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  for (final brightness in Brightness.values) {
    final themeMode = brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    testWidgets('review screen with a page meets the a11y guidelines in '
        '${brightness.name} theme (F-011)', (tester) async {
      final handle = tester.ensureSemantics();
      final source = _Source();
      // Created outside the fake clock, like in setUp of the other widget
      // tests, so its queue runs on the real I/O below.
      final controller = (await tester.runAsync(() async {
        final c = SessionController(
          store: SessionStore(Directory('${tmp.path}/session')..createSync()),
          source: source,
          exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
          sharer: _Sharer(),
          thumbnailer: (_) async => _thumb,
          previewer: _preview,
        );
        final file = File('${tmp.path}/p.png')..writeAsBytesSync(_thumb);
        source.captures.add(file.path);
        await c.capture();
        return c;
      }))!;
      expect(controller.session.pages, hasLength(1));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: ReviewScreen(
            controller: controller,
            themeMode: themeMode,
            onToggleTheme: () {},
          ),
        ),
      );
      // The cached preview future completes on the real event loop.
      await tester.runAsync(
        () => controller.croppedPreviewFor(controller.session.pages.single),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trang 1'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await _expectGuidelines(tester);
      handle.dispose();
    });

    testWidgets('review screen with a failed thumbnail meets the a11y '
        'guidelines in ${brightness.name} theme (F-020)', (tester) async {
      final handle = tester.ensureSemantics();
      final source = _Source();
      // The page is added with a working decoder; a second controller then
      // opens the saved session with one that fails.
      final controller = (await tester.runAsync(() async {
        SessionController make(Future<Uint8List> Function(String) thumbs) =>
            SessionController(
              store: SessionStore(Directory('${tmp.path}/session')),
              source: source,
              exporter: PageExporter(
                exportDir: Directory('${tmp.path}/exports'),
              ),
              sharer: _Sharer(),
              thumbnailer: thumbs,
              previewer: _preview,
            );
        Directory('${tmp.path}/session').createSync();
        final file = File('${tmp.path}/p.png')..writeAsBytesSync(_thumb);
        source.captures.add(file.path);
        await make((_) async => _thumb).capture();
        final c = make((_) async => throw const ImageDecodeFailure());
        await c.restore();
        // Fails on the real event loop; the screen then shows the error.
        await c
            .croppedPreviewFor(c.session.pages.single)
            .then<void>((_) {}, onError: (Object _) {});
        return c;
      }))!;
      expect(controller.session.pages, hasLength(1));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: ReviewScreen(
            controller: controller,
            themeMode: themeMode,
            onToggleTheme: () {},
          ),
        ),
      );
      // Lets any preview future made on the real event loop report.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.byTooltip('Tải lại ảnh xem trước trang 1'), findsOneWidget);

      await _expectGuidelines(tester);
      handle.dispose();
    });

    Widget screen(SessionController controller) => MaterialApp(
      theme: buildTheme(brightness),
      home: ReviewScreen(
        controller: controller,
        themeMode: themeMode,
        onToggleTheme: () {},
      ),
    );

    testWidgets('empty review screen meets the a11y guidelines in '
        '${brightness.name} theme (F-056)', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = SessionController(
        store: SessionStore(Directory('${tmp.path}/session')..createSync()),
        source: _Source(),
        exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
        sharer: _Sharer(),
        thumbnailer: (_) async => _thumb,
      );

      await tester.pumpWidget(screen(controller));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa có trang nào. Chụp hoặc nhập ảnh để bắt đầu.'),
        findsOneWidget,
      );
      expect(find.text('Chụp'), findsOneWidget);
      expect(find.text('Nhập ảnh'), findsOneWidget);

      await _expectGuidelines(tester);
      handle.dispose();
    });

    testWidgets('review screen while the session is opening meets the a11y '
        'guidelines in ${brightness.name} theme (F-056)', (tester) async {
      final handle = tester.ensureSemantics();
      final store = _HeldStore(Directory('${tmp.path}/session')..createSync());
      final controller = SessionController(
        store: store,
        source: _Source(),
        exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
        sharer: _Sharer(),
        thumbnailer: (_) async => _thumb,
      );
      await tester.pumpWidget(screen(controller));
      unawaited(controller.restore());
      // Real I/O runs until the store holds the load.
      for (var i = 0; i < 500 && !store.loading.isCompleted; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
      // The spinners never settle, so frames are pumped one at a time.
      await tester.pump();
      expect(store.loading.isCompleted, isTrue);
      expect(find.text('Đang mở phiên…'), findsOneWidget);
      expect(find.text('Chụp'), findsNothing);

      await _expectGuidelines(tester);

      store.hold.complete();
      for (var i = 0; i < 500 && controller.busy; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      expect(controller.busy, isFalse);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('review screen while exporting meets the a11y guidelines in '
        '${brightness.name} theme (XS-12a AC-7)', (tester) async {
      final handle = tester.ensureSemantics();
      final source = _Source();
      final hold = Completer<void>();
      final controller = (await tester.runAsync(() async {
        final c = SessionController(
          store: SessionStore(Directory('${tmp.path}/session')..createSync()),
          source: source,
          exporter: PageExporter(
            exportDir: Directory('${tmp.path}/exports'),
            // Holds the first page so the export stays in progress.
            renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async {
              await hold.future;
              return Uint8List.fromList([1, 2, 3]);
            },
          ),
          sharer: _Sharer(),
          thumbnailer: (_) async => _thumb,
          previewer: _preview,
        );
        final file = File('${tmp.path}/p.png')..writeAsBytesSync(_thumb);
        source.captures.add(file.path);
        await c.capture();
        unawaited(c.exportAndShare(ExportFormat.jpeg));
        for (
          var i = 0;
          i < 500 && c.exportJob?.state != ExportState.running;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        return c;
      }))!;

      expect(controller.exportJob?.state, ExportState.running);

      await tester.pumpWidget(screen(controller));
      // The cached preview future completes on the real event loop.
      await tester.runAsync(
        () => controller.croppedPreviewFor(controller.session.pages.single),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Đang xuất trang 1/1'), findsOneWidget);
      final cancel = find.ancestor(
        of: find.text('Huỷ'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(cancel, findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(cancel).onPressed,
        isNotNull,
        reason: 'enabled while busy',
      );
      final size = tester.getSize(cancel);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await _expectGuidelines(tester);

      await tester.tap(cancel);
      hold.complete();
      for (var i = 0; i < 500 && controller.busy; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      expect(controller.busy, isFalse);
      expect(controller.exportJob, isNull);
      await tester.pumpAndSettle();
      expect(find.text('Chụp'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('quad editor meets the a11y guidelines in '
        '${brightness.name} theme (F-011)', (tester) async {
      final handle = tester.ensureSemantics();
      final page = ScanPage(
        id: 'b' * 32,
        originalPath: 'originals/${'b' * 32}.png',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: QuadEditorScreen(page: page, thumbnailBytes: _thumb),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh góc'), findsOneWidget);

      await _expectGuidelines(tester);

      // Undo/redo (XS-13 FR-6): labelled, 48 dp, and checked again enabled.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Xoay 90°'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Hoàn tác'));
      await tester.pumpAndSettle();
      for (final label in ['Hoàn tác', 'Làm lại']) {
        final button = find.ancestor(
          of: find.byTooltip(label),
          matching: find.byType(IconButton),
        );
        expect(button, findsOneWidget, reason: label);
        expect(tester.widget<IconButton>(button).onPressed, isNotNull);
        final size = tester.getSize(button);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
      await _expectGuidelines(tester);
      handle.dispose();
    });
  }
}
