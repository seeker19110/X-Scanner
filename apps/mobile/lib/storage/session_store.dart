import 'dart:convert';
import 'dart:io';

import '../core/scan_session.dart';
import '../core/session_manifest.dart';

/// Outcome of [SessionStore.load].
sealed class SessionLoadResult {
  const SessionLoadResult();
}

/// The manifest was read and every referenced original exists.
final class SessionLoaded extends SessionLoadResult {
  const SessionLoaded(this.session);

  final ScanSession session;
}

/// No manifest has been saved yet.
final class SessionEmpty extends SessionLoadResult {
  const SessionEmpty();
}

/// The manifest could not be used. It was renamed to [corruptCopyPath]
/// (relative to the session root) and all originals were kept.
final class SessionUnrecoverable extends SessionLoadResult {
  const SessionUnrecoverable(this.corruptCopyPath);

  final String corruptCopyPath;
}

/// Persists one scan session under an injected [root] directory:
/// `session.json` plus untouched originals in `originals/{id}.{ext}`.
///
/// Originals are never overwritten. They are only deleted once a manifest
/// that no longer references them has been saved, or as orphans after a
/// successful [load]. Nothing is logged.
class SessionStore {
  SessionStore(this.root);

  final Directory root;

  static const String _manifestName = 'session.json';
  static const String _originalsDir = 'originals';
  static const String _partSuffix = '.part';
  static const String _tmpSuffix = '.tmp';

  static final RegExp _extensionPattern = RegExp(r'^[a-z0-9]{1,5}$');
  static final RegExp _quarantinePattern = RegExp(
    r'^session\.corrupt-\d+\.json$',
  );

  /// Relative paths of originals referenced by the last loaded or saved
  /// manifest; only these may be cleaned by [save].
  Set<String> _saved = const {};

  /// Whether [_saved] matches the manifest on disk: set once [load]
  /// returns or [save] writes. Until then an existing manifest is
  /// unknown, so [save] must not replace it (its originals would become
  /// unreferenced and be deleted by the next [load]).
  bool _ready = false;

  /// Serializes [load], [save] and [importOriginal] so they never
  /// interleave on disk.
  Future<void> _tail = Future<void>.value();

  File get _manifest => File('${root.path}/$_manifestName');

  Directory get _originals => Directory('${root.path}/$_originalsDir');

  /// Returns the file for a canonical original path `originals/{id}.{ext}`,
  /// or throws [ArgumentError] for anything else (e.g. traversal).
  File resolve(String relativePath) {
    final id = relativePath.split('/').last.split('.').first;
    if (!isValidOriginalPath(id, relativePath)) {
      throw ArgumentError('not a valid original path');
    }
    return File('${root.path}/$relativePath');
  }

  /// Copies [source] to `originals/{id}.{extension}` and returns that
  /// relative path. [source] is never modified or deleted.
  ///
  /// Throws [ArgumentError] for an invalid id or extension and
  /// [StateError] if the destination already exists (never overwritten).
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
    if (!_extensionPattern.hasMatch(ext)) {
      throw ArgumentError('extension must be 1-5 letters or digits');
    }
    final relative = '$_originalsDir/$id.$ext';
    final target = resolve(relative);
    if (await target.exists()) {
      throw StateError('original already exists');
    }
    await _originals.create(recursive: true);
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

  /// Reads the saved session.
  ///
  /// An undecodable manifest, or one referencing a missing original, is
  /// renamed to `session.corrupt-{ms}.json` and no original is deleted.
  /// On success, leftover `.part` files are deleted, and so are files in
  /// `originals/` not referenced by the session unless a quarantined
  /// manifest still exists (its originals stay for manual recovery).
  Future<SessionLoadResult> load() => _serialized(_load);

  /// Atomically writes [session] as the manifest, then deletes originals
  /// of the previously saved session that [session] no longer references.
  ///
  /// Throws [ArgumentError] for an invalid original path and [StateError]
  /// if an original is missing, or if `session.json` exists but this store
  /// has not loaded it yet (e.g. [load] failed with an I/O error); in all
  /// these cases nothing is written.
  Future<void> save(ScanSession session) => _serialized(() => _save(session));

  Future<SessionLoadResult> _load() async {
    // Any failure below leaves the store unable to replace the manifest.
    _ready = false;
    if (!await _manifest.exists()) {
      return _known(const {}, const SessionEmpty());
    }
    final bytes = await _manifest.readAsBytes();
    final ScanSession session;
    try {
      session = decodeManifest(utf8.decode(bytes));
    } on FormatException {
      return _unrecoverable();
    }
    for (final page in session.pages) {
      if (!await resolve(page.originalPath).exists()) {
        return _unrecoverable();
      }
    }
    final referenced = _referencedPaths(session);
    // DEBT: originals of a quarantined session are kept with no UI to recover or delete them | trần: kept until app data is cleared | xem lại khi: Data Governance (spec §14) before release.
    await _deleteUnreferencedOriginals(
      referenced,
      partialOnly: await _hasQuarantinedManifest(),
    );
    return _known(referenced, SessionLoaded(session));
  }

  /// Quarantines the manifest. Its originals are no longer in [_saved], so
  /// no later [save] deletes them.
  Future<SessionLoadResult> _unrecoverable() async {
    final copy = await _quarantineManifest();
    return _known(const {}, SessionUnrecoverable(copy));
  }

  /// Records that [saved] is what the manifest on disk references.
  SessionLoadResult _known(Set<String> saved, SessionLoadResult result) {
    _saved = saved;
    _ready = true;
    return result;
  }

  Future<void> _save(ScanSession session) async {
    if (!_ready && await _manifest.exists()) {
      throw StateError('the saved session has not been loaded');
    }
    for (final page in session.pages) {
      if (!await resolve(page.originalPath).exists()) {
        throw StateError('original of a page is missing');
      }
    }
    final json = encodeManifest(session);
    final tmp = File('${_manifest.path}$_tmpSuffix');
    try {
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(_manifest.path);
    } catch (_) {
      await _deleteQuietly(tmp);
      rethrow;
    }
    final referenced = _referencedPaths(session);
    final previous = _saved;
    _saved = referenced;
    _ready = true;
    for (final path in previous.difference(referenced)) {
      // Best effort: the manifest is already saved; a leftover file is an
      // orphan that the next successful load removes.
      await _deleteQuietly(resolve(path));
    }
  }

  /// Renames the manifest to a fresh `session.corrupt-{ms}.json` (UTC
  /// epoch ms, bumped until unused) and returns its relative path.
  Future<String> _quarantineManifest() async {
    var stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    while (true) {
      final name = 'session.corrupt-$stamp.json';
      final copy = File('${root.path}/$name');
      if (!await copy.exists()) {
        await _manifest.rename(copy.path);
        return name;
      }
      stamp++;
    }
  }

  Future<bool> _hasQuarantinedManifest() => root
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

  static Set<String> _referencedPaths(ScanSession session) => {
    for (final page in session.pages) page.originalPath,
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
