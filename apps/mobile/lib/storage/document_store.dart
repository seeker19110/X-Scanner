// DEBT: DocumentStore copies SessionStore's guarantees for one document folder | trần: two stores to keep in sync | xem lại khi: XS-09 PR-4 switches the app to documents and deletes SessionStore.
import 'dart:convert';
import 'dart:io';

import '../core/scan_document.dart';
import '../core/session_manifest.dart';

/// Outcome of [DocumentStore.load].
sealed class DocumentLoadResult {
  const DocumentLoadResult();
}

/// The manifest was read and every referenced original exists.
final class DocumentLoaded extends DocumentLoadResult {
  const DocumentLoaded(this.document);

  final ScanDocument document;
}

/// document.json has a newer schema (XS-08 FR-7): nothing renamed or
/// deleted; save() refuses.
final class DocumentNeedsUpdate extends DocumentLoadResult {
  const DocumentNeedsUpdate();
}

/// Unusable manifest renamed to [corruptCopyPath] (relative to the document
/// folder), or null when there was no document.json at all. No original is
/// deleted.
final class DocumentUnrecoverable extends DocumentLoadResult {
  const DocumentUnrecoverable(this.corruptCopyPath);

  final String? corruptCopyPath;
}

/// Persists one document in its folder [dir] (`documents/{docId}`):
/// `document.json` plus untouched originals in `originals/{id}.{ext}`.
///
/// Same guarantees as `SessionStore`: originals are never overwritten and
/// are only deleted once a manifest that no longer references them has been
/// saved, or as orphans after a successful [load]. Nothing is logged.
class DocumentStore {
  /// Throws [ArgumentError] if the folder name is not a valid document id.
  DocumentStore(this.dir) : docId = _folderName(dir) {
    if (!isValidPageId(docId)) {
      throw ArgumentError('folder name must be 32 lowercase hex characters');
    }
  }

  final Directory dir;

  /// The folder name, which every saved document's id must equal.
  final String docId;

  static const String _manifestName = 'document.json';
  static const String _originalsDir = 'originals';
  static const String _partSuffix = '.part';
  static const String _tmpSuffix = '.tmp';

  static final RegExp _quarantinePattern = RegExp(
    r'^document\.corrupt-\d+\.json$',
  );

  /// Relative paths of originals referenced by the last loaded or saved
  /// manifest; only these may be cleaned by [save].
  Set<String> _saved = const {};

  /// Whether [_saved] matches the manifest on disk: set once [load]
  /// returns a usable or quarantined result, or [save] writes. Until then
  /// an existing manifest is unknown, so [save] must not replace it (its
  /// originals would become unreferenced and be deleted by the next
  /// [load]).
  bool _ready = false;

  /// Serializes [load], [save] and [importOriginal] so they never
  /// interleave on disk.
  Future<void> _tail = Future<void>.value();

  File get _manifest => File('${dir.path}/$_manifestName');

  Directory get _originals => Directory('${dir.path}/$_originalsDir');

  /// Returns the file for a canonical original path `originals/{id}.{ext}`,
  /// or throws [ArgumentError] for anything else (e.g. traversal).
  File resolve(String relativePath) {
    final id = relativePath.split('/').last.split('.').first;
    if (!isValidOriginalPath(id, relativePath)) {
      throw ArgumentError('not a valid original path');
    }
    return File('${dir.path}/$relativePath');
  }

  /// Copies [source] to `originals/{id}.{extension}` and returns that
  /// relative path. [source] is never modified or deleted.
  ///
  /// Throws [ArgumentError] for an invalid id or extension and
  /// [StateError] if the destination already exists (never overwritten) or
  /// the document folder does not exist (only `LibraryStore.create` makes
  /// one, so a folder named by an id always has a manifest).
  Future<String> importOriginal(
    File source, {
    required String id,
    required String extension,
  }) =>
      _serialized(() => _importOriginal(source, id: id, extension: extension));

  Future<String> _importOriginal(
    File source, {
    required String id,
    required String extension,
  }) async {
    final ext = extension.toLowerCase();
    if (!isValidPageId(id)) {
      throw ArgumentError('id must be 32 lowercase hex characters');
    }
    if (!isValidExtension(ext)) {
      throw ArgumentError('extension must be 1-5 letters or digits');
    }
    final relative = '$_originalsDir/$id.$ext';
    final target = resolve(relative);
    if (await target.exists()) {
      throw StateError('original already exists');
    }
    if (!await dir.exists()) {
      throw StateError('document folder does not exist');
    }
    await _originals.create();
    final part = File('${target.path}$_partSuffix');
    try {
      await source.copy(part.path);
      await _sync(part);
      if (await target.exists()) {
        throw StateError('original already exists');
      }
      await part.rename(target.path);
    } catch (_) {
      await _deleteQuietly(part);
      rethrow;
    }
    return relative;
  }

  /// Reads the saved document.
  ///
  /// A missing manifest gives [DocumentUnrecoverable] with no copy and
  /// changes nothing. A newer schema gives [DocumentNeedsUpdate], changes
  /// nothing and leaves [save] refusing. An undecodable manifest, one whose
  /// id is not [docId], or one referencing a missing original, is renamed
  /// to `document.corrupt-{ms}.json` and no original is deleted. On
  /// success, leftover `.part` files are deleted, and so are files in
  /// `originals/` not referenced by the document unless a quarantined
  /// manifest still exists (its originals stay for manual recovery).
  Future<DocumentLoadResult> load() => _serialized(_load);

  /// Atomically writes [document] as the manifest, then deletes originals
  /// of the previously saved document that [document] no longer references.
  ///
  /// Throws [ArgumentError] if [document] is not this folder's document or
  /// has an invalid original path, and [StateError] if an original is
  /// missing, or if `document.json` exists but this store has not loaded it
  /// (e.g. [load] failed with an I/O error or needs an app update); in all
  /// these cases nothing is written.
  Future<void> save(ScanDocument document) =>
      _serialized(() => _save(document));

  Future<DocumentLoadResult> _load() async {
    // Any failure below leaves the store unable to replace the manifest.
    _ready = false;
    // What an earlier load referenced is no longer known, so a later save
    // must not delete it.
    _saved = const {};
    if (!await _manifest.exists()) {
      // Documents are created with a manifest, so a missing one is damage;
      // there is nothing to replace, so a later save is allowed.
      return _known(const {}, const DocumentUnrecoverable(null));
    }
    final bytes = await _manifest.readAsBytes();
    final DocumentDecodeResult decoded;
    try {
      decoded = decodeDocument(utf8.decode(bytes));
    } on FormatException {
      return _unrecoverable();
    }
    final ScanDocument document;
    switch (decoded) {
      case DocumentNeedsAppUpdate():
        // Not damaged: keep everything and stay not ready.
        return const DocumentNeedsUpdate();
      case DecodedDocument(document: final d):
        document = d;
    }
    if (document.id != docId) {
      return _unrecoverable();
    }
    for (final page in document.pages) {
      if (!await resolve(page.originalPath).exists()) {
        return _unrecoverable();
      }
    }
    final referenced = _referencedPaths(document);
    // DEBT: originals of a quarantined document are kept with no UI to recover or delete them | trần: kept until app data is cleared | xem lại khi: Data Governance (spec §14) before release.
    await _deleteUnreferencedOriginals(
      referenced,
      partialOnly: await _hasQuarantinedManifest(),
    );
    return _known(referenced, DocumentLoaded(document));
  }

  /// Quarantines the manifest. Its originals are no longer in [_saved], so
  /// no later [save] deletes them.
  Future<DocumentLoadResult> _unrecoverable() async {
    final copy = await _quarantineManifest();
    return _known(const {}, DocumentUnrecoverable(copy));
  }

  /// Records that [saved] is what the manifest on disk references.
  DocumentLoadResult _known(Set<String> saved, DocumentLoadResult result) {
    _saved = saved;
    _ready = true;
    return result;
  }

  Future<void> _save(ScanDocument document) async {
    if (document.id != docId) {
      throw ArgumentError('document id must equal the folder name');
    }
    if (!_ready && await _manifest.exists()) {
      throw StateError('the saved document has not been loaded');
    }
    for (final page in document.pages) {
      if (!await resolve(page.originalPath).exists()) {
        throw StateError('original of a page is missing');
      }
    }
    final json = encodeDocument(document);
    final tmp = File('${_manifest.path}$_tmpSuffix');
    try {
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(_manifest.path);
    } catch (_) {
      await _deleteQuietly(tmp);
      rethrow;
    }
    final referenced = _referencedPaths(document);
    final previous = _saved;
    _saved = referenced;
    _ready = true;
    for (final path in previous.difference(referenced)) {
      // Best effort: the manifest is already saved; a leftover file is an
      // orphan that the next successful load removes.
      await _deleteQuietly(resolve(path));
    }
  }

  /// Renames the manifest to a fresh `document.corrupt-{ms}.json` (UTC
  /// epoch ms, bumped until unused) and returns its relative path.
  Future<String> _quarantineManifest() async {
    var stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    while (true) {
      final name = 'document.corrupt-$stamp.json';
      final copy = File('${dir.path}/$name');
      if (!await copy.exists()) {
        await _manifest.rename(copy.path);
        return name;
      }
      stamp++;
    }
  }

  Future<bool> _hasQuarantinedManifest() => dir
      .list(followLinks: false)
      .any((e) => _quarantinePattern.hasMatch(e.uri.pathSegments.last));

  /// Deletes unreferenced files in `originals/`; with [partialOnly], only
  /// interrupted `.part` copies, which never hold a complete original.
  Future<void> _deleteUnreferencedOriginals(
    Set<String> referenced, {
    required bool partialOnly,
  }) async {
    if (!await _originals.exists()) {
      return;
    }
    await for (final entity in _originals.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final unreferenced = !referenced.contains('$_originalsDir/$name');
      if (unreferenced && (!partialOnly || name.endsWith(_partSuffix))) {
        await _deleteQuietly(entity);
      }
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Last non-empty segment of [dir]'s path, so a trailing separator does
  /// not hide the folder name.
  static String _folderName(Directory dir) {
    final segments = dir.path.split(RegExp(r'[/\\]'))
      ..removeWhere((s) => s.isEmpty);
    return segments.isEmpty ? '' : segments.last;
  }

  static Set<String> _referencedPaths(ScanDocument document) => {
    for (final page in document.pages) page.originalPath,
  };

  /// Forces a copied file's contents to disk before it is renamed.
  static Future<void> _sync(File file) async {
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone or not removable; the caller's outcome stands.
    }
  }
}
