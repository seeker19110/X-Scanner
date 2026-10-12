import 'dart:convert';
import 'dart:io';

import '../core/scan_document.dart';
import '../core/session_manifest.dart';
import 'document_store.dart';

/// One folder of the library, as returned by [LibraryStore.list].
sealed class LibraryEntry {
  const LibraryEntry(this.docId);

  /// The folder name.
  final String docId;
}

/// A readable document whose id equals its folder name.
final class LibraryDocument extends LibraryEntry {
  LibraryDocument(this.document) : super(document.id);

  final ScanDocument document;
}

/// `document.json` has a newer schema than this app knows (XS-08 FR-7).
final class LibraryNeedsUpdate extends LibraryEntry {
  const LibraryNeedsUpdate(super.docId);
}

/// `document.json` is missing, unreadable, invalid or has another id.
final class LibraryUnreadable extends LibraryEntry {
  const LibraryUnreadable(super.docId);
}

/// The library under [root] (`documents/`): one folder per document,
/// `{docId}/document.json` plus its originals.
///
/// [list] only reads; [create] adds a folder through `{docId}.part`. Nothing
/// is logged and no error message contains a title or a path.
class LibraryStore {
  LibraryStore(this.root);

  final Directory root;

  static const String _manifestName = 'document.json';
  static const String _partSuffix = '.part';

  /// Every document folder, without changing anything on disk.
  ///
  /// Only directories named by a valid id are considered (files, links,
  /// other names and `.part` folders are skipped). Readable documents come
  /// first, newest [ScanDocument.updatedAt] first and ties by id; the other
  /// entries follow by id. A missing [root] gives an empty list; an I/O
  /// error while listing [root] is thrown as [FileSystemException].
  Future<List<LibraryEntry>> list() async {
    if (!await root.exists()) {
      return [];
    }
    final entries = <LibraryEntry>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (isValidPageId(name)) {
        entries.add(await _read(entity, name));
      }
    }
    return entries..sort(_compare);
  }

  /// Returns the store of document [docId] without touching the disk.
  ///
  /// Throws [ArgumentError] for an invalid id.
  DocumentStore open(String docId) {
    if (!isValidPageId(docId)) {
      throw ArgumentError('docId must be 32 lowercase hex characters');
    }
    return DocumentStore(Directory('${root.path}/$docId'));
  }

  /// Creates the folder of the empty [document] and returns its store; call
  /// [DocumentStore.load] before [DocumentStore.save].
  ///
  /// The manifest is written into `{id}.part/`, which is then renamed to
  /// `{id}/`, so a folder named by an id always has a manifest. Throws
  /// [ArgumentError] if [document] has pages and [StateError] if `{id}` or
  /// `{id}.part` already exists; in both cases nothing is written. Any
  /// other failure removes `{id}.part` and is rethrown.
  Future<DocumentStore> create(ScanDocument document) async {
    if (document.pages.isNotEmpty) {
      throw ArgumentError('a new document must have no pages');
    }
    final json = encodeDocument(document);
    final target = Directory('${root.path}/${document.id}');
    final part = Directory('${target.path}$_partSuffix');
    if (await _exists(target) || await _exists(part)) {
      throw StateError('document folder already exists');
    }
    await root.create(recursive: true);
    try {
      await part.create();
      await File('${part.path}/$_manifestName')
          .writeAsString(json, flush: true);
      if (await _exists(target)) {
        throw StateError('document folder already exists');
      }
      await part.rename(target.path);
    } catch (_) {
      await _deleteQuietly(part);
      rethrow;
    }
    return DocumentStore(target);
  }

  /// Reads the manifest of folder [dir] named [docId]; never throws.
  static Future<LibraryEntry> _read(Directory dir, String docId) async {
    try {
      final bytes = await File('${dir.path}/$_manifestName').readAsBytes();
      return switch (decodeDocument(utf8.decode(bytes))) {
        DecodedDocument(:final document) when document.id == docId =>
          LibraryDocument(document),
        DecodedDocument() => LibraryUnreadable(docId),
        DocumentNeedsAppUpdate() => LibraryNeedsUpdate(docId),
      };
    } on FileSystemException {
      return LibraryUnreadable(docId);
    } on FormatException {
      return LibraryUnreadable(docId);
    }
  }

  /// Readable documents first (newest first, then by id); the rest by id.
  static int _compare(LibraryEntry a, LibraryEntry b) {
    if (a is LibraryDocument && b is LibraryDocument) {
      final byTime = b.document.updatedAt.compareTo(a.document.updatedAt);
      return byTime != 0 ? byTime : a.docId.compareTo(b.docId);
    }
    if (a is LibraryDocument) {
      return -1;
    }
    if (b is LibraryDocument) {
      return 1;
    }
    return a.docId.compareTo(b.docId);
  }

  /// Whether anything (file, folder or link) exists at [dir]'s path.
  static Future<bool> _exists(Directory dir) async =>
      await FileSystemEntity.type(dir.path, followLinks: false) !=
      FileSystemEntityType.notFound;

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Already gone or not removable; the original error is rethrown.
    }
  }
}
