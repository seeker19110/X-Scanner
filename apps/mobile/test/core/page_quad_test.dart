import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';

/// Builds a quad from eight numbers: TL, TR, BR, BL as (x, y) pairs.
PageQuad quadOf(List<double> c) => PageQuad(
  topLeft: Point<double>(c[0], c[1]),
  topRight: Point<double>(c[2], c[3]),
  bottomRight: Point<double>(c[4], c[5]),
  bottomLeft: Point<double>(c[6], c[7]),
);

void main() {
  test('accepts a valid clockwise quad', () {
    final quad = quadOf([0.1, 0.2, 0.9, 0.15, 0.85, 0.95, 0.05, 0.9]);

    expect(quad.topLeft, const Point<double>(0.1, 0.2));
    expect(quad.topRight, const Point<double>(0.9, 0.15));
    expect(quad.bottomRight, const Point<double>(0.85, 0.95));
    expect(quad.bottomLeft, const Point<double>(0.05, 0.9));

    final full = quadOf([0, 0, 1, 0, 1, 1, 0, 1]);
    expect(full, PageQuad.fullFrame);
    expect(full.hashCode, PageQuad.fullFrame.hashCode);
    expect(PageQuad.fullFrame.topLeft, const Point<double>(0, 0));
    expect(PageQuad.fullFrame.bottomRight, const Point<double>(1, 1));
  });

  test('equality compares all four corners', () {
    final a = quadOf([0.1, 0.1, 0.9, 0.1, 0.9, 0.9, 0.1, 0.9]);
    final b = quadOf([0.1, 0.1, 0.9, 0.1, 0.9, 0.9, 0.1, 0.9]);
    final c = quadOf([0.1, 0.1, 0.9, 0.1, 0.9, 0.9, 0.2, 0.9]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });

  group('rejects', () {
    void expectRejected(List<double> c) =>
        expect(() => quadOf(c), throwsArgumentError);

    test('negative coordinate', () {
      expectRejected([-0.01, 0, 1, 0, 1, 1, 0, 1]);
    });

    test('coordinate greater than 1', () {
      expectRejected([0, 0, 1, 0, 1, 1.01, 0, 1]);
    });

    test('NaN coordinate', () {
      expectRejected([0, 0, 1, double.nan, 1, 1, 0, 1]);
    });

    test('infinite coordinate', () {
      expectRejected([0, 0, 1, 0, double.infinity, 1, 0, 1]);
      expectRejected([double.negativeInfinity, 0, 1, 0, 1, 1, 0, 1]);
    });

    test('self-intersecting quad (bowtie)', () {
      // BR and BL swapped: edges TR->BR and BL->TL cross.
      expectRejected([0, 0, 1, 0, 0, 1, 1, 1]);
    });

    test('concave quad', () {
      // BR pushed inward past the TR-BL diagonal.
      expectRejected([0, 0, 1, 0, 0.3, 0.3, 0, 1]);
    });

    test('counter-clockwise quad', () {
      // Same rectangle traversed TL -> BL -> BR -> TR.
      expectRejected([0, 0, 0, 1, 1, 1, 1, 0]);
    });

    test('three collinear corners', () {
      // TR lies on the straight top edge between TL and BR.
      expectRejected([0, 0, 0.5, 0, 1, 0, 0, 1]);
    });

    test('degenerate quad with repeated corners', () {
      expectRejected([0, 0, 0, 0, 1, 1, 0, 1]);
    });

    test('area below minArea', () {
      // 0.099 x 0.1 rectangle: area 0.0099 < 0.01.
      expectRejected([0, 0, 0.099, 0, 0.099, 0.1, 0, 0.1]);
    });

    test('area exactly minArea is accepted (boundary)', () {
      final quad = quadOf([0, 0, 0.1, 0, 0.1, 0.1, 0, 0.1]);
      expect(quad.topRight, const Point<double>(0.1, 0));
      expect(PageQuad.minArea, 0.01);
    });

    test('area exactly minArea is accepted anywhere in the frame', () {
      // Same 0.1 x 0.1 square translated; floating-point rounding must not
      // make the 1% boundary depend on position.
      expect(quadOf([0.6, 0.6, 0.7, 0.6, 0.7, 0.7, 0.6, 0.7]), isA<PageQuad>());
      expect(
        quadOf([0.3, 0.2, 1.0, 0.2, 1.0, 0.2 + 1 / 70, 0.3, 0.2 + 1 / 70]),
        isA<PageQuad>(),
      );
    });
  });
}
