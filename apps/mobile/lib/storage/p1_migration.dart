import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/scan_document.dart';
import '../core/scan_page.dart';
import '../core/scan_session.dart';
import '../core/session_manifest.dart';

/// Why a migration did not finish; carries no path or title.
enum MigrationFailure { insufficientSpace, io }

/// Result of [P1Migration.run].
sealed class MigrationOutcome {
  const MigrationOutcome();
}

/// There is no P1 session to migrate.
final class MigrationNotNeeded extends MigrationOutcome {
  const MigrationNotNeeded();
}

/// The P1 session is the committed and verified document [docId].
final class MigrationDone extends MigrationOutcome {
  const MigrationDone(this.docId);

  final String docId;
}

/// `session/session.json` cannot be read as schema 1 or references a
/// missing original (AC-9); `session/` is left unchanged.
final class MigrationSourceUnreadable extends MigrationOutcome {
  const MigrationSourceUnreadable();
}

/// The migration stopped; `session/` is unchanged and a later run retries.
final class MigrationFailed extends MigrationOutcome {
  const MigrationFailed(this.reason);

  final MigrationFailure reason;
}

/// Free space seam; the platform implementation comes with PR-4.
abstract interface class Storage {
  Future<int> freeBytes(Directory dir);
}

enum _State { copying, committed }

/// A valid `migration.json`.
final class _Journal {
  const _Journal(this.state, this.docId);

  final _State state;
  final String docId;
}

/// What step 1 read from `session/`.
final class _Source {
  const _Source(this.session, this.totalBytes, this.modified);

  final ScanSession session;
  final int totalBytes;
  final DateTime modified;
}

/// Moves the P1 session under [appRoot] (`session/`) into one library
/// document `documents/{docId}` (XS-09 FR-6, FR-7, ADR-0011).
///
/// Originals are copied and verified byte for byte before the document
/// folder is committed by a rename; `session/` is then renamed to the first
/// unused `session.migrated`, `session.migrated-2`, … and is never deleted.
/// A journal `migration.json` makes every stopping point recoverable by the
/// next [run]. Only [FileSystemException] (and [FormatException] while
/// reading) is handled; nothing is logged. One caller at a time.
class P1Migration {
  P1Migration({
    required Directory appRoot,
    required this._storage,
    String Function()? newDocId,
  }) : _root = appRoot.path,
       _newDocId = newDocId ?? newPageId;

  final String _root;
  final Storage _storage;
  final String Function() _newDocId;

  static const int _journalVersion = 1;
  static const String _partSuffix = '.part';
  static const String _tmpSuffix = '.tmp';
  static const String _manifestName = 'document.json';
  static const String _rollbackName = 'session.migrated';

  /// Bytes compared at a time in step 5.
  static const int _chunkBytes = 1 << 20;

  String get _session => '$_root/session';
  String get _sessionManifest => '$_session/session.json';
  String get _documents => '$_root/documents';
  String get _journal => '$_root/migration.json';
  String _part(String docId) => '$_documents/$docId$_partSuffix';
  String _document(String docId) => '$_documents/$docId';

  /// Runs or resumes the migration once.
  ///
  /// Throws [StateError] if `newDocId` returns an invalid id (before
  /// anything is written).
  Future<MigrationOutcome> run() async {
    final MigrationOutcome outcome;
    if (await _exists(_journal)) {
      final journal = await _readJournal();
      if (journal == null) {
        // Never guess: leave every file as it is.
        return const MigrationFailed(MigrationFailure.io);
      }
      outcome = await _recover(journal);
    } else if (await _exists(_sessionManifest)) {
      outcome = await _migrate(null);
    } else {
      outcome = const MigrationNotNeeded();
    }
    if ((outcome is MigrationNotNeeded || outcome is MigrationDone) &&
        !await _exists(_journal)) {
      await _deleteOrphanParts();
    }
    return outcome;
  }

  /// FR-7: continues from the state recorded in [journal].
  Future<MigrationOutcome> _recover(_Journal journal) async {
    final docId = journal.docId;
    if (journal.state == _State.committed ||
        await _isDirectory(_document(docId))) {
      // The folder is only renamed into place after verification.
      return _finish(docId);
    }
    if (!await _exists(_sessionManifest)) {
      await _abandon(docId);
      return const MigrationNotNeeded();
    }
    return _migrate(docId);
  }

  /// Steps 1–6, then 7; [resumedDocId] comes from a `copying` journal.
  Future<MigrationOutcome> _migrate(String? resumedDocId) async {
    final _Source? source;
    try {
      source = await _readSource();
    } on FileSystemException {
      // Nothing was written by this run.
      return const MigrationFailed(MigrationFailure.io);
    }
    if (source == null) {
      if (resumedDocId != null) {
        await _abandon(resumedDocId);
      }
      return const MigrationSourceUnreadable();
    }
    final docId = resumedDocId ?? _newDocId();
    if (!isValidPageId(docId)) {
      throw StateError('generated document id is invalid');
    }
    // Built before any write, so an invalid document leaves no trace.
    final pages = source.session.pages;
    final json = encodeDocument(
      ScanDocument(
        id: docId,
        title: defaultDocumentTitle(source.modified.toLocal()),
        createdAt: source.modified.toUtc(),
        updatedAt: source.modified.toUtc(),
        pages: pages,
      ),
    );
    try {
      if (resumedDocId == null) {
        await _writeJournal(_State.copying, docId);
      }
      final needed = source.totalBytes + (source.totalBytes + 9) ~/ 10;
      if (await _storage.freeBytes(Directory(_root)) < needed) {
        await _abandon(docId);
        return const MigrationFailed(MigrationFailure.insufficientSpace);
      }
      await _copy(docId, pages, json);
      if (!await _verify(docId, pages) || await _exists(_document(docId))) {
        await _abandon(docId);
        return const MigrationFailed(MigrationFailure.io);
      }
      await Directory(_part(docId)).rename(_document(docId));
    } on FileSystemException {
      await _abandon(docId);
      return const MigrationFailed(MigrationFailure.io);
    }
    try {
      await _writeJournal(_State.committed, docId);
    } on FileSystemException {
      // Committed and verified; the `copying` journal plus the folder lets
      // the next run finish step 7.
      return MigrationDone(docId);
    }
    return _finish(docId);
  }

  /// Step 1: `null` when the manifest is not a readable schema 1 file or a
  /// referenced original is not a regular file.
  Future<_Source?> _readSource() async {
    if (!await _isFile(_sessionManifest)) {
      return null;
    }
    final manifest = File(_sessionManifest);
    final ScanSession session;
    try {
      session = decodeManifest(utf8.decode(await manifest.readAsBytes()));
    } on FormatException {
      return null;
    }
    var total = 0;
    for (final page in session.pages) {
      final path = '$_session/${page.originalPath}';
      if (!await _isFile(path)) {
        return null;
      }
      total += await File(path).length();
    }
    return _Source(session, total, await manifest.lastModified());
  }

  /// Step 4: fresh `{docId}.part` with copied originals and [json].
  Future<void> _copy(String docId, List<ScanPage> pages, String json) async {
    final part = _part(docId);
    if (await _exists(part)) {
      await Directory(part).delete(recursive: true);
    }
    await Directory(_documents).create(recursive: true);
    await Directory('$part/originals').create(recursive: true);
    for (final page in pages) {
      final target = '$part/${page.originalPath}';
      await File('$_session/${page.originalPath}').copy(target);
      await _sync(File(target));
    }
    await File('$part/$_manifestName').writeAsString(json, flush: true);
  }

  /// Step 5: the written manifest reads back as the same pages and every
  /// copy has the same bytes as its P1 original (D-3).
  Future<bool> _verify(String docId, List<ScanPage> pages) async {
    final part = _part(docId);
    final DocumentDecodeResult decoded;
    try {
      final bytes = await File('$part/$_manifestName').readAsBytes();
      decoded = decodeDocument(utf8.decode(bytes));
    } on FormatException {
      return false;
    }
    if (decoded is! DecodedDocument ||
        decoded.document.id != docId ||
        decoded.document.pages.length != pages.length) {
      return false;
    }
    for (var i = 0; i < pages.length; i++) {
      final written = decoded.document.pages[i];
      final page = pages[i];
      if (written.id != page.id ||
          written.originalPath != page.originalPath ||
          written.quad != page.quad ||
          written.quarterTurns != page.quarterTurns ||
          written.revision != 0) {
        return false;
      }
    }
    for (final page in pages) {
      final same = await _sameBytes(
        File('$_session/${page.originalPath}'),
        File('$part/${page.originalPath}'),
      );
      if (!same) {
        return false;
      }
    }
    return true;
  }

  /// Step 7: keeps P1 as the rollback copy and closes the journal. A
  /// failure leaves everything for the next run; the document is done.
  Future<MigrationOutcome> _finish(String docId) async {
    try {
      if (await _exists(_session)) {
        await Directory(_session).rename(await _freeRollbackPath());
      }
      await File(_journal).delete();
    } on FileSystemException {
      // The journal (or `session/`) remains; the next run completes step 7.
    }
    return MigrationDone(docId);
  }

  /// First of `session.migrated`, `session.migrated-2`, … with nothing at
  /// its path, so an earlier rollback copy is never replaced.
  Future<String> _freeRollbackPath() async {
    for (var n = 1; ; n++) {
      final path = n == 1
          ? '$_root/$_rollbackName'
          : '$_root/$_rollbackName-$n';
      if (!await _exists(path)) {
        return path;
      }
    }
  }

  /// Reads `migration.json`; `null` when it cannot be read or is not
  /// exactly a version 1 journal with a known state and a valid id.
  Future<_Journal?> _readJournal() async {
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(await File(_journal).readAsBytes()));
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
    if (root is! Map<String, Object?>) {
      return null;
    }
    final version = root['version'];
    final docId = root['docId'];
    final state = switch (root['state']) {
      'copying' => _State.copying,
      'committed' => _State.committed,
      _ => null,
    };
    if (version is! int ||
        version != _journalVersion ||
        state == null ||
        docId is! String ||
        !isValidPageId(docId)) {
      return null;
    }
    return _Journal(state, docId);
  }

  /// Atomically replaces the journal: `.tmp`, flush, rename.
  Future<void> _writeJournal(_State state, String docId) async {
    final json = jsonEncode({
      'version': _journalVersion,
      'state': state.name,
      'docId': docId,
    });
    final tmp = File('$_journal$_tmpSuffix');
    try {
      await tmp.writeAsString(json, flush: true);
    } on FileSystemException {
      await _deleteQuietly(tmp);
      rethrow;
    }
    await tmp.rename(_journal);
  }

  /// Removes this migration's own copy and journal; never touches
  /// `session/`, a committed document or a rollback copy.
  Future<void> _abandon(String docId) async {
    await _deleteQuietly(Directory(_part(docId)));
    await _deleteQuietly(File(_journal));
  }

  /// Step 8 (FR-4): deletes `documents/{id}.part` folders left by an
  /// interrupted copy. Links, files and other names are skipped; failures
  /// are ignored.
  Future<void> _deleteOrphanParts() async {
    try {
      if (!await _isDirectory(_documents)) {
        return;
      }
      final entries = await Directory(_documents)
          .list(followLinks: false)
          .toList();
      for (final entry in entries) {
        final name = entry.path.substring(entry.path.lastIndexOf('/') + 1);
        if (!name.endsWith(_partSuffix) || !await _isDirectory(entry.path)) {
          continue;
        }
        final id = name.substring(0, name.length - _partSuffix.length);
        if (isValidPageId(id)) {
          await _deleteQuietly(Directory(entry.path));
        }
      }
    } on FileSystemException {
      // Best effort: a leftover `.part` is retried by the next run.
    }
  }

  /// Whether the two files have the same length and bytes, read in chunks.
  static Future<bool> _sameBytes(File a, File b) async {
    if (await a.length() != await b.length()) {
      return false;
    }
    final readA = await a.open();
    try {
      final readB = await b.open();
      try {
        while (true) {
          final chunkA = await readA.read(_chunkBytes);
          final chunkB = await readB.read(_chunkBytes);
          if (!_equalBytes(chunkA, chunkB)) {
            return false;
          }
          if (chunkA.isEmpty) {
            return true;
          }
        }
      } finally {
        await readB.close();
      }
    } finally {
      await readA.close();
    }
  }

  static bool _equalBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /// Forces a copied file's contents to disk.
  static Future<void> _sync(File file) async {
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  /// Whether anything (file, folder or link) exists at [path].
  static Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) !=
      FileSystemEntityType.notFound;

  static Future<bool> _isFile(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) ==
      FileSystemEntityType.file;

  static Future<bool> _isDirectory(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) ==
      FileSystemEntityType.directory;

  static Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // Already gone or not removable; the outcome stands.
    }
  }
}
