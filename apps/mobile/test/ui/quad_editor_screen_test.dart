import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/app/theme.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/ui/quad_editor_screen.dart';

final PageQuad _base = PageQuad(
  topLeft: const Point<double>(0.1, 0.1),
  topRight: const Point<double>(0.9, 0.1),
  bottomRight: const Point<double>(0.9, 0.9),
  bottomLeft: const Point<double>(0.1, 0.9),
);

final ScanPage _page = ScanPage(
  id: 'a' * 32,
  originalPath: 'originals/${'a' * 32}.jpg',
  quad: _base,
);

/// A synthetic 400 × 300 JPEG; no real images are used.
final Uint8List _thumb = img.encodeJpg(img.Image(width: 400, height: 300));

const String _invalid = 'Góc này làm khung không hợp lệ.';

/// Opens the editor from a launcher route; [result] gets what it pops.
Future<List<ScanPage?>> _open(WidgetTester tester) async {
  final results = <ScanPage?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(
              await Navigator.of(context).push<ScanPage>(
                MaterialPageRoute(
                  builder: (_) =>
                      QuadEditorScreen(page: _page, thumbnailBytes: _thumb),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Finder _handle(String label) => find.bySemanticsLabel(label);

/// Moves the handle [label] by [offset] in a single pointer move.
Future<void> _dragHandle(
  WidgetTester tester,
  String label,
  Offset offset,
) async {
  final start = tester.getCenter(_handle(label));
  final gesture = await tester.startGesture(start);
  await gesture.moveTo(start + offset);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<ScanPage?> _save(WidgetTester tester, List<ScanPage?> results) async {
  await tester.tap(find.text('Lưu'));
  await tester.pumpAndSettle();
  expect(results, hasLength(1));
  return results.single;
}

void main() {
  testWidgets('shows four labelled handles with 48 dp touch targets (F-029)', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Chỉnh góc'), findsOneWidget);
    for (final label in [
      'Góc trên trái',
      'Góc trên phải',
      'Góc dưới phải',
      'Góc dưới trái',
    ]) {
      expect(_handle(label), findsOneWidget, reason: label);
      final size = tester.getSize(_handle(label));
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
    }
  });

  testWidgets('rejects an invalid drag and keeps the previous quad (AC-4)', (
    tester,
  ) async {
    final results = await _open(tester);
    final tl = tester.getCenter(_handle('Góc trên trái'));
    final tr = tester.getCenter(_handle('Góc trên phải'));

    await _dragHandle(tester, 'Góc trên trái', Offset(tr.dx - tl.dx + 30, 0));

    expect(find.text(_invalid), findsOneWidget);
    expect(tester.getCenter(_handle('Góc trên trái')), tl);
    final saved = await _save(tester, results);
    expect(saved!.quad, _base);
  });

  testWidgets('a valid drag moves only that corner', (tester) async {
    final results = await _open(tester);
    final tl = tester.getCenter(_handle('Góc trên trái'));
    final tr = tester.getCenter(_handle('Góc trên phải'));
    final bl = tester.getCenter(_handle('Góc dưới trái'));
    final pxPerUnitX = (tr.dx - tl.dx) / 0.8;
    final pxPerUnitY = (bl.dy - tl.dy) / 0.8;

    await _dragHandle(tester, 'Góc trên trái', const Offset(20, 30));

    expect(find.text(_invalid), findsNothing);
    final quad = (await _save(tester, results))!.quad;
    expect(quad.topLeft.x, closeTo(0.1 + 20 / pxPerUnitX, 1e-6));
    expect(quad.topLeft.y, closeTo(0.1 + 30 / pxPerUnitY, 1e-6));
    expect(quad.topRight, _base.topRight);
    expect(quad.bottomRight, _base.bottomRight);
    expect(quad.bottomLeft, _base.bottomLeft);
  });

  testWidgets('reset restores the full frame', (tester) async {
    final results = await _open(tester);
    await tester.tap(find.text('Đặt lại'));
    await tester.pump();
    expect((await _save(tester, results))!.quad, PageQuad.fullFrame);
  });

  testWidgets('rotate turns the page a quarter clockwise', (tester) async {
    final results = await _open(tester);
    expect(find.text('Xoay: 0°'), findsOneWidget);
    await tester.tap(find.text('Xoay 90°'));
    await tester.pump();
    expect(find.text('Xoay: 90°'), findsOneWidget);
    final saved = (await _save(tester, results))!;
    expect(saved.quarterTurns, 1);
    expect(saved.quad, _base);
    expect(saved.id, _page.id);
  });

  testWidgets('going back returns null', (tester) async {
    final results = await _open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
