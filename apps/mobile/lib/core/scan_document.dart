import 'scan_page.dart';
import 'scan_session.dart';
import 'session_manifest.dart';

/// Maximum title length in Unicode code points.
const int _maxTitleRunes = 120;

/// C0 controls U+0000–U+001F and DEL U+007F.
final RegExp _controlCharacter = RegExp(r'[\x00-\x1f\x7f]');

/// Whether [title] is a valid stored title: equal to its trim, 1..120
/// Unicode code points (runes), no U+0000–U+001F and no U+007F.
bool isValidDocumentTitle(String title) {
  final runes = title.runes.length;
  return title == title.trim() &&
      runes >= 1 &&
      runes <= _maxTitleRunes &&
      !_controlCharacter.hasMatch(title);
}

/// An immutable scanned document: metadata plus an ordered list of pages
/// with unique ids (XS-08 FR-1).
///
/// Invalid input throws [ArgumentError]; its message never contains the
/// title.
class ScanDocument {
  ScanDocument({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<ScanPage> pages = const [],
  }) : this._(
         _checkId(id),
         _checkTitle(title),
         _checkUtc(createdAt, 'createdAt'),
         _checkUpdatedAt(createdAt, updatedAt),
         // Reuses the session's duplicate-id check and unmodifiable copy.
         ScanSession(pages: pages).pages,
       );

  const ScanDocument._(
    this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.pages,
  );

  /// 32 lowercase hex characters, never changes.
  final String id;

  /// See [isValidDocumentTitle].
  final String title;

  /// UTC.
  final DateTime createdAt;

  /// UTC, never before [createdAt].
  final DateTime updatedAt;

  /// The pages in order; the list cannot be modified.
  final List<ScanPage> pages;

  static String _checkId(String id) {
    if (!isValidPageId(id)) {
      throw ArgumentError.value(
        id,
        'id',
        'must be 32 lowercase hex characters',
      );
    }
    return id;
  }

  static String _checkTitle(String title) {
    if (!isValidDocumentTitle(title)) {
      // The value is user content, so it is left out of the error.
      throw ArgumentError(
        'title: must be 1-120 characters without surrounding spaces or '
        'control characters',
      );
    }
    return title;
  }

  static DateTime _checkUtc(DateTime time, String name) {
    if (!time.isUtc) {
      throw ArgumentError('$name: must be UTC');
    }
    return time;
  }

  static DateTime _checkUpdatedAt(DateTime createdAt, DateTime updatedAt) {
    _checkUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt: must not be before createdAt');
    }
    return updatedAt;
  }
}
