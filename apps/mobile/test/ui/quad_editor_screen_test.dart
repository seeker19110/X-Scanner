import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/app/theme.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/quad_editing.dart';
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

/// Opens the editor on [page] from a launcher route; the returned list
/// gets what the editor pops.
Future<List<ScanPage?>> _open(WidgetTester tester, {ScanPage? page}) async {
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
                  builder: (_) => QuadEditorScreen(
                    page: page ?? _page,
                    thumbnailBytes: _thumb,
                  ),
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
    // Nothing changed, so "Lưu" closes without a page (XS-13 FR-7).
    expect(await _save(tester, results), isNull);
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

  testWidgets('rotated page is shown upright and drags move the right corner '
      '(XS-13 AC-5)', (tester) async {
    final rotated = ScanPage(
      id: _page.id,
      originalPath: _page.originalPath,
      quad: _base,
      quarterTurns: 1,
    );
    final results = await _open(tester, page: rotated);
    final box = tester.widget<RotatedBox>(find.byType(RotatedBox));
    expect(box.quarterTurns, 1);

    final tl = tester.getCenter(_handle('Góc trên trái'));
    final tr = tester.getCenter(_handle('Góc trên phải'));
    final bl = tester.getCenter(_handle('Góc dưới trái'));
    final pxPerUnitX = (tr.dx - tl.dx) / 0.8;
    final pxPerUnitY = (bl.dy - tl.dy) / 0.8;
    // The 400 × 300 image is shown 300 wide and 400 tall.
    expect(pxPerUnitX / pxPerUnitY, closeTo(300 / 400, 1e-3));

    await _dragHandle(tester, 'Góc trên trái', const Offset(20, 30));

    final saved = (await _save(tester, results))!;
    expect(saved.quarterTurns, 1);
    final quad = saved.quad;
    // Shown top-left after one turn is the original bottom-left.
    final shown = toDisplay(quad.bottomLeft, 1);
    expect(shown.x, closeTo(0.1 + 20 / pxPerUnitX, 1e-6));
    expect(shown.y, closeTo(0.1 + 30 / pxPerUnitY, 1e-6));
    expect(quad.topLeft, _base.topLeft);
    expect(quad.topRight, _base.topRight);
    expect(quad.bottomRight, _base.bottomRight);
  });

  group('undo and redo', () {
    Finder undo() => find.widgetWithIcon(IconButton, Icons.undo);
    Finder redo() => find.widgetWithIcon(IconButton, Icons.redo);
    bool enabled(WidgetTester tester, Finder button) =>
        tester.widget<IconButton>(button).onPressed != null;
    List<Offset> handles(WidgetTester tester) => [
      for (final label in [
        'Góc trên trái',
        'Góc trên phải',
        'Góc dưới phải',
        'Góc dưới trái',
      ])
        tester.getCenter(_handle(label)),
    ];

    testWidgets('undo and redo buttons follow the history (XS-13 AC-6)', (
      tester,
    ) async {
      final results = await _open(tester);
      expect(find.byTooltip('Hoàn tác'), findsOneWidget);
      expect(find.byTooltip('Làm lại'), findsOneWidget);
      expect(enabled(tester, undo()), isFalse);
      expect(enabled(tester, redo()), isFalse);
      final start = handles(tester);

      await _dragHandle(tester, 'Góc trên trái', const Offset(20, 30));
      final dragged = handles(tester);
      expect(dragged, isNot(start));
      await tester.tap(find.text('Xoay 90°'));
      await tester.pumpAndSettle();
      final turned = handles(tester);
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
      expect(enabled(tester, undo()), isTrue);
      expect(enabled(tester, redo()), isFalse);

      await tester.tap(undo());
      await tester.pumpAndSettle();
      expect(handles(tester), turned);
      expect(find.text('Xoay: 90°'), findsOneWidget);
      await tester.tap(undo());
      await tester.pumpAndSettle();
      expect(handles(tester), dragged);
      expect(find.text('Xoay: 0°'), findsOneWidget);
      await tester.tap(undo());
      await tester.pumpAndSettle();
      expect(handles(tester), start);
      expect(enabled(tester, undo()), isFalse);
      expect(enabled(tester, redo()), isTrue);

      await tester.tap(redo());
      await tester.pumpAndSettle();
      expect(handles(tester), dragged);
      expect(enabled(tester, undo()), isTrue);
      expect(enabled(tester, redo()), isTrue);

      // A new step after undo drops the redo branch.
      await tester.tap(find.text('Xoay 90°'));
      await tester.pumpAndSettle();
      expect(enabled(tester, redo()), isFalse);
      final saved = (await _save(tester, results))!;
      expect(saved.quarterTurns, 1);
      expect(saved.quad, isNot(_base));
    });

    testWidgets('one drag with many moves is one undo step (XS-13 AC-6)', (
      tester,
    ) async {
      await _open(tester);
      final start = handles(tester);
      final from = tester.getCenter(_handle('Góc trên trái'));
      final gesture = await tester.startGesture(from);
      for (var i = 1; i <= 5; i++) {
        await gesture.moveTo(from + Offset(8.0 * i, 6.0 * i));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(handles(tester), isNot(start));

      await tester.tap(undo());
      await tester.pumpAndSettle();
      expect(handles(tester), start);
      expect(enabled(tester, undo()), isFalse);
    });
  });

  group('leaving the editor', () {
    const ask = 'Bỏ thay đổi?';

    testWidgets('back with changes asks before discarding (XS-13 AC-7)', (
      tester,
    ) async {
      final results = await _open(tester);
      await tester.tap(find.text('Xoay 90°'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(ask), findsOneWidget);
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text(ask), findsNothing);
      expect(find.text('Chỉnh góc'), findsOneWidget);
      expect(find.text('Xoay: 90°'), findsOneWidget);
      expect(results, isEmpty);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh góc'), findsNothing);
      expect(results, [null]);
    });

    testWidgets('no changes closes without asking (XS-13 AC-7)', (
      tester,
    ) async {
      final results = await _open(tester);
      await _dragHandle(tester, 'Góc trên trái', const Offset(20, 30));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(ask), findsNothing);
      expect(results, [null]);
    });

    testWidgets('saving without changes returns null (XS-13 AC-7)', (
      tester,
    ) async {
      final results = await _open(tester);
      await tester.tap(find.text('Xoay 90°'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
      await tester.pumpAndSettle();
      expect(await _save(tester, results), isNull);
    });
  });

  testWidgets('loupe shows only while dragging (XS-13 AC-8)', (tester) async {
    await _open(tester);
    expect(find.byType(RawMagnifier), findsNothing);
    final from = tester.getCenter(_handle('Góc trên trái'));
    final gesture = await tester.startGesture(from);
    await gesture.moveTo(from + const Offset(20, 30));
    await tester.pump();
    expect(find.byType(RawMagnifier), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(RawMagnifier), findsNothing);
  });

  group('semantic nudge', () {
    const right = CustomSemanticsAction(label: 'Dịch sang phải');

    for (final turns in [0, 1]) {
      testWidgets('semantic nudge moves the shown corner, $turns turn(s) '
          '(XS-13 AC-9)', (tester) async {
        final handle = tester.ensureSemantics();
        final page = ScanPage(
          id: _page.id,
          originalPath: _page.originalPath,
          quad: _base,
          quarterTurns: turns,
        );
        final results = await _open(tester, page: page);
        final before = toDisplay(
          cornerOf(_base, sourceCorner(QuadCorner.topLeft, turns)),
          turns,
        );

        tester.semantics.customAction(
          find.semantics.byLabel('Góc trên trái'),
          right,
        );
        await tester.pumpAndSettle();

        expect(find.text(_invalid), findsNothing);
        final saved = (await _save(tester, results))!;
        final after = toDisplay(
          cornerOf(saved.quad, sourceCorner(QuadCorner.topLeft, turns)),
          turns,
        );
        expect(after.x, closeTo(before.x + 0.01, 1e-9));
        expect(after.y, closeTo(before.y, 1e-9));
        handle.dispose();
      });
    }

    testWidgets('an invalid semantic nudge is rejected (XS-13 AC-9)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final narrow = PageQuad(
        topLeft: const Point<double>(0.1, 0.1),
        topRight: const Point<double>(0.105, 0.1),
        bottomRight: const Point<double>(0.9, 0.9),
        bottomLeft: const Point<double>(0.1, 0.9),
      );
      final page = ScanPage(
        id: _page.id,
        originalPath: _page.originalPath,
        quad: narrow,
      );
      final results = await _open(tester, page: page);

      tester.semantics.customAction(
        find.semantics.byLabel('Góc trên trái'),
        right,
      );
      await tester.pump();

      expect(find.text(_invalid), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
            .onPressed,
        isNull,
      );
      await tester.pumpAndSettle();
      expect(await _save(tester, results), isNull);
      handle.dispose();
    });
  });

  testWidgets('a step that changes nothing is not recorded (XS-13 AC-6)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final page = ScanPage(id: _page.id, originalPath: _page.originalPath);
    final results = await _open(tester, page: page);
    final undo = find.widgetWithIcon(IconButton, Icons.undo);

    await tester.tap(find.text('Đặt lại'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(undo).onPressed, isNull);

    // The full frame's top-left is at (0, 0): moving left only clamps.
    tester.semantics.customAction(
      find.semantics.byLabel('Góc trên trái'),
      const CustomSemanticsAction(label: 'Dịch sang trái'),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(undo).onPressed, isNull);
    expect(await _save(tester, results), isNull);
    handle.dispose();
  });

  testWidgets('saving during a drag keeps the dragged corner (XS-13 AC-7)', (
    tester,
  ) async {
    final results = await _open(tester);
    final from = tester.getCenter(_handle('Góc trên trái'));
    final drag = await tester.startGesture(from);
    await drag.moveTo(from + const Offset(20, 30));
    await tester.pump();

    // A second finger presses "Lưu" before the first is lifted.
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    await drag.up();
    expect(results, hasLength(1));
    expect(results.single?.quad.topLeft, isNot(_base.topLeft));
  });

  testWidgets('saved page has a higher revision after undo and a new edit '
      '(XS-13 AC-10)', (tester) async {
    final page = ScanPage(
      id: _page.id,
      originalPath: _page.originalPath,
      quad: _base,
      revision: 3,
    );
    final results = await _open(tester, page: page);
    await _dragHandle(tester, 'Góc trên trái', const Offset(20, 30));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
    await tester.pumpAndSettle();
    final tl = tester.getCenter(_handle('Góc trên trái'));
    final tr = tester.getCenter(_handle('Góc trên phải'));
    final pxPerUnitX = (tr.dx - tl.dx) / 0.8;
    await _dragHandle(tester, 'Góc trên trái', const Offset(40, 0));

    final saved = (await _save(tester, results))!;
    expect(saved.revision, greaterThan(3));
    expect(saved.quad.topLeft.x, closeTo(0.1 + 40 / pxPerUnitX, 1e-6));
    expect(saved.quad.topLeft.y, closeTo(0.1, 1e-6));
  });
}
