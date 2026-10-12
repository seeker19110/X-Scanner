import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/imaging/homography.dart';

const double _eps = 1e-9;

/// Builds a homography from eight numbers: TL, TR, BR, BL as (x, y) pairs.
Homography homographyOf(List<double> c) => Homography.unitSquareTo(
  topLeft: Point<double>(c[0], c[1]),
  topRight: Point<double>(c[2], c[3]),
  bottomRight: Point<double>(c[4], c[5]),
  bottomLeft: Point<double>(c[6], c[7]),
);

void expectPoint(Point<double> actual, Point<double> expected) {
  expect(actual.x, closeTo(expected.x, _eps));
  expect(actual.y, closeTo(expected.y, _eps));
}

/// Intersection of lines a1–a2 and b1–b2 (assumed not parallel).
Point<double> intersect(
  Point<double> a1,
  Point<double> a2,
  Point<double> b1,
  Point<double> b2,
) {
  final d1 = a2 - a1;
  final d2 = b2 - b1;
  final denom = d1.x * d2.y - d1.y * d2.x;
  final t = ((b1.x - a1.x) * d2.y - (b1.y - a1.y) * d2.x) / denom;
  return Point<double>(a1.x + t * d1.x, a1.y + t * d1.y);
}

void main() {
  const tl = Point<double>(10, 10);
  const tr = Point<double>(90, 20);
  const br = Point<double>(80, 90);
  const bl = Point<double>(20, 70);
  Homography perspective() => homographyOf([10, 10, 90, 20, 80, 90, 20, 70]);
  Homography rectangle() => homographyOf([5, 7, 105, 7, 105, 57, 5, 57]);

  test('maps the unit corners onto the rectangle corners', () {
    expectPoint(rectangle().map(0, 0), const Point<double>(5, 7));
    expectPoint(rectangle().map(1, 0), const Point<double>(105, 7));
    expectPoint(rectangle().map(1, 1), const Point<double>(105, 57));
    expectPoint(rectangle().map(0, 1), const Point<double>(5, 57));
  });

  test('maps the unit centre onto the rectangle centre', () {
    expectPoint(rectangle().map(0.5, 0.5), const Point<double>(55, 32));
  });

  test('maps the unit corners onto a perspective quad', () {
    expectPoint(perspective().map(0, 0), tl);
    expectPoint(perspective().map(1, 0), tr);
    expectPoint(perspective().map(1, 1), br);
    expectPoint(perspective().map(0, 1), bl);
  });

  test('maps the unit centre onto the diagonal intersection', () {
    // A projective map preserves incidence, so the square's centre (where
    // its diagonals cross) lands where the quad's diagonals cross. Bilinear
    // interpolation would give the corner average (50, 47.5) instead, which
    // is not on both diagonals for a non-parallelogram.
    expectPoint(perspective().map(0.5, 0.5), intersect(tl, br, tr, bl));
  });

  test('keeps collinear points collinear', () {
    final a = perspective().map(0, 0.25);
    final b = perspective().map(0.5, 0.25);
    final c = perspective().map(1, 0.25);
    final cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    expect(cross, closeTo(0, 1e-6));
  });

  group('rejects degenerate corners', () {
    test('three collinear corners', () {
      expect(() => homographyOf([0, 0, 1, 0, 1, 1, 1, 2]), throwsArgumentError);
    });

    test('non-finite corners', () {
      expect(
        () => homographyOf([0, 0, double.nan, 0, 1, 1, 0, 1]),
        throwsArgumentError,
      );
    });
  });
}
