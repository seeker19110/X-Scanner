import 'dart:convert';
import 'dart:math';

import 'page_quad.dart';
import 'scan_page.dart';
import 'scan_session.dart';

/// Version of the `session.json` layout written by [encodeManifest].
const int manifestSchemaVersion = 1;

/// Allowed original file extension: 1–5 lowercase letters or digits.
const String _extension = '[a-z0-9]{1,5}';

final RegExp _pageIdPattern = RegExp(r'^[0-9a-f]{32}$');
final RegExp _extensionPattern = RegExp('^$_extension\$');
final RegExp _originalPathPattern = RegExp(
  '^originals/([0-9a-f]{32})\\.($_extension)\$',
);

/// Number of coordinates in a serialized quad (x, y for TL, TR, BR, BL).
const int _quadLength = 8;

/// Whether [id] is a valid page id (32 lowercase hex characters).
bool isValidPageId(String id) => _pageIdPattern.hasMatch(id);

/// Whether [extension] is an allowed original file extension: 1–5
/// lowercase letters `a`–`z` or digits, without the dot.
bool isValidExtension(String extension) =>
    _extensionPattern.hasMatch(extension);

/// Lowercased text after the last dot of the file name in [path], or `null`
/// when the name has no dot. Directories are split on both `/` and `\`, so
/// a dot in a directory name is ignored; a trailing dot gives `''`.
String? fileExtension(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? null : name.substring(dot + 1).toLowerCase();
}

/// Whether [path] is the canonical relative original path
/// `originals/{id}.{ext}` for page [id].
bool isValidOriginalPath(String id, String path) {
  final match = _originalPathPattern.firstMatch(path);
  return match != null && match.group(1) == id && isValidPageId(id);
}

/// Serializes [session] as a `session.json` manifest.
///
/// Throws [ArgumentError] if a page has an invalid id or original path, so
/// an unreadable manifest is never written.
String encodeManifest(ScanSession session) {
  final pages = [for (final page in session.pages) _encodePage(page)];
  return jsonEncode({'schemaVersion': manifestSchemaVersion, 'pages': pages});
}

Map<String, Object> _encodePage(ScanPage page) {
  if (!isValidPageId(page.id)) {
    throw ArgumentError('page has an invalid id');
  }
  if (!isValidOriginalPath(page.id, page.originalPath)) {
    throw ArgumentError('page has an invalid original path');
  }
  final q = page.quad;
  return {
    'id': page.id,
    'original': page.originalPath,
    'quad': [
      for (final p in [q.topLeft, q.topRight, q.bottomRight, q.bottomLeft]) ...[
        p.x,
        p.y,
      ],
    ],
    'quarterTurns': page.quarterTurns,
  };
}

/// Parses and validates a `session.json` manifest.
///
/// Any deviation from the schema throws [FormatException] whose message
/// names only the offending field and page index, never user content.
ScanSession decodeManifest(String json) {
  final Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException {
    // Rethrown without the source so the manifest content is not exposed.
    throw const FormatException('manifest is not valid JSON');
  }
  if (root is! Map<String, Object?>) {
    throw const FormatException('root: must be a JSON object');
  }
  final version = root['schemaVersion'];
  if (version is! int || version != manifestSchemaVersion) {
    throw const FormatException(
      'schemaVersion: must be the integer $manifestSchemaVersion',
    );
  }
  final rawPages = root['pages'];
  if (rawPages is! List<Object?>) {
    throw const FormatException('pages: must be a list');
  }
  final pages = <ScanPage>[];
  final seen = <String>{};
  for (var i = 0; i < rawPages.length; i++) {
    final page = _decodePage(rawPages[i], 'pages[$i]');
    if (!seen.add(page.id)) {
      throw FormatException('pages[$i].id: duplicate id');
    }
    pages.add(page);
  }
  return ScanSession(pages: pages);
}

ScanPage _decodePage(Object? raw, String field) {
  if (raw is! Map<String, Object?>) {
    throw FormatException('$field: must be a JSON object');
  }
  final id = raw['id'];
  if (id is! String || !isValidPageId(id)) {
    throw FormatException('$field.id: must be 32 lowercase hex characters');
  }
  final original = raw['original'];
  if (original is! String || !isValidOriginalPath(id, original)) {
    throw FormatException(
      '$field.original: must be originals/{id}.{ext} for this page',
    );
  }
  final quad = _decodeQuad(raw['quad'], '$field.quad');
  final turns = raw['quarterTurns'];
  if (turns is! int || turns < 0 || turns > 3) {
    throw FormatException('$field.quarterTurns: must be an integer in 0..3');
  }
  return ScanPage(
    id: id,
    originalPath: original,
    quad: quad,
    quarterTurns: turns,
  );
}

PageQuad _decodeQuad(Object? raw, String field) {
  if (raw is! List<Object?> || raw.length != _quadLength) {
    throw FormatException('$field: must be a list of $_quadLength numbers');
  }
  final values = <double>[];
  for (final v in raw) {
    if (v is! num || !v.isFinite) {
      throw FormatException('$field: must contain only finite numbers');
    }
    values.add(v.toDouble());
  }
  Point<double> at(int i) => Point<double>(values[2 * i], values[2 * i + 1]);
  try {
    return PageQuad(
      topLeft: at(0),
      topRight: at(1),
      bottomRight: at(2),
      bottomLeft: at(3),
    );
  } on ArgumentError {
    throw FormatException('$field: not a valid page quad');
  }
}
