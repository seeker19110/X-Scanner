import 'dart:math';

/// The four page corners in normalized `[0, 1]` coordinates of the original,
/// unrotated image (origin top-left, y pointing down).
///
/// Only strictly convex, clockwise (in y-down space), finite, in-bounds quads
/// with area of at least [minArea] can be constructed; anything else throws
/// [ArgumentError] at creation.
class PageQuad {
  const PageQuad._(
    this.topLeft,
    this.topRight,
    this.bottomRight,
    this.bottomLeft,
  );

  /// Validates the corners and creates a quad, or throws [ArgumentError].
  factory PageQuad({
    required Point<double> topLeft,
    required Point<double> topRight,
    required Point<double> bottomRight,
    required Point<double> bottomLeft,
  }) {
    final corners = [topLeft, topRight, bottomRight, bottomLeft];
    _checkInBounds(corners);
    _checkStrictlyConvexClockwise(corners);
    _checkArea(corners);
    return PageQuad._(topLeft, topRight, bottomRight, bottomLeft);
  }

  /// Minimum allowed area: 1% of the frame.
  static const double minArea = 0.01;

  /// Tolerance for the area check so floating-point rounding of the
  /// shoelace sum cannot make the boundary depend on the quad's position.
  static const double _areaTolerance = 1e-9;

  /// The whole image.
  static const PageQuad fullFrame = PageQuad._(
    Point<double>(0, 0),
    Point<double>(1, 0),
    Point<double>(1, 1),
    Point<double>(0, 1),
  );

  static const List<String> _cornerNames = [
    'topLeft',
    'topRight',
    'bottomRight',
    'bottomLeft',
  ];

  final Point<double> topLeft;
  final Point<double> topRight;
  final Point<double> bottomRight;
  final Point<double> bottomLeft;

  static void _checkInBounds(List<Point<double>> corners) {
    for (var i = 0; i < corners.length; i++) {
      final p = corners[i];
      if (!_isUnit(p.x) || !_isUnit(p.y)) {
        throw ArgumentError.value(
          p,
          _cornerNames[i],
          'must be finite and within [0, 1]',
        );
      }
    }
  }

  /// NaN and infinities fail both comparisons, so they are rejected here too.
  static bool _isUnit(double v) => v >= 0 && v <= 1;

  /// Every turn TL→TR→BR→BL→TL must be a strict right turn in y-down space,
  /// i.e. the cross product of consecutive edges is > 0. For four vertices
  /// this also rules out self-intersection (a bowtie has mixed signs),
  /// concavity, counter-clockwise order and collinear/repeated corners.
  static void _checkStrictlyConvexClockwise(List<Point<double>> corners) {
    final n = corners.length;
    for (var i = 0; i < n; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % n];
      final c = corners[(i + 2) % n];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (!(cross > 0)) {
        throw ArgumentError(
          'Quad must be strictly convex and clockwise '
          '(failed at ${_cornerNames[(i + 1) % n]})',
        );
      }
    }
  }

  static void _checkArea(List<Point<double>> corners) {
    final area = _shoelaceArea(corners);
    if (area < minArea - _areaTolerance) {
      throw ArgumentError.value(area, 'area', 'must be at least $minArea');
    }
  }

  static double _shoelaceArea(List<Point<double>> corners) {
    var twiceArea = 0.0;
    for (var i = 0; i < corners.length; i++) {
      final p = corners[i];
      final q = corners[(i + 1) % corners.length];
      twiceArea += p.x * q.y - q.x * p.y;
    }
    return twiceArea.abs() / 2;
  }

  @override
  bool operator ==(Object other) =>
      other is PageQuad &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() =>
      'PageQuad($topLeft, $topRight, $bottomRight, $bottomLeft)';
}
