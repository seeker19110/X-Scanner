import 'dart:io';
import 'dart:typed_data';

import '../core/scan_document.dart';
import '../core/scan_page.dart';
import '../core/scan_session.dart';
import '../storage/document_store.dart';
import '../storage/library_store.dart';
import '../storage/p1_migration.dart';
import '../storage/pending_pick_store.dart';
import 'page_source.dart';

/// What [PickImporter.importInto] did with a pending picker image.
sealed class PickImport {
  const PickImport();
}

/// The page is in [document], which is saved. [preview] is the decoded
/// thumbnail when this call decoded it.
final class PickImported extends PickImport {
  const PickImported(this.document, this.preview);

  final ScanDocument document;
  final Uint8List? preview;
}

/// The image or its owner cannot take it; its bytes are kept aside and the
/// next capture may start.
final class PickRejected extends PickImport {
  const PickRejected();
}

/// Nothing changed that could lose the image; it stays pending for a retry.
final class PickKept extends PickImport {
  const PickKept();
}

/// Outcome of [PickImporter.recover], for a closed library notice.
enum PickRecovery { none, added, rejected, kept }

/// Moves pending picker images into their owning document (XS-09 PR-4b.2,
/// leaf protocol §12). Nothing is logged.
class PickImporter {
  PickImporter({
    required this.pending,
    required this._source,
    required this._decode,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PendingPickStore pending;
  final PageSource _source;
  final Future<Uint8List> Function(String path) _decode;
  final DateTime Function() _now;

  bool _recovered = false;

  /// Imports [pick], which has a remembered result, into [document] loaded
  /// from [store]: a page with its reserved id is added, or replaces the
  /// page it retakes, and saved; only then is the picker's cache copy
  /// discarded and the pick completed. [preview] skips a decode that the
  /// caller has already done.
  ///
  /// A page already in [document] means an earlier run committed it, so
  /// only the cleanup runs again. An undecodable or oversized image, or a
  /// retake whose page is gone, is retained aside ([PickRejected]); a
  /// storage failure keeps the pick pending ([PickKept]).
  Future<PickImport> importInto(
    PendingPick pick,
    DocumentStore store,
    ScanDocument document, {
    Uint8List? preview,
  }) async {
    final replace = pick.replacePageId;
    if (_has(document, pick.pageId)) {
      await _finish(pick);
      return PickImported(document, null);
    }
    if (replace != null && !_has(document, replace)) return _reject(pick);
    final File staged;
    try {
      staged = await pending.stage(pick);
    } on PendingPickFailure catch (failure) {
      return failure.sizeRejected ? _reject(pick) : const PickKept();
    }
    var decoded = preview;
    if (decoded == null) {
      try {
        decoded = await _decode(staged.path);
      } catch (_) {
        // Any decode error means the image cannot become a page.
        return _reject(pick);
      }
    }
    final ScanDocument next;
    try {
      final relative = 'originals/${pick.pageId}.${pick.extension}';
      // A copy left by an earlier run for this reserved id is the same image.
      if (!await store.resolve(relative).exists()) {
        await store.importOriginal(
          staged,
          id: pick.pageId,
          extension: pick.extension!,
        );
      }
      final page = ScanPage(id: pick.pageId, originalPath: relative);
      final pages = ScanSession(pages: document.pages);
      next = withPages(
        document,
        replace == null
            ? pages.added(page).pages
            : pages.replaced(replace, page).pages,
        _now(),
      );
      await store.save(next);
    } on FileSystemException {
      return const PickKept();
    } on StateError {
      return const PickKept();
    }
    await _finish(pick);
    return PickImported(next, decoded);
  }

  /// The one startup recovery of this instance, after a migration step that
  /// did not fail: an existing marker wins; otherwise one is reserved
  /// before the single lost-photo probe, for the migrated document or a new
  /// one created only once the image is staged and decodes.
  Future<PickRecovery> recover(
    LibraryStore library,
    MigrationOutcome migration,
  ) async {
    if (_recovered) return PickRecovery.none;
    _recovered = true;
    PendingPick? pick;
    try {
      pick =
          await pending.load() ??
          await pending.begin(
            docId: migration is MigrationDone ? migration.docId : newPageId(),
            pageId: newPageId(),
            createOwner: migration is! MigrationDone,
          );
      if (pick.cacheRelativePath == null) {
        // DEBT: plugin clears lost-result preferences before Dart can journal the returned path | trần: a crash between native clear and durable remember can leave an unassigned cache original | xem lại khi: a device test reproduces this handoff loss or before distributed release requires transactional picker recovery.
        final lost = await _source.retrieveLost();
        if (lost == null) {
          // An empty marker holds no bytes; keeping it would only block
          // every later capture (XS-09 PR-4b.2 C5a).
          await pending.cancel(pick);
          return PickRecovery.none;
        }
        pick = await pending.remember(pick, lost);
      }
    } on PendingPickFailure {
      return PickRecovery.kept;
    }
    final docId = pick.docId;
    Uint8List? preview;
    try {
      if (pick.createOwner &&
          await FileSystemEntity.type(
                '${library.root.path}/$docId',
                followLinks: false,
              ) ==
              FileSystemEntityType.notFound) {
        final File staged;
        try {
          staged = await pending.stage(pick);
        } on PendingPickFailure catch (failure) {
          return _recovery(
            failure.sizeRejected ? await _reject(pick) : const PickKept(),
          );
        }
        try {
          preview = await _decode(staged.path);
        } catch (_) {
          return _recovery(await _reject(pick));
        }
        // A crash inside an earlier create can leave `{docId}.part`; only
        // this marker owns that id and the folder holds no original yet.
        final part = Directory('${library.root.path}/$docId.part');
        if (await FileSystemEntity.type(part.path, followLinks: false) ==
            FileSystemEntityType.directory) {
          await part.delete(recursive: true);
        }
        final time = _now();
        await library.create(
          ScanDocument(
            id: docId,
            title: defaultDocumentTitle(time.toLocal()),
            createdAt: time.toUtc(),
            updatedAt: time.toUtc(),
          ),
        );
      }
      final store = library.open(docId);
      final loaded = await store.load();
      if (loaded is! DocumentLoaded) {
        // Never attach to another document (C5b).
        return _recovery(await _reject(pick));
      }
      return _recovery(
        await importInto(pick, store, loaded.document, preview: preview),
      );
    } on FileSystemException {
      return PickRecovery.kept;
    } on StateError {
      return PickRecovery.kept;
    }
  }

  static PickRecovery _recovery(PickImport result) => switch (result) {
    PickImported() => PickRecovery.added,
    PickRejected() => PickRecovery.rejected,
    PickKept() => PickRecovery.kept,
  };

  static bool _has(ScanDocument document, String pageId) =>
      document.pages.any((p) => p.id == pageId);

  Future<PickImport> _reject(PendingPick pick) async {
    try {
      await pending.retainRejected(pick);
      return const PickRejected();
    } on PendingPickFailure {
      return const PickKept();
    }
  }

  /// Cleanup after a durable manifest; a failure leaves the pick for the
  /// next run, which only repeats this cleanup.
  Future<void> _finish(PendingPick pick) async {
    await _source.discard('${pending.cacheDir.path}/${pick.cacheRelativePath}');
    try {
      await pending.complete(pick);
    } on PendingPickFailure {
      // Retried by the next resume or startup.
    }
  }
}

/// [document] with [pages] and `updatedAt = max(now UTC, createdAt)`.
ScanDocument withPages(
  ScanDocument document,
  List<ScanPage> pages,
  DateTime now,
) {
  final utc = now.toUtc();
  return ScanDocument(
    id: document.id,
    title: document.title,
    createdAt: document.createdAt,
    updatedAt: utc.isBefore(document.createdAt) ? document.createdAt : utc,
    pages: pages,
  );
}
