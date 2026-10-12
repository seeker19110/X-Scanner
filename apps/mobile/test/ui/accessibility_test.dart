import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/app/theme.dart';
import 'package:x_scanner/core/scan_page.dart';
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

/// A synthetic 40 × 30 PNG used as every thumbnail; no real images.
final Uint8List _thumb = img.encodePng(
  img.fill(img.Image(width: 40, height: 30), color: img.ColorRgb8(90, 90, 90)),
);

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
        () => controller.thumbnailFor(controller.session.pages.single),
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
            );
        Directory('${tmp.path}/session').createSync();
        final file = File('${tmp.path}/p.png')..writeAsBytesSync(_thumb);
        source.captures.add(file.path);
        await make((_) async => _thumb).capture();
        final c = make((_) async => throw const ImageDecodeFailure());
        await c.restore();
        // Fails on the real event loop; the screen then shows the error.
        await c
            .thumbnailFor(c.session.pages.single)
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
      handle.dispose();
    });
  }
}
