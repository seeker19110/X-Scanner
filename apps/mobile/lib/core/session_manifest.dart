import 'dart:convert';
import 'dart:math';

import 'page_quad.dart';
import 'scan_document.dart';
import 'scan_page.dart';
import 'scan_session.dart';

/// Version of the `session.json` layout written by [encodeManifest].
const int manifestSchemaVersion = 1;

/// Version of the `document.json` layout written by [encodeDocument].
const int documentSchemaVersion = 2;

/// Allowed original file extension: 1–5 lowercase letters or digits.
const String _extension = '[a-z0-9]{1,5}';

final RegExp _pageIdPattern = RegExp(r'^[0-9a-f]{32}$');
final RegExp _extensionPattern = RegExp('^$_extension\$');
final RegExp _originalPathPattern = RegExp(
  '^originals/([0-9a-f]{32})\\.($_extension)\$',
);

/// A stored time: ISO-8601 in UTC with `Z` and at most microseconds.
final RegExp _utcTimePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,6})?Z$',
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

/// Serializes [document] as a `document.json` (schema 2).
///
/// Throws [ArgumentError] if a page has an invalid id or original path, or a
/// time cannot be written in a form [decodeDocument] accepts, so an
/// unreadable document is never written.
String encodeDocument(ScanDocument document) {
  final pages = [
    for (final page in document.pages) _encodePage(page, withRevision: true),
  ];
  return jsonEncode({
    'schemaVersion': documentSchemaVersion,
    'document': {
      'id': document.id,
      'title': document.title,
      'createdAt': _encodeTime(document.createdAt),
      'updatedAt': _encodeTime(document.updatedAt),
    },
    'pages': pages,
  });
}

/// [ScanDocument] keeps times in UTC, so this always ends in `Z`; only
/// years outside 0000–9999 do not fit the stored form.
String _encodeTime(DateTime time) {
  final text = time.toUtc().toIso8601String();
  if (!_utcTimePattern.hasMatch(text)) {
    throw ArgumentError('document has a time outside years 0000-9999');
  }
  return text;
}

Map<String, Object> _encodePage(ScanPage page, {bool withRevision = false}) {
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
    if (withRevision) 'revision': page.revision,
  };
}

/// Parses and validates a `session.json` manifest.
///
/// Any deviation from the schema throws [FormatException] whose message
/// names only the offending field and page index, never user content.
ScanSession decodeManifest(String json) {
  final root = _decodeRoot(json, 'manifest');
  final version = root['schemaVersion'];
  if (version is! int || version != manifestSchemaVersion) {
    throw const FormatException(
      'schemaVersion: must be the integer $manifestSchemaVersion',
    );
  }
  return ScanSession(pages: _decodePages(root['pages']));
}

/// Result of [decodeDocument].
sealed class DocumentDecodeResult {
  const DocumentDecodeResult();
}

/// A valid schema 2 document.
final class DecodedDocument extends DocumentDecodeResult {
  const DecodedDocument(this.document);

  final ScanDocument document;
}

/// The file has a newer schema than this app knows (XS-08 FR-7): it is not
/// damaged and must be neither quarantined nor deleted.
final class DocumentNeedsAppUpdate extends DocumentDecodeResult {
  const DocumentNeedsAppUpdate();
}

/// Parses and validates a `document.json` (schema 2).
///
/// A newer integer `schemaVersion` gives [DocumentNeedsAppUpdate] without
/// checking the rest. Any other deviation throws [FormatException] whose
/// message names only the offending field and page index, never user
/// content.
DocumentDecodeResult decodeDocument(String json) {
  final root = _decodeRoot(json, 'document');
  final version = root['schemaVersion'];
  if (version is int && version > documentSchemaVersion) {
    return const DocumentNeedsAppUpdate();
  }
  if (version is! int || version != documentSchemaVersion) {
    throw const FormatException(
      'schemaVersion: must be the integer $documentSchemaVersion',
    );
  }
  final raw = root['document'];
  if (raw is! Map<String, Object?>) {
    throw const FormatException('document: must be a JSON object');
  }
  final id = raw['id'];
  if (id is! String || !isValidPageId(id)) {
    throw const FormatException(
      'document.id: must be 32 lowercase hex characters',
    );
  }
  final title = raw['title'];
  if (title is! String || !isValidDocumentTitle(title)) {
    throw const FormatException(
      'document.title: must be 1-120 characters without surrounding spaces '
      'or control characters',
    );
  }
  final createdAt = _decodeTime(raw['createdAt'], 'document.createdAt');
  final updatedAt = _decodeTime(raw['updatedAt'], 'document.updatedAt');
  if (updatedAt.isBefore(createdAt)) {
    throw const FormatException(
      'document.updatedAt: must not be before createdAt',
    );
  }
  return DecodedDocument(
    ScanDocument(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pages: _decodePages(root['pages'], withRevision: true),
    ),
  );
}

/// Decodes [json] into a root object; [name] labels the JSON error.
Map<String, Object?> _decodeRoot(String json, String name) {
  final Object? root;
  try {
    root = jsonDecode(json);
  } on FormatException {
    // Rethrown without the source so the file content is not exposed.
    throw FormatException('$name is not valid JSON');
  }
  if (root is! Map<String, Object?>) {
    throw const FormatException('root: must be a JSON object');
  }
  return root;
}

List<ScanPage> _decodePages(Object? raw, {bool withRevision = false}) {
  if (raw is! List<Object?>) {
    throw const FormatException('pages: must be a list');
  }
  final pages = <ScanPage>[];
  final seen = <String>{};
  for (var i = 0; i < raw.length; i++) {
    final page = _decodePage(raw[i], 'pages[$i]', withRevision: withRevision);
    if (!seen.add(page.id)) {
      throw FormatException('pages[$i].id: duplicate id');
    }
    pages.add(page);
  }
  return pages;
}

/// Reads a time written by [_encodeTime]. [DateTime.parse] rolls over
/// out-of-range fields (`02-30` becomes `03-02`), so the parsed fields must
/// equal the written ones.
DateTime _decodeTime(Object? raw, String field) {
  final match = raw is String ? _utcTimePattern.firstMatch(raw) : null;
  final time = match == null ? null : DateTime.tryParse(raw! as String);
  if (match == null ||
      time == null ||
      !time.isUtc ||
      time.year != int.parse(match.group(1)!) ||
      time.month != int.parse(match.group(2)!) ||
      time.day != int.parse(match.group(3)!) ||
      time.hour != int.parse(match.group(4)!) ||
      time.minute != int.parse(match.group(5)!) ||
      time.second != int.parse(match.group(6)!)) {
    throw FormatException('$field: must be an ISO-8601 UTC time ending in Z');
  }
  return time;
}

/// Schema 1 ignores a `revision` field and gives revision 0; schema 2
/// ([withRevision]) requires it.
ScanPage _decodePage(Object? raw, String field, {bool withRevision = false}) {
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
  final revision = withRevision ? raw['revision'] : 0;
  if (revision is! int || revision < 0) {
    throw FormatException('$field.revision: must be a non-negative integer');
  }
  return ScanPage(
    id: id,
    originalPath: original,
    quad: quad,
    quarterTurns: turns,
    revision: revision,
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
