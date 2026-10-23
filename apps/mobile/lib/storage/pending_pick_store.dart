import 'dart:convert';
import 'dart:io';

import '../core/session_manifest.dart';

/// A sanitized persistence failure; carries no file or platform details.
final class PendingPickFailure implements Exception {
  const PendingPickFailure({this.sizeRejected = false});

  /// An empty or over-cap original; ordinary storage failures stay false.
  final bool sizeRejected;

  @override
  String toString() => 'Pending image could not be recovered';
}

/// The reserved destination of one picker operation.
final class PendingPick {
  const PendingPick._({
    required this.docId,
    required this.pageId,
    this.replacePageId,
    this.createOwner = false,
    this.cacheRelativePath,
    this.extension,
  });

  final String docId;
  final String pageId;
  final String? replacePageId;
  final bool createOwner;
  final String? cacheRelativePath;
  final String? extension;
}

/// Holds one picker intent and its original outside document folders.
///
/// All operations share a queue. Nothing is logged, and unknown state is
/// left untouched. The caller alone acknowledges a durable document commit
/// through [complete]; this store never reads or changes a document.
class PendingPickStore {
  PendingPickStore({
    required this.dir,
    required this.cacheDir,
    required this.maxBytes,
  }) {
    if (maxBytes <= 0) {
      throw ArgumentError('maxBytes must be positive');
    }
  }

  final Directory dir;
  final Directory cacheDir;
  final int maxBytes;

  static const _journalLimit = 8192;
  static const _chunkBytes = 64 * 1024;
  static const _fields = {
    'version',
    'docId',
    'pageId',
    'replacePageId',
    'createOwner',
    'cacheRelativePath',
    'extension',
  };

  Future<void> _tail = Future<void>.value();

  File get _journal => File('${dir.path}/intent.json');
  File get _tmp => File('${_journal.path}.tmp');
  File _original(PendingPick pick) =>
      File('${dir.path}/original.${pick.extension}');
  File _part(PendingPick pick) => File('${_original(pick).path}.part');

  /// Reads bounded, validated metadata without repairing or deleting files.
  Future<PendingPick?> load() => _queued(_load);

  Future<PendingPick> begin({
    required String docId,
    required String pageId,
    String? replacePageId,
    bool createOwner = false,
  }) => _queued(() async {
    final pick = PendingPick._(
      docId: docId,
      pageId: pageId,
      replacePageId: replacePageId,
      createOwner: createOwner,
    );
    _validate(pick);
    if (await _load() != null) throw const PendingPickFailure();
    await dir.create(recursive: true);
    await _write(pick);
    return pick;
  });

  /// Records the validated cache-relative result before copying or decoding.
  Future<PendingPick> remember(PendingPick pick, String resultPath) =>
      _queued(() async {
        final current = await _current(pick);
        final relative = await _cacheRelative(resultPath);
        final rawExtension = fileExtension(relative);
        final extension = rawExtension != null && isValidExtension(rawExtension)
            ? rawExtension
            : 'jpg';
        if (current.cacheRelativePath != null) {
          if (current.cacheRelativePath != relative ||
              current.extension != extension) {
            throw const PendingPickFailure();
          }
          return current;
        }
        final next = PendingPick._(
          docId: current.docId,
          pageId: current.pageId,
          replacePageId: current.replacePageId,
          createOwner: current.createOwner,
          cacheRelativePath: relative,
          extension: extension,
        );
        await _write(next);
        return next;
      });

  /// Copies a bounded original before decode. A complete copy is reusable
  /// even after Android removes the source cache file.
  Future<File> stage(PendingPick pick) => _queued(() async {
    final current = await _current(pick);
    if (current.cacheRelativePath == null) throw const PendingPickFailure();
    final original = _original(current);
    if (await _kind(original.path) == FileSystemEntityType.file) {
      await _checkSize(original);
      return original;
    }
    final source = await _source(current);
    final expectedBytes = await _checkSize(source);
    final input = await source.open();
    try {
      final part = _part(current);
      if (await _kind(part.path) == FileSystemEntityType.file) {
        await part.delete();
      }
      await part.create(exclusive: true);
      final output = await part.open(mode: FileMode.write);
      try {
        var total = 0;
        while (true) {
          final remaining = maxBytes - total;
          final count = remaining < _chunkBytes ? remaining + 1 : _chunkBytes;
          final bytes = await input.read(count);
          if (bytes.isEmpty) break;
          total += bytes.length;
          if (total > maxBytes) {
            throw const PendingPickFailure(sizeRejected: true);
          }
          await output.writeFrom(bytes);
        }
        if (total != expectedBytes || total == 0) {
          throw const PendingPickFailure();
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (await _kind(original.path) != FileSystemEntityType.notFound) {
        throw const PendingPickFailure();
      }
      await part.rename(original.path);
      return original;
    } finally {
      await input.close();
    }
  });

  /// Removes an empty intent only. A loaded recovery returning no result
  /// must never call this; that distinction belongs to the caller.
  Future<void> cancel(PendingPick pick) => _queued(() async {
    final current = await _current(pick);
    if (current.cacheRelativePath != null) throw const PendingPickFailure();
    await _journal.delete();
  });

  /// Acknowledges a durable manifest. Known copy files go first and the
  /// journal last, so interrupted cleanup retains its operation identity.
  Future<void> complete(PendingPick pick) => _queued(() async {
    final current = await _current(pick);
    if (current.cacheRelativePath == null) throw const PendingPickFailure();
    for (final file in [_original(current), _part(current)]) {
      if (await _kind(file.path) == FileSystemEntityType.file) {
        await file.delete();
      }
    }
    await _journal.delete();
  });

  /// Preserves a rejected input without blocking the next capture.
  Future<void> retainRejected(PendingPick pick) => _queued(() async {
    final current = await _current(pick);
    if (current.cacheRelativePath == null) throw const PendingPickFailure();
    final original = _original(current);
    var staged = false;
    if (await _kind(original.path) == FileSystemEntityType.file) {
      final size = await original.length();
      staged = size > 0 && size <= maxBytes;
    }
    if (!staged) await _source(current);
    final folder = dir.uri.pathSegments.lastWhere((part) => part.isNotEmpty);
    final target = '${dir.parent.path}/$folder.rejected-${current.pageId}';
    if (await _kind(target) != FileSystemEntityType.notFound) {
      throw const PendingPickFailure();
    }
    // DEBT: rejected picker inputs are retained outside the active intent without recovery UI | trần: private retained data until XS10/manualreview; unstaged oversized source still relies on OS cache | xem lại khi: XS10 defines retention/recovery or before distributed release.
    await dir.rename(target);
  });

  Future<PendingPick?> _load() async {
    final directoryType = await _kind(dir.path);
    if (directoryType == FileSystemEntityType.notFound) return null;
    if (directoryType != FileSystemEntityType.directory) {
      throw const PendingPickFailure();
    }
    final entries = await dir.list(followLinks: false).toList();
    if (entries.isEmpty) return null;
    if (await _kind(_journal.path) != FileSystemEntityType.file) {
      throw const PendingPickFailure();
    }
    final input = await _journal.open();
    final bytes = <int>[];
    try {
      while (bytes.length <= _journalLimit) {
        final chunk = await input.read(_journalLimit + 1 - bytes.length);
        if (chunk.isEmpty) break;
        bytes.addAll(chunk);
      }
    } finally {
      await input.close();
    }
    if (bytes.length > _journalLimit) throw const PendingPickFailure();
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map<String, Object?> ||
        raw.length != _fields.length ||
        !_fields.every(raw.containsKey) ||
        raw['version'] is! int ||
        raw['version'] != 1 ||
        raw['docId'] is! String ||
        raw['pageId'] is! String ||
        raw['createOwner'] is! bool ||
        (raw['replacePageId'] != null && raw['replacePageId'] is! String) ||
        (raw['cacheRelativePath'] != null &&
            raw['cacheRelativePath'] is! String) ||
        (raw['extension'] != null && raw['extension'] is! String)) {
      throw const PendingPickFailure();
    }
    final pick = PendingPick._(
      docId: raw['docId']! as String,
      pageId: raw['pageId']! as String,
      replacePageId: raw['replacePageId'] as String?,
      createOwner: raw['createOwner']! as bool,
      cacheRelativePath: raw['cacheRelativePath'] as String?,
      extension: raw['extension'] as String?,
    );
    _validate(pick);
    final names = {
      'intent.json',
      if (pick.extension != null) ...[
        'original.${pick.extension}',
        'original.${pick.extension}.part',
      ],
    };
    for (final entry in entries) {
      if (!names.contains(entry.uri.pathSegments.last) ||
          await _kind(entry.path) != FileSystemEntityType.file) {
        throw const PendingPickFailure();
      }
    }
    return pick;
  }

  Future<PendingPick> _current(PendingPick pick) async {
    final current = await _load();
    if (current == null ||
        current.docId != pick.docId ||
        current.pageId != pick.pageId ||
        current.replacePageId != pick.replacePageId ||
        current.createOwner != pick.createOwner) {
      throw const PendingPickFailure();
    }
    return current;
  }

  static void _validate(PendingPick pick) {
    final oldId = pick.replacePageId;
    final relative = pick.cacheRelativePath;
    final extension = pick.extension;
    if (!isValidPageId(pick.docId) ||
        !isValidPageId(pick.pageId) ||
        (oldId != null &&
            (!isValidPageId(oldId) ||
                oldId == pick.pageId ||
                pick.createOwner)) ||
        ((relative == null) != (extension == null)) ||
        (relative != null && !_validRelative(relative)) ||
        (extension != null && !isValidExtension(extension))) {
      throw const PendingPickFailure();
    }
  }

  static bool _validRelative(String path) =>
      path.isNotEmpty &&
      path.length <= 2048 &&
      !path.contains('\\') &&
      !path.contains('\u0000') &&
      !path.contains(':') &&
      path.split('/').every((s) => s.isNotEmpty && s != '.' && s != '..');

  Future<String> _cacheRelative(String path) async {
    if (await _kind(cacheDir.path) != FileSystemEntityType.directory ||
        await _kind(path) != FileSystemEntityType.file) {
      throw const PendingPickFailure();
    }
    final root = await cacheDir.resolveSymbolicLinks();
    final resolved = await File(path).resolveSymbolicLinks();
    final prefix = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    if (!resolved.startsWith(prefix)) throw const PendingPickFailure();
    final relative = resolved.substring(prefix.length);
    if (!_validRelative(relative)) throw const PendingPickFailure();
    return relative;
  }

  Future<File> _source(PendingPick pick) async {
    final relative = pick.cacheRelativePath;
    if (relative == null) throw const PendingPickFailure();
    final source = File('${cacheDir.path}/$relative');
    if (await _cacheRelative(source.path) != relative) {
      throw const PendingPickFailure();
    }
    return source;
  }

  Future<int> _checkSize(File file) async {
    final size = await file.length();
    if (size <= 0 || size > maxBytes) {
      throw const PendingPickFailure(sizeRejected: true);
    }
    return size;
  }

  Future<void> _write(PendingPick pick) async {
    final json = jsonEncode({
      'version': 1,
      'docId': pick.docId,
      'pageId': pick.pageId,
      'replacePageId': pick.replacePageId,
      'createOwner': pick.createOwner,
      'cacheRelativePath': pick.cacheRelativePath,
      'extension': pick.extension,
    });
    if (utf8.encode(json).length > _journalLimit) {
      throw const PendingPickFailure();
    }
    if (await _kind(_tmp.path) != FileSystemEntityType.notFound) {
      throw const PendingPickFailure();
    }
    await _tmp.create(exclusive: true);
    await _tmp.writeAsString(json, flush: true);
    await _tmp.rename(_journal.path);
  }

  static Future<FileSystemEntityType> _kind(String path) =>
      FileSystemEntity.type(path, followLinks: false);

  Future<T> _queued<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      try {
        return await operation();
      } on FileSystemException {
        throw const PendingPickFailure();
      } on FormatException {
        throw const PendingPickFailure();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
