import 'dart:math';

import 'scan_page.dart';

/// An immutable, ordered list of scanned pages with unique ids.
///
/// Every operation returns a new session; the receiver is never changed.
/// Invalid input throws [ArgumentError] or [RangeError].
class ScanSession {
  /// Creates a session, or throws [ArgumentError] if two pages share an id.
  ScanSession({List<ScanPage> pages = const []})
    : this._(_checkUniqueIds(List.unmodifiable(pages)));

  const ScanSession._(this.pages);

  /// A session without pages.
  static const ScanSession empty = ScanSession._([]);

  /// The pages in order; the list cannot be modified.
  final List<ScanPage> pages;

  /// Returns a session with [page] appended; its id must be new.
  ScanSession added(ScanPage page) {
    if (_indexOf(page.id) != -1) {
      throw ArgumentError.value(page.id, 'page.id', 'is already in session');
    }
    return ScanSession._(List.unmodifiable([...pages, page]));
  }

  /// Returns a session without the page with [id]; it must exist.
  ScanSession removed(String id) {
    final index = _requireIndex(id);
    return ScanSession._(
      List.unmodifiable([...pages.take(index), ...pages.skip(index + 1)]),
    );
  }

  /// Returns a session where the page at [from] is taken out and then
  /// inserted at [to] of the remaining list. Both must be valid indices of
  /// [pages], otherwise [RangeError] is thrown.
  ScanSession moved(int from, int to) {
    RangeError.checkValidIndex(from, pages, 'from');
    RangeError.checkValidIndex(to, pages, 'to');
    final list = [...pages];
    final page = list.removeAt(from);
    list.insert(to, page);
    return ScanSession._(List.unmodifiable(list));
  }

  /// Returns a session where the page with [id] is replaced by [page] at the
  /// same position. [page] may keep [id] (edit) or carry a new id (retake),
  /// but a new id must not belong to another page.
  ScanSession replaced(String id, ScanPage page) {
    final index = _requireIndex(id);
    final clash = _indexOf(page.id);
    if (clash != -1 && clash != index) {
      throw ArgumentError.value(page.id, 'page.id', 'is already in session');
    }
    final list = [...pages];
    list[index] = page;
    return ScanSession._(List.unmodifiable(list));
  }

  int _indexOf(String id) => pages.indexWhere((p) => p.id == id);

  int _requireIndex(String id) {
    final index = _indexOf(id);
    if (index == -1) {
      throw ArgumentError.value(id, 'id', 'is not in session');
    }
    return index;
  }

  static List<ScanPage> _checkUniqueIds(List<ScanPage> pages) {
    final seen = <String>{};
    for (final page in pages) {
      if (!seen.add(page.id)) {
        throw ArgumentError.value(page.id, 'pages', 'contain a duplicate id');
      }
    }
    return pages;
  }
}

/// Number of random bytes in a page id (rendered as twice as many hex chars).
const int _pageIdBytes = 16;

/// Returns a new page id: 32 lowercase hex characters from [random]
/// (default [Random.secure]).
String newPageId([Random? random]) {
  final source = random ?? Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < _pageIdBytes; i++) {
    buffer.write(source.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
