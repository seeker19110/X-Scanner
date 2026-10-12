import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
}
