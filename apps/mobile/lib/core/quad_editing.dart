import 'dart:math';

import 'page_quad.dart';

/// The four draggable corners of a [PageQuad], in clockwise order.
enum QuadCorner { topLeft, topRight, bottomRight, bottomLeft }

/// Returns the position of [corner] in [quad].
Point<double> cornerOf(PageQuad quad, QuadCorner corner) => switch (corner) {
  QuadCorner.topLeft => quad.topLeft,
  QuadCorner.topRight => quad.topRight,
  QuadCorner.bottomRight => quad.bottomRight,
  QuadCorner.bottomLeft => quad.bottomLeft,
};

/// Returns a copy of [quad] with [corner] moved to [to] clamped into
/// `[0, 1] × [0, 1]`, or `null` if the result is not a valid [PageQuad]
/// (self-intersecting, concave, too small or non-finite). The caller keeps
/// the previous quad in that case.
PageQuad? withCornerMoved(PageQuad quad, QuadCorner corner, Point<double> to) {
  final p = Point<double>(_unit(to.x), _unit(to.y));
  Point<double> at(QuadCorner c) => c == corner ? p : cornerOf(quad, c);
  try {
    return PageQuad(
      topLeft: at(QuadCorner.topLeft),
      topRight: at(QuadCorner.topRight),
      bottomRight: at(QuadCorner.bottomRight),
      bottomLeft: at(QuadCorner.bottomLeft),
    );
  } on ArgumentError {
    return null;
  }
}

/// Clamps [v] into `[0, 1]`; NaN stays NaN so [PageQuad] rejects it.
double _unit(double v) => v.clamp(0.0, 1.0);
