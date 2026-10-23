import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/scan_document.dart';
import '../core/scan_session.dart';
import '../storage/document_store.dart';
import '../storage/library_store.dart';
import '../storage/p1_migration.dart';
import 'pick_import.dart';

/// Where the library screen is (XS-09 §6).
enum LibraryStatus { loading, ready, failed }

/// A one-off message for the library screen; carries no title or path.
enum LibraryNotice {
  migrationSourceUnreadable,
  saveFailed,

  /// A photo taken before the app was stopped could not become a page; it
  /// is kept aside.
  pickRejected,

  /// A photo taken before the app was stopped is kept for the next start.
  pickKept,
}

/// Why a typed title cannot be saved.
enum TitleError { empty, tooLong, invalid }

/// Maximum title length in Unicode code points, as [isValidDocumentTitle].
const int _maxTitleRunes = 120;

/// Returns the error for a title typed by the user after trimming, or
/// null when `isValidDocumentTitle(raw.trim())`.
TitleError? titleErrorOf(String raw) {
  final title = raw.trim();
  if (title.isEmpty) return TitleError.empty;
  if (title.runes.length > _maxTitleRunes) return TitleError.tooLong;
  return isValidDocumentTitle(title) ? null : TitleError.invalid;
}

/// State of the library screen: an optional migration step, the listing,
/// new documents and renames (XS-09 PR-4a).
///
/// [start] and [refresh] are queued so only one runs at a time, in call
/// order. Nothing is logged, and no notice or error carries a title or a
/// path.
class LibraryController extends ChangeNotifier {
  LibraryController({
    required this._library,
    this._migrate,
    this._recover,
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? newPageId;

  final LibraryStore _library;
  final Future<MigrationOutcome> Function()? _migrate;

  /// Startup picker recovery after a migration step that did not fail.
  final Future<PickRecovery> Function(MigrationOutcome outcome)? _recover;
  final DateTime Function() _now;
  final String Function() _newId;

  final Queue<LibraryNotice> _notices = Queue();
  LibraryStatus _status = LibraryStatus.loading;
  bool _migrating = false;
  List<LibraryEntry> _entries = const [];
  MigrationFailure? _migrationFailure;
  bool _disposed = false;

  /// Whether the last migration step let the library open; until then
  /// [refresh] does not list.
  bool _opened = false;

  /// Tail of the [start]/[refresh] queue; never completes with an error.
  Future<void> _tail = Future<void>.value();

  /// Starts as [LibraryStatus.loading].
  LibraryStatus get status => _status;

  /// Whether the migration step is running.
  bool get migrating => _migrating;

  /// The last listing, in [LibraryStore.list] order; empty unless ready.
  List<LibraryEntry> get entries => _entries;

  /// Set while status is failed because of the migration; null for a
  /// listing failure.
  MigrationFailure? get migrationFailure => _migrationFailure;

  /// Returns the oldest pending notice and removes it, or `null`.
  LibraryNotice? takeNotice() =>
      _notices.isEmpty ? null : _notices.removeFirst();

  /// The store of document [docId], the one [LibraryStore.open] shares.
  /// Throws [ArgumentError] for an invalid id.
  DocumentStore storeOf(String docId) => _library.open(docId);

  /// Runs the migration step (if any), then lists; also the retry after a
  /// failure.
  Future<void> start() => _enqueue(_start);

  /// Lists again, e.g. after coming back from a document; does nothing
  /// until a migration step has let the library open.
  Future<void> refresh() => _enqueue(() async {
    if (_opened) await _list();
  });

  /// Creates an empty document titled [defaultDocumentTitle] of the local
  /// time, created and updated now (UTC), then refreshes. Returns its store
  /// (not yet loaded) and document, or null with [LibraryNotice.saveFailed],
  /// also before a migration step has let the library open.
  Future<(DocumentStore, ScanDocument)?> createDocument() async {
    if (!_opened) {
      // Before or after a failed migration step, which writes the same
      // folder.
      _report(LibraryNotice.saveFailed);
      return null;
    }
    final now = _now();
    final document = ScanDocument(
      id: _newId(),
      title: defaultDocumentTitle(now.toLocal()),
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    final DocumentStore store;
    try {
      store = await _library.create(document);
    } on FileSystemException {
      _report(LibraryNotice.saveFailed);
      return null;
    } on StateError {
      // The folder already exists: never overwritten.
      _report(LibraryNotice.saveFailed);
      return null;
    }
    await refresh();
    return (store, document);
  }

  /// Validates with [titleErrorOf] (returns the error, changes nothing);
  /// otherwise saves document [docId] with the trimmed title and
  /// `updatedAt = max(now UTC, createdAt)`, refreshes and returns null.
  ///
  /// Only a document listed as readable is loaded; anything else, a load
  /// that is not [DocumentLoaded] or a failing save reports
  /// [LibraryNotice.saveFailed] and keeps the old title.
  Future<TitleError?> rename(String docId, String raw) async {
    final error = titleErrorOf(raw);
    if (error != null) return error;
    final listed = _entries
        .whereType<LibraryDocument>()
        .where((e) => e.docId == docId)
        .firstOrNull;
    if (listed == null) {
      // Unreadable or unknown: loading could quarantine its manifest.
      _report(LibraryNotice.saveFailed);
      return null;
    }
    try {
      final store = _library.open(docId);
      // A missing original would also make the load quarantine the
      // manifest, so a rename never loads such a document.
      for (final page in listed.document.pages) {
        if (!await store.resolve(page.originalPath).exists()) {
          _report(LibraryNotice.saveFailed);
          return null;
        }
      }
      final loaded = await store.load();
      if (loaded is DocumentLoaded) {
        final old = loaded.document;
        final now = _now().toUtc();
        await store.save(
          ScanDocument(
            id: old.id,
            title: raw.trim(),
            createdAt: old.createdAt,
            updatedAt: now.isBefore(old.createdAt) ? old.createdAt : now,
            pages: old.pages,
          ),
        );
      } else {
        _report(LibraryNotice.saveFailed);
      }
    } on FileSystemException {
      _report(LibraryNotice.saveFailed);
    } on StateError {
      _report(LibraryNotice.saveFailed);
    }
    // Also after a failure: a load may have changed what is on disk.
    await refresh();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _start() async {
    _status = LibraryStatus.loading;
    _migrationFailure = null;
    final migrate = _migrate;
    MigrationOutcome outcome = const MigrationNotNeeded();
    if (migrate != null) {
      _migrating = true;
      _notify();
      try {
        outcome = await migrate();
      } catch (_) {
        // Anything the migration did not expect means the same to the
        // user: the old data is kept and "Thử lại" runs it again.
        outcome = const MigrationFailed(MigrationFailure.io);
      } finally {
        _migrating = false;
      }
      switch (outcome) {
        case MigrationFailed(:final reason):
          _opened = false;
          _entries = const [];
          _migrationFailure = reason;
          _status = LibraryStatus.failed;
          _notify();
          return;
        case MigrationSourceUnreadable():
          _notices.add(LibraryNotice.migrationSourceUnreadable);
        case MigrationNotNeeded() || MigrationDone():
          break;
      }
    } else {
      _notify();
    }
    final recover = _recover;
    if (recover != null) {
      PickRecovery recovery;
      try {
        recovery = await recover(outcome);
      } catch (_) {
        // Nothing unexpected may keep the library from opening; the picker
        // state on disk is left as it is.
        recovery = PickRecovery.kept;
      }
      switch (recovery) {
        case PickRecovery.rejected:
          _notices.add(LibraryNotice.pickRejected);
        case PickRecovery.kept:
          _notices.add(LibraryNotice.pickKept);
        case PickRecovery.none || PickRecovery.added:
          break;
      }
    }
    _opened = true;
    await _list();
  }

  /// Lists the library: ready with the entries, or failed on an I/O error.
  Future<void> _list() async {
    try {
      _entries = await _library.list();
      _status = LibraryStatus.ready;
    } on FileSystemException {
      _entries = const [];
      _status = LibraryStatus.failed;
    }
    _migrationFailure = null;
    _notify();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _report(LibraryNotice notice) {
    _notices.add(notice);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
