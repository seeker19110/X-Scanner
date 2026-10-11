import 'page_quad.dart';

/// One scanned page: an immutable reference to the untouched original image
/// plus non-destructive edit parameters.
///
/// Edits return a new [ScanPage]; [id] and [originalPath] never change and
/// this class never reads, writes or deletes files.
class ScanPage {
  ScanPage({
    required String id,
    required String originalPath,
    PageQuad quad = PageQuad.fullFrame,
    int quarterTurns = 0,
  }) : this._(
         _requireNonBlank(id, 'id'),
         _requireNonBlank(originalPath, 'originalPath'),
         quad,
         _normalizeQuarterTurns(quarterTurns),
       );

  const ScanPage._(this.id, this.originalPath, this.quad, this.quarterTurns);

  final String id;
  final String originalPath;

  /// Crop corners in the coordinates of the original, unrotated image.
  final PageQuad quad;

  /// Clockwise rotation in quarter turns, always in `0..3`.
  final int quarterTurns;

  /// Returns a new page with [quad]; this page is unchanged.
  ScanPage withQuad(PageQuad quad) =>
      ScanPage._(id, originalPath, quad, quarterTurns);

  /// Returns a new page rotated 90° clockwise; this page is unchanged.
  ScanPage rotatedClockwise() => ScanPage._(
    id,
    originalPath,
    quad,
    _normalizeQuarterTurns(quarterTurns + 1),
  );

  static String _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty or blank');
    }
    return value;
  }

  /// Dart's int `%` is Euclidean: never negative for a positive divisor.
  static int _normalizeQuarterTurns(int value) => value % 4;
}
