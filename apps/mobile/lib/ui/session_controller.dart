import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/page_quad.dart';
import '../core/scan_document.dart';
import '../core/scan_page.dart';
import '../core/scan_session.dart';
import '../export/export_job.dart';
import '../export/file_sharer.dart';
import '../export/page_exporter.dart';
import '../imaging/decode_gate.dart';
import '../imaging/page_render.dart';
import '../storage/document_store.dart';
import '../storage/pending_pick_store.dart';
import 'page_source.dart';
import 'pick_import.dart';

/// User-facing outcomes the UI reports as a message.
enum SessionNotice {
  restoreFailed,
  decodeFailed,
  saveFailed,
  exportFailed,
  exportCancelled,

  /// An earlier picker image is still being kept for another document, or
  /// its state is unknown; no picker is opened until it is resolved.
  pendingImage,
}

/// Owns one open library document for the UI (XS-09 FR-8).
///
/// Every change runs through one internal queue, one at a time, and is
/// applied in memory only after [DocumentStore.save] succeeded, so a failed
/// write leaves the document exactly as it was. Nothing is written until
/// [restore] has loaded the document. Nothing is logged.
class SessionController extends ChangeNotifier {
  /// Creates a controller; [thumbnailer] decodes an image file into a
  /// preview and throws [ImageDecodeFailure] for unreadable images. The
  /// exporter's directory is cleared on [restore] and after every share.
  /// [previewer] renders a thumbnail cropped and rotated like an export
  /// and throws [ImageDecodeFailure] for unreadable bytes.
  /// Thumbnails, cropped previews and decode checks run through
  /// [decodeGate]; pass the gate the exporter's renderer uses so only one
  /// original is decoded at once.
  ///
  /// `document` is the listed document of [store], shown until [restore]
  /// loads it; picker images go through [pending] (PR-4b.2 C3). [restore]
  /// first waits for `after`: the [idle] of the previous controller of the
  /// same document.
  SessionController({
    required this._store,
    required this._document,
    required PendingPickStore pending,
    required this._source,
    required this._exporter,
    required this._sharer,
    this._thumbnailer = thumbnail,
    this._previewer = croppedPreview,
    DecodeGate? decodeGate,
    DateTime Function()? now,
    this._after,
  }) : _now = now ?? DateTime.now,
       _decodeGate = decodeGate ?? DecodeGate() {
    _importer = PickImporter(
      pending: pending,
      source: _source,
      decode: (path) => _decode(() => path),
      now: _now,
    );
  }

  final DocumentStore _store;
  final PageSource _source;
  final PageExporter _exporter;
  final FileSharer _sharer;
  final Future<Uint8List> Function(String path) _thumbnailer;
  final Future<Uint8List> Function(
    Uint8List thumbnail,
    PageQuad quad,
    int quarterTurns,
  )
  _previewer;
  final DecodeGate _decodeGate;
  final DateTime Function() _now;
  late final PickImporter _importer;

  /// [idle] of the previous controller of this document, if any.
  final Future<void>? _after;

  ScanDocument _document;

  /// Whether [restore] loaded the document, so it may be saved.
  bool _writable = false;

  ScanSession _session = ScanSession.empty;
  final Queue<SessionNotice> _notices = Queue<SessionNotice>();
  final Map<String, Future<Uint8List>> _thumbnails = {};

  /// Ids whose cached preview in [_thumbnails] completed with an error.
  final Set<String> _failedThumbnails = {};

  /// Cropped previews by page id, each for one revision of that page only.
  final Map<String, _CroppedPreview> _previews = {};
  ExportJob? _exportJob;
  int _pending = 0;
  int _restoring = 0;
  bool _disposed = false;

  /// Tail of the write queue; never completes with an error.
  Future<void> _writeTail = Future<void>.value();

  /// The pages of the document.
  ScanSession get session => _session;

  /// Completes once every queued operation has finished; never errors.
  Future<void> get idle => _writeTail;

  /// The document: its title, and its pages once loaded.
  ScanDocument get document => _document;

  /// Whether a queued operation has not finished yet.
  bool get busy => _pending > 0;

  /// Whether a [restore] has been called and has not finished yet.
  bool get restoring => _restoring > 0;

  /// The export [exportAndShare] is running, from the moment it starts
  /// until its job ends, before any sharing; `null` otherwise.
  ExportJob? get exportJob => _exportJob;

  /// Returns the oldest pending notice and removes it, or `null`.
  SessionNotice? takeNotice() =>
      _notices.isEmpty ? null : _notices.removeFirst();

  /// The stored original of [page].
  File originalFile(ScanPage page) => _store.resolve(page.originalPath);

  /// The preview of [page], cached by page id. Decoding is queued behind
  /// any other decode. A failure is rethrown to the caller and stays
  /// cached, so rebuilding the page list never decodes a broken original
  /// again; only [retryThumbnail] does.
  Future<Uint8List> thumbnailFor(ScanPage page) =>
      _thumbnails.putIfAbsent(page.id, () {
        late final Future<Uint8List> decoding;
        decoding = _decode(() => originalFile(page).path)
            .catchError((Object error, StackTrace stack) {
              // Only this attempt: a newer preview for the page is not marked.
              if (identical(_thumbnails[page.id], decoding)) {
                _failedThumbnails.add(page.id);
              }
              return Future<Uint8List>.error(error, stack);
            });
        return decoding;
      });

  /// The thumbnail of [page] cropped by its quad and rotated by its quarter
  /// turns like an export, cached by `(page.id, page.revision)` (XS-08
  /// FR-4). Rendering is queued behind any other decode. A failure of the
  /// thumbnail or of the render is rethrown and stays cached like a failed
  /// thumbnail, until [retryThumbnail].
  ///
  /// Only the revision of the page in the session is cached, replacing the
  /// entry of an older one; another revision of a page in the session is
  /// rendered for this caller alone, so its result never reaches the cache.
  /// A page no longer in the session fails with a [StateError].
  Future<Uint8List> croppedPreviewFor(ScanPage page) {
    if (!_isCurrent(page)) return _renderPreview(page);
    final cached = _previews[page.id];
    if (cached != null && cached.revision == page.revision) {
      return cached.preview;
    }
    final entry = _CroppedPreview(page.revision);
    entry.preview = _renderPreview(page)
        .catchError((Object error, StackTrace stack) {
          // Only this attempt: a newer preview for the page is not marked.
          if (identical(_previews[page.id], entry)) entry.failed = true;
          return Future<Uint8List>.error(error, stack);
        });
    _previews[page.id] = entry;
    return entry.preview;
  }

  /// Drops the cached thumbnail and cropped preview of [page] if either
  /// failed and notifies, so the next [thumbnailFor] or [croppedPreviewFor]
  /// decodes both again. Previews still decoding or already decoded are
  /// kept.
  void retryThumbnail(ScanPage page) {
    if (!_failedThumbnails.contains(page.id) &&
        !(_previews[page.id]?.failed ?? false)) {
      return;
    }
    _forgetThumbnail(page.id);
    _notify();
  }

  /// Removes export files and share-sheet copies left by an earlier run,
  /// loads the document, then finishes a picker image this document still
  /// owns. Only a loaded document can be changed; anything else reports
  /// [SessionNotice.restoreFailed]. [restoring] is true from this call until
  /// that has finished, whether it succeeded or not.
  Future<void> restore() {
    _restoring++;
    _notify();
    return _enqueue(() async {
      try {
        await _restoreDocument();
      } finally {
        _restoring--;
      }
    });
  }

  Future<void> _restoreDocument() async {
    // A closed screen of this document may still be saving an import; reading
    // before it ends would let the two saves overwrite each other.
    await _after;
    await _exporter.clearLeftovers();
    _writable = false;
    try {
      final loaded = await _store.load();
      if (loaded is DocumentLoaded) {
        _document = loaded.document;
        _writable = true;
      }
    } on FileSystemException {
      // Reported below like an unusable document.
    }
    _session = _writable
        ? ScanSession(pages: _document.pages)
        : ScanSession.empty;
    _forgetThumbnails();
    if (!_writable) _notices.add(SessionNotice.restoreFailed);
    _notify();
    if (!_writable) return;
    final PendingPick? pick;
    try {
      pick = await _importer.pending.load();
    } on PendingPickFailure {
      return;
    }
    if (pick != null && _owns(pick)) await _import(pick);
  }

  /// Adds a photo from the system camera; a cancel does nothing.
  Future<void> capture() => _enqueue(() => _pick(_source.capture));

  /// Adds an image from the photo picker; a cancel does nothing.
  Future<void> importFromGallery() =>
      _enqueue(() => _pick(_source.pickFromGallery));

  /// Replaces the page [id] with a new camera photo, resetting its quad
  /// and rotation. The old original is removed by [DocumentStore.save].
  Future<void> retake(String id) => _enqueue(() async {
    if (!_contains(id)) return;
    await _pick(_source.capture, replace: id);
  });

  /// Removes the page [id]; a page that is already gone is ignored.
  Future<void> remove(String id) => _enqueue(() async {
    if (!_contains(id)) return;
    if (await _commit(_session.removed(id))) _forgetThumbnail(id);
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
    if (await _commit(ScanSession.empty)) _forgetThumbnails();
  });

  /// Exports the pages as [format] through an [ExportJob] published as
  /// [exportJob], shares the files and then deletes them. Listeners are
  /// notified on every change of the job. An empty session does nothing;
  /// a cancel through [cancelExport] reports
  /// [SessionNotice.exportCancelled] and any failure
  /// [SessionNotice.exportFailed], both sharing nothing and leaving the
  /// session and originals as they were. Edits queued meanwhile do not
  /// reach the job, which exports the pages as they were when it started.
  Future<void> exportAndShare(ExportFormat format) => _enqueue(() async {
    final pages = _session.pages;
    if (pages.isEmpty) return;
    final job = ExportJob(pages, format)..addListener(_notify);
    _exportJob = job;
    _notify();
    try {
      try {
        await _exporter.run(job, originalFile);
      } finally {
        // The job has ended: from here on there is nothing to cancel.
        _endExportJob(job);
      }
      switch (job.state) {
        case ExportState.succeeded:
          await _sharer.share(job.files!);
        case ExportState.cancelled:
          _report(SessionNotice.exportCancelled);
        // A job still queued or running after run() is a bug; it shares
        // nothing either.
        case ExportState.failed || ExportState.queued || ExportState.running:
          _report(SessionNotice.exportFailed);
      }
    } catch (_) {
      // Render, PDF, file system and platform share errors all mean the
      // same to the user; none of their details are shown or logged.
      _report(SessionNotice.exportFailed);
    } finally {
      await _exporter.clear();
    }
  });

  void _endExportJob(ExportJob job) {
    job.removeListener(_notify);
    _exportJob = null;
    _notify();
  }

  /// Asks the running export to stop at its next page; does nothing when
  /// there is none. Not queued, as the queue is busy with that export.
  void cancelExport() => _exportJob?.cancel();

  @override
  void dispose() {
    // Nobody is left to share with.
    _exportJob?.cancel();
    _disposed = true;
    super.dispose();
  }

  bool _contains(String id) => _session.pages.any((p) => p.id == id);

  /// Whether [page] is in the session in this revision.
  bool _isCurrent(ScanPage page) =>
      _session.pages.any((p) => p.id == page.id && p.revision == page.revision);

  void _forgetThumbnail(String id) {
    _thumbnails.remove(id);
    _failedThumbnails.remove(id);
    _previews.remove(id);
  }

  void _forgetThumbnails() {
    _thumbnails.clear();
    _failedThumbnails.clear();
    _previews.clear();
  }

  /// Renders the cropped preview of [page] from its thumbnail through the
  /// decode gate.
  Future<Uint8List> _renderPreview(ScanPage page) {
    if (!_contains(page.id)) {
      return Future<Uint8List>.error(StateError('page is not in the session'));
    }
    return thumbnailFor(page).then(
      (bytes) => _decodeGate.run(
        () => _previewer(bytes, page.quad, page.quarterTurns),
      ),
    );
  }

  /// Whether [pick] belongs to this document and has an image to import.
  bool _owns(PendingPick pick) =>
      pick.docId == _document.id && pick.cacheRelativePath != null;

  /// One picker operation (PR-4b.2 C3): a pick this document still owns is
  /// imported first instead (the retry); another pending pick blocks.
  /// Otherwise the page id is reserved before [launch] opens the picker,
  /// the result is remembered even if this controller is disposed
  /// meanwhile, and only a live controller imports it.
  Future<void> _pick(
    Future<String?> Function() launch, {
    String? replace,
  }) async {
    if (!_writable) {
      _report(SessionNotice.saveFailed);
      return;
    }
    final pending = _importer.pending;
    PendingPick pick;
    try {
      final existing = await pending.load();
      if (existing != null) {
        if (_owns(existing)) {
          await _import(existing);
        } else {
          _report(SessionNotice.pendingImage);
        }
        return;
      }
      pick = await pending.begin(
        docId: _document.id,
        pageId: newPageId(),
        replacePageId: replace,
      );
    } on PendingPickFailure {
      _report(SessionNotice.pendingImage);
      return;
    }
    final path = await launch();
    if (path == null) {
      await _cancel(pick);
      return;
    }
    try {
      pick = await pending.remember(pick, path);
    } on PendingPickFailure {
      // Nothing was kept, so the empty reservation goes; a result that is no
      // readable file in the cache cannot become a page (P1 AC-7).
      await _cancel(pick);
      final unreadable =
          await FileSystemEntity.type(path) != FileSystemEntityType.file;
      _report(
        unreadable ? SessionNotice.decodeFailed : SessionNotice.saveFailed,
      );
      return;
    }
    // Another controller may own this document now; it imports the pick.
    if (_disposed) return;
    await _import(pick);
  }

  /// Drops the empty reservation [pick]; one that cannot be dropped stays
  /// and blocks pickers until the next start resolves it.
  Future<void> _cancel(PendingPick pick) async {
    try {
      await _importer.pending.cancel(pick);
    } on PendingPickFailure {
      // Kept on disk; the startup recovery cancels an empty reservation.
    }
  }

  /// Imports [pick] into the document and shows the outcome.
  Future<void> _import(PendingPick pick) async {
    switch (await _importer.importInto(pick, _store, _document)) {
      case PickImported(:final document, :final preview):
        _document = document;
        _session = ScanSession(pages: document.pages);
        if (preview != null) {
          _thumbnails[pick.pageId] = Future<Uint8List>.value(preview);
        }
        final replaced = pick.replacePageId;
        if (replaced != null && !_contains(replaced)) {
          _forgetThumbnail(replaced);
        }
        _notify();
      case PickRejected():
        _report(SessionNotice.decodeFailed);
      case PickKept():
        _report(SessionNotice.saveFailed);
    }
  }

  /// Saves [next] as the document's pages and adopts it; returns whether
  /// that succeeded.
  Future<bool> _commit(ScanSession next) async {
    if (!_writable) {
      _report(SessionNotice.saveFailed);
      return false;
    }
    final document = withPages(_document, next.pages, _now());
    try {
      await _store.save(document);
    } on FileSystemException {
      _report(SessionNotice.saveFailed);
      return false;
    } on StateError {
      _report(SessionNotice.saveFailed);
      return false;
    }
    _document = document;
    _session = next;
    _notify();
    return true;
  }

  /// Runs [_thumbnailer] on the path from [path] through the decode gate.
  Future<Uint8List> _decode(String Function() path) =>
      _decodeGate.run(() => _thumbnailer(path()));

  Future<void> _enqueue(Future<void> Function() operation) {
    _pending++;
    _notify();
    final result = _writeTail
        .then((_) async {
          // Let an in-flight save finish, but never start another picker, write
          // or share after its owning screen/controller has gone away.
          if (!_disposed) await operation();
        })
        .whenComplete(() {
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
}

/// A cropped preview of one page revision and whether it failed.
class _CroppedPreview {
  _CroppedPreview(this.revision);

  final int revision;
  late final Future<Uint8List> preview;
  bool failed = false;
}
