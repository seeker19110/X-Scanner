import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/scan_page.dart';
import '../core/scan_session.dart';
import '../imaging/page_render.dart';
import '../storage/session_store.dart';
import 'page_source.dart';

/// User-facing outcomes the UI reports as a message.
enum SessionNotice { restoreFailed, decodeFailed, saveFailed }

/// Owns the open scan session for the UI.
///
/// Every change runs through one internal queue, one at a time, and is
/// applied in memory only after [SessionStore.save] succeeded, so a failed
/// write leaves the session exactly as it was. Nothing is logged.
class SessionController extends ChangeNotifier {
  /// Creates a controller; [thumbnailer] decodes an image file into a
  /// preview and throws [ImageDecodeFailure] for unreadable images.
  SessionController({
    required this._store,
    required this._source,
    this._thumbnailer = thumbnail,
  });

  final SessionStore _store;
  final PageSource _source;
  final Future<Uint8List> Function(String path) _thumbnailer;

  static final RegExp _extensionPattern = RegExp(r'^[a-z0-9]{1,5}$');
  static const String _defaultExtension = 'jpg';

  ScanSession _session = ScanSession.empty;
  final Queue<SessionNotice> _notices = Queue<SessionNotice>();
  final Map<String, Future<Uint8List>> _thumbnails = {};
  int _pending = 0;
  bool _disposed = false;

  /// Tail of the write queue; never completes with an error.
  Future<void> _writeTail = Future<void>.value();

  /// Tail of the decode queue so at most one image is decoded at a time.
  Future<void> _decodeTail = Future<void>.value();

  /// The current session.
  ScanSession get session => _session;

  /// Whether a queued operation has not finished yet.
  bool get busy => _pending > 0;

  /// Returns the oldest pending notice and removes it, or `null`.
  SessionNotice? takeNotice() =>
      _notices.isEmpty ? null : _notices.removeFirst();

  /// The stored original of [page].
  File originalFile(ScanPage page) => _store.resolve(page.originalPath);

  /// The preview of [page], cached by page id. Decoding is queued behind
  /// any other decode; a failure is rethrown to the caller.
  Future<Uint8List> thumbnailFor(ScanPage page) => _thumbnails.putIfAbsent(
    page.id,
    () => _decode(() => originalFile(page).path),
  );

  /// Loads the saved session, then adds a photo Android may have kept after
  /// killing the app during capture.
  Future<void> restore() => _enqueue(() async {
    var failed = false;
    try {
      switch (await _store.load()) {
        case SessionLoaded(:final session):
          _session = session;
        case SessionEmpty():
          _session = ScanSession.empty;
        case SessionUnrecoverable():
          _session = ScanSession.empty;
          failed = true;
      }
    } on FileSystemException {
      _session = ScanSession.empty;
      failed = true;
    }
    _thumbnails.clear();
    if (failed) _notices.add(SessionNotice.restoreFailed);
    _notify();
    final lost = await _source.retrieveLost();
    if (lost != null) {
      await _addFromPath(lost, (page) => _session.added(page));
    }
  });

  /// Adds a photo from the system camera; a cancel does nothing.
  Future<void> capture() => _enqueue(() async {
    final path = await _source.capture();
    if (path != null) {
      await _addFromPath(path, (page) => _session.added(page));
    }
  });

  /// Adds an image from the photo picker; a cancel does nothing.
  Future<void> importFromGallery() => _enqueue(() async {
    final path = await _source.pickFromGallery();
    if (path != null) {
      await _addFromPath(path, (page) => _session.added(page));
    }
  });

  /// Replaces the page [id] with a new camera photo, resetting its quad
  /// and rotation. The old original is removed by [SessionStore.save].
  Future<void> retake(String id) => _enqueue(() async {
    if (!_contains(id)) return;
    final path = await _source.capture();
    if (path != null) {
      await _addFromPath(path, (page) => _session.replaced(id, page));
      if (!_contains(id)) _thumbnails.remove(id);
    }
  });

  /// Removes the page [id]; a page that is already gone is ignored.
  Future<void> remove(String id) => _enqueue(() async {
    if (!_contains(id)) return;
    if (await _commit(_session.removed(id))) _thumbnails.remove(id);
  });

  /// Moves the page at [from] to [to]; stale indices are ignored.
  Future<void> move(int from, int to) => _enqueue(() async {
    final count = _session.pages.length;
    if (from == to || from < 0 || to < 0 || from >= count || to >= count) {
      return;
    }
    await _commit(_session.moved(from, to));
  });

  /// Stores the edited [page] in place of the page with the same id.
  Future<void> updatePage(ScanPage page) => _enqueue(() async {
    if (!_contains(page.id)) return;
    await _commit(_session.replaced(page.id, page));
  });

  /// Removes every page.
  Future<void> clearAll() => _enqueue(() async {
    if (await _commit(ScanSession.empty)) _thumbnails.clear();
  });

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool _contains(String id) => _session.pages.any((p) => p.id == id);

  /// Checks that [path] decodes, copies it in as a new page, saves the
  /// session built by [apply] and only then shows it.
  Future<void> _addFromPath(
    String path,
    ScanSession Function(ScanPage page) apply,
  ) async {
    final Uint8List preview;
    try {
      preview = await _decode(() => path);
    } on ImageDecodeFailure {
      _report(SessionNotice.decodeFailed);
      return;
    } on FileSystemException {
      // The picked file vanished or is unreadable: same outcome for the user.
      _report(SessionNotice.decodeFailed);
      return;
    }
    final id = newPageId();
    try {
      final relative = await _store.importOriginal(
        File(path),
        id: id,
        extension: _extensionOf(path),
      );
      final next = apply(ScanPage(id: id, originalPath: relative));
      await _store.save(next);
      _session = next;
      _thumbnails[id] = Future<Uint8List>.value(preview);
      _notify();
    } on FileSystemException {
      _report(SessionNotice.saveFailed);
    } on StateError {
      _report(SessionNotice.saveFailed);
    }
  }

  /// Saves [next] and adopts it; returns whether that succeeded.
  Future<bool> _commit(ScanSession next) async {
    try {
      await _store.save(next);
    } on FileSystemException {
      _report(SessionNotice.saveFailed);
      return false;
    } on StateError {
      _report(SessionNotice.saveFailed);
      return false;
    }
    _session = next;
    _notify();
    return true;
  }

  /// Runs [_thumbnailer] on the path from [path] after earlier decodes.
  Future<Uint8List> _decode(String Function() path) {
    final result = _decodeTail.then((_) => _thumbnailer(path()));
    _decodeTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _pending++;
    _notify();
    final result = _writeTail.then((_) => operation()).whenComplete(() {
      _pending--;
      _notify();
    });
    _writeTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _report(SessionNotice notice) {
    _notices.add(notice);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Lowercased text after the last dot of the file name, or `jpg` when
  /// that is missing or not 1–5 letters/digits.
  static String _extensionOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return _defaultExtension;
    final ext = name.substring(dot + 1).toLowerCase();
    return _extensionPattern.hasMatch(ext) ? ext : _defaultExtension;
  }
}
