import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/quad_editing.dart';

final PageQuad _base = PageQuad(
  topLeft: const Point<double>(0.1, 0.1),
  topRight: const Point<double>(0.9, 0.1),
  bottomRight: const Point<double>(0.9, 0.9),
  bottomLeft: const Point<double>(0.1, 0.9),
);

void main() {
  test('cornerOf returns each of the four corners', () {
    final quad = PageQuad(
      topLeft: const Point<double>(0.1, 0.2),
      topRight: const Point<double>(0.9, 0.15),
      bottomRight: const Point<double>(0.85, 0.95),
      bottomLeft: const Point<double>(0.05, 0.9),
    );
    expect(cornerOf(quad, QuadCorner.topLeft), quad.topLeft);
    expect(cornerOf(quad, QuadCorner.topRight), quad.topRight);
    expect(cornerOf(quad, QuadCorner.bottomRight), quad.bottomRight);
    expect(cornerOf(quad, QuadCorner.bottomLeft), quad.bottomLeft);
  });

  test('a valid drag moves only that corner', () {
    const to = Point<double>(0.2, 0.15);
    for (final corner in QuadCorner.values) {
      final target = switch (corner) {
        QuadCorner.topLeft => to,
        QuadCorner.topRight => const Point<double>(0.8, 0.15),
        QuadCorner.bottomRight => const Point<double>(0.8, 0.85),
        QuadCorner.bottomLeft => const Point<double>(0.2, 0.85),
      };
      final moved = withCornerMoved(_base, corner, target);
      expect(moved, isNotNull, reason: corner.name);
      for (final other in QuadCorner.values) {
        expect(
          cornerOf(moved!, other),
          other == corner ? target : cornerOf(_base, other),
          reason: '${corner.name} → ${other.name}',
        );
      }
    }
  });

  test('dragging top-left past top-right (self-intersecting) is rejected', () {
    expect(
      withCornerMoved(_base, QuadCorner.topLeft, const Point(0.95, 0.1)),
      isNull,
    );
  });

  test('a drag that makes the quad concave is rejected', () {
    expect(
      withCornerMoved(_base, QuadCorner.topLeft, const Point(0.6, 0.6)),
      isNull,
    );
  });

  test('a drag that leaves less than 1% area is rejected', () {
    final small = PageQuad(
      topLeft: const Point<double>(0.4, 0.4),
      topRight: const Point<double>(0.52, 0.4),
      bottomRight: const Point<double>(0.52, 0.52),
      bottomLeft: const Point<double>(0.4, 0.52),
    );
    expect(
      withCornerMoved(small, QuadCorner.topLeft, const Point(0.45, 0.45)),
      isNull,
    );
  });

  test('targets outside the frame are clamped into [0, 1]', () {
    final moved = withCornerMoved(
      _base,
      QuadCorner.bottomLeft,
      const Point(-0.2, 1.3),
    );
    expect(moved, isNotNull);
    expect(moved!.bottomLeft, const Point<double>(0, 1));
    expect(moved.topLeft, _base.topLeft);
    expect(moved.topRight, _base.topRight);
    expect(moved.bottomRight, _base.bottomRight);
  });

  test('non-finite targets are rejected', () {
    expect(
      withCornerMoved(_base, QuadCorner.topLeft, const Point(double.nan, 0.1)),
      isNull,
    );
  });

  group('display mapping (XS-13 AC-5)', () {
    const points = [
      Point<double>(0, 0),
      Point<double>(1, 0),
      Point<double>(0.2, 0.3),
      Point<double>(0.75, 0.9),
      Point<double>(1, 1),
    ];

    test('display mapping matches the export rotation', () {
      // A 4 × 3 image with one marked pixel, turned like renderPageSync.
      final source = img.Image(width: 4, height: 3);
      source.setPixelRgb(1, 2, 255, 0, 0);
      final mark = Point<double>(1.5 / 4, 2.5 / 3);
      for (var t = 0; t < 4; t++) {
        final turned = img.copyRotate(source, angle: 90 * t);
        final at = toDisplay(mark, t);
        final x = (at.x * turned.width).floor();
        final y = (at.y * turned.height).floor();
        expect(turned.getPixel(x, y).r, 255, reason: 'turns $t');
      }
    });

    test('display mapping round-trips for every turn', () {
      for (final t in [0, 1, 2, 3, 4, -1]) {
        for (final p in points) {
          final back = fromDisplay(toDisplay(p, t), t);
          expect(back.x, closeTo(p.x, 1e-12), reason: 't=$t p=$p');
          expect(back.y, closeTo(p.y, 1e-12), reason: 't=$t p=$p');
        }
      }
    });

    test('one clockwise turn maps (x, y) to (1 - y, x)', () {
      expect(toDisplay(const Point(0, 0), 1), const Point<double>(1, 0));
      final p = toDisplay(const Point(0.2, 0.3), 1);
      expect(p.x, closeTo(0.7, 1e-12));
      expect(p.y, closeTo(0.2, 1e-12));
    });

    test('turns are taken mod 4', () {
      const p = Point<double>(0.2, 0.3);
      expect(toDisplay(p, 0), p);
      expect(toDisplay(p, 4), p);
      expect(toDisplay(p, -1), toDisplay(p, 3));
      expect(toDisplay(p, 2), toDisplay(toDisplay(p, 1), 1));
    });

    test('sourceCorner names the original corner shown at each spot', () {
      for (final shown in QuadCorner.values) {
        expect(sourceCorner(shown, 0), shown);
        expect(sourceCorner(shown, 4), shown);
      }
      expect(sourceCorner(QuadCorner.topRight, 1), QuadCorner.topLeft);
      expect(sourceCorner(QuadCorner.topLeft, 1), QuadCorner.bottomLeft);
      expect(sourceCorner(QuadCorner.topLeft, 2), QuadCorner.bottomRight);
      expect(sourceCorner(QuadCorner.topLeft, 3), QuadCorner.topRight);
      expect(sourceCorner(QuadCorner.topLeft, -1), QuadCorner.topRight);
    });

    test('sourceCorner agrees with toDisplay of the full frame', () {
      for (final t in [0, 1, 2, 3]) {
        for (final shown in QuadCorner.values) {
          final source = sourceCorner(shown, t);
          expect(
            toDisplay(cornerOf(PageQuad.fullFrame, source), t),
            cornerOf(PageQuad.fullFrame, shown),
            reason: 't=$t shown=${shown.name}',
          );
        }
      }
    });
  });
}
