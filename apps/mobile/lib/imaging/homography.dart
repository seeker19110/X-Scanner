import 'dart:math';

/// Immutable projective map (3×3 homography) from the unit square onto a
/// quadrilateral.
///
/// Unlike bilinear interpolation it maps straight lines to straight lines,
/// which is what a flat page photographed in perspective requires.
class Homography {
  const Homography._(
    this._a,
    this._b,
    this._c,
    this._d,
    this._e,
    this._f,
    this._g,
    this._h,
  );

  /// Maps (0,0)→[topLeft], (1,0)→[topRight], (1,1)→[bottomRight] and
  /// (0,1)→[bottomLeft] using the closed-form square-to-quad solution
  /// (Heckbert 1989).
  ///
  /// Throws [ArgumentError] for non-finite corners or when [topRight],
  /// [bottomRight] and [bottomLeft] are (nearly) collinear.
  factory Homography.unitSquareTo({
    required Point<double> topLeft,
    required Point<double> topRight,
    required Point<double> bottomRight,
    required Point<double> bottomLeft,
  }) {
    final corners = [topLeft, topRight, bottomRight, bottomLeft];
    if (!corners.every((p) => p.x.isFinite && p.y.isFinite)) {
      throw ArgumentError('Corners must be finite');
    }
    final (x0, y0) = (topLeft.x, topLeft.y);
    final (x1, y1) = (topRight.x, topRight.y);
    final (x2, y2) = (bottomRight.x, bottomRight.y);
    final (x3, y3) = (bottomLeft.x, bottomLeft.y);

    final dx1 = x1 - x2;
    final dx2 = x3 - x2;
    final dx3 = x0 - x1 + x2 - x3;
    final dy1 = y1 - y2;
    final dy2 = y3 - y2;
    final dy3 = y0 - y1 + y2 - y3;

    final det = dx1 * dy2 - dx2 * dy1;
    if (!(det.abs() > _minDeterminant)) {
      throw ArgumentError('Corners are degenerate (collinear)');
    }
    final g = (dx3 * dy2 - dx2 * dy3) / det;
    final h = (dx1 * dy3 - dx3 * dy1) / det;

    return Homography._(
      x1 - x0 + g * x1,
      x3 - x0 + h * x3,
      x0,
      y1 - y0 + g * y1,
      y3 - y0 + h * y3,
      y0,
      g,
      h,
    );
  }

  /// Determinants at or below this magnitude are treated as degenerate.
  static const double _minDeterminant = 1e-12;

  final double _a;
  final double _b;
  final double _c;
  final double _d;
  final double _e;
  final double _f;
  final double _g;
  final double _h;

  /// Maps the unit-square point ([u], [v]) into the quadrilateral.
  ///
  /// For a strictly convex quad the projective denominator stays positive
  /// over the whole unit square.
  Point<double> map(double u, double v) {
    final w = _g * u + _h * v + 1;
    return Point<double>(
      (_a * u + _b * v + _c) / w,
      (_d * u + _e * v + _f) / w,
    );
  }
}
