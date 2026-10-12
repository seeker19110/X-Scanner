import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';

const String _idA = '0123456789abcdef0123456789abcdef';
const String _idB = 'fedcba9876543210fedcba9876543210';
const String _idC = 'cccccccccccccccccccccccccccccccc';
const String _docId = 'dddddddddddddddddddddddddddddddd';

final PageQuad _skewed = PageQuad(
  topLeft: const Point<double>(0.1, 0.05),
  topRight: const Point<double>(0.93, 0.12),
  bottomRight: const Point<double>(0.88, 0.97),
  bottomLeft: const Point<double>(0.02, 0.9),
);

ScanSession _session() => ScanSession(
  pages: [
    ScanPage(
      id: _idA,
      originalPath: 'originals/$_idA.jpg',
      quad: _skewed,
      quarterTurns: 3,
    ),
    ScanPage(id: _idB, originalPath: 'originals/$_idB.png'),
  ],
);

Map<String, Object?> _validPage([String id = _idA]) => {
  'id': id,
  'original': 'originals/$id.jpg',
  'quad': [0, 0, 1, 0, 1, 1, 0, 1],
  'quarterTurns': 0,
};

Map<String, Object?> _withPage(Map<String, Object?> page) => {
  'schemaVersion': 1,
  'pages': [page],
};

Map<String, Object?> _pageWith(String key, Object? value) =>
    _withPage({..._validPage(), key: value});

Map<String, Object?> _validDocument() => {
  'schemaVersion': 2,
  'document': {
    'id': _docId,
    'title': 'Hợp đồng',
    'createdAt': '2026-10-12T09:00:00Z',
    'updatedAt': '2026-10-12T09:05:00.123456Z',
  },
  'pages': [
    {..._validPage(), 'revision': 2},
  ],
};

Map<String, Object?> _documentWith(String key, Object? value) {
  final root = _validDocument();
  final document = {...root['document']! as Map<String, Object?>, key: value};
  return {...root, 'document': document};
}

Map<String, Object?> _documentWithout(String key) {
  final root = _validDocument();
  final document = {...root['document']! as Map<String, Object?>}..remove(key);
  return {...root, 'document': document};
}

Map<String, Object?> _documentPageWith(String key, Object? value) {
  final root = _validDocument();
  final page = {
    ...(root['pages']! as List<Object?>).single! as Map,
    key: value,
  };
  return {
    ...root,
    'pages': [page],
  };
}

Matcher _formatError(String field) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(field)),
);

void main() {
  group('encode/decode', () {
    test('round trip keeps ids, paths, quads and rotation', () {
      final original = _session();
      final decoded = decodeManifest(encodeManifest(original));
      expect(decoded.pages, hasLength(2));
      for (var i = 0; i < 2; i++) {
        final a = original.pages[i];
        final b = decoded.pages[i];
        expect(b.id, a.id);
        expect(b.originalPath, a.originalPath);
        expect(b.quad, a.quad);
        expect(b.quarterTurns, a.quarterTurns);
      }
    });

    test('encodes the documented schema', () {
      final map =
          jsonDecode(encodeManifest(_session())) as Map<String, Object?>;
      expect(map['schemaVersion'], manifestSchemaVersion);
      final pages = map['pages']! as List<Object?>;
      expect(pages.first, {
        'id': _idA,
        'original': 'originals/$_idA.jpg',
        'quad': [0.1, 0.05, 0.93, 0.12, 0.88, 0.97, 0.02, 0.9],
        'quarterTurns': 3,
      });
    });

    test('empty session round trips', () {
      expect(decodeManifest(encodeManifest(ScanSession.empty)).pages, isEmpty);
    });

    test('refuses to encode a page whose original path is invalid', () {
      final bad = ScanSession(
        pages: [ScanPage(id: _idA, originalPath: '/etc/passwd')],
      );
      expect(() => encodeManifest(bad), throwsArgumentError);
      final badId = ScanSession(
        pages: [ScanPage(id: 'p1', originalPath: 'originals/p1.jpg')],
      );
      expect(() => encodeManifest(badId), throwsArgumentError);
    });

    test('accepts integer quad coordinates', () {
      final session = decodeManifest(jsonEncode(_withPage(_validPage())));
      expect(session.pages.single.quad, PageQuad.fullFrame);
    });
  });

  group('decode rejects', () {
    final cases = <String, (Object, String)>{
      'unparsable JSON': ('{not json', 'JSON'),
      'root that is a list': ('[]', 'root'),
      'root that is a number': ('1', 'root'),
      'schemaVersion 2': (
        {'schemaVersion': 2, 'pages': <Object>[]},
        'schemaVersion',
      ),
      'schemaVersion "1"': (
        {'schemaVersion': '1', 'pages': <Object>[]},
        'schemaVersion',
      ),
      'schemaVersion 1.5': (
        {'schemaVersion': 1.5, 'pages': <Object>[]},
        'schemaVersion',
      ),
      'missing schemaVersion': ({'pages': <Object>[]}, 'schemaVersion'),
      'pages not a list': (
        {'schemaVersion': 1, 'pages': <String, Object>{}},
        'pages',
      ),
      'missing pages': ({'schemaVersion': 1}, 'pages'),
      'page not an object': (
        {
          'schemaVersion': 1,
          'pages': [1],
        },
        'pages[0]',
      ),
      'id too short': (_pageWith('id', 'abc'), 'pages[0].id'),
      'id uppercase': (_pageWith('id', _idA.toUpperCase()), 'pages[0].id'),
      'id not a string': (_pageWith('id', 7), 'pages[0].id'),
      'duplicate id': (
        {
          'schemaVersion': 1,
          'pages': [_validPage(), _validPage()],
        },
        'pages[1].id',
      ),
      'original /etc/passwd': (
        _pageWith('original', '/etc/passwd'),
        'pages[0].original',
      ),
      'original with ..': (
        _pageWith('original', 'originals/../x.jpg'),
        'pages[0].original',
      ),
      'original of another id': (
        _pageWith('original', 'originals/$_idB.jpg'),
        'pages[0].original',
      ),
      'original with bad extension': (
        _pageWith('original', 'originals/$_idA.JPEG'),
        'pages[0].original',
      ),
      'original not a string': (_pageWith('original', 1), 'pages[0].original'),
      'quad not a list': (_pageWith('quad', 'x'), 'pages[0].quad'),
      'quad with 7 numbers': (
        _pageWith('quad', [0, 0, 1, 0, 1, 1, 0]),
        'pages[0].quad',
      ),
      'quad with 9 numbers': (
        _pageWith('quad', [0, 0, 1, 0, 1, 1, 0, 1, 0]),
        'pages[0].quad',
      ),
      'quad with a string': (
        _pageWith('quad', [0, 0, 1, 0, 1, 1, 0, '1']),
        'pages[0].quad',
      ),
      'quad out of bounds': (
        _pageWith('quad', [0, 0, 2, 0, 1, 1, 0, 1]),
        'pages[0].quad',
      ),
      'quad counter-clockwise': (
        _pageWith('quad', [0, 0, 0, 1, 1, 1, 1, 0]),
        'pages[0].quad',
      ),
      'quarterTurns 4': (_pageWith('quarterTurns', 4), 'pages[0].quarterTurns'),
      'quarterTurns -1': (
        _pageWith('quarterTurns', -1),
        'pages[0].quarterTurns',
      ),
      'quarterTurns 1.5': (
        _pageWith('quarterTurns', 1.5),
        'pages[0].quarterTurns',
      ),
      'quarterTurns missing': (
        _withPage({..._validPage()}..remove('quarterTurns')),
        'pages[0].quarterTurns',
      ),
    };

    for (final MapEntry(key: name, value: (input, field)) in cases.entries) {
      test(name, () {
        final json = input is String ? input : jsonEncode(input);
        expect(() => decodeManifest(json), _formatError(field));
      });
    }

    test('non-finite quad values (not expressible in JSON) are rejected', () {
      // 1e999 parses to infinity in Dart.
      const json =
          '{"schemaVersion":1,"pages":[{"id":"$_idA",'
          '"original":"originals/$_idA.jpg",'
          '"quad":[0,0,1e999,0,1,1,0,1],"quarterTurns":0}]}';
      expect(() => decodeManifest(json), _formatError('pages[0].quad'));
    });

    test('error messages do not echo user content', () {
      const secret = 'originals/../secret-name.jpg';
      try {
        decodeManifest(jsonEncode(_pageWith('original', secret)));
        fail('expected FormatException');
      } on FormatException catch (e) {
        expect(e.toString(), isNot(contains('secret-name')));
        expect(e.source, isNull);
      }
      try {
        decodeManifest('{"secret-key": ');
        fail('expected FormatException');
      } on FormatException catch (e) {
        expect(e.toString(), isNot(contains('secret-key')));
        expect(e.source, isNull);
      }
    });
  });

  group('isValidOriginalPath', () {
    test('accepts the canonical path', () {
      expect(isValidOriginalPath(_idA, 'originals/$_idA.jpg'), isTrue);
      expect(isValidOriginalPath(_idA, 'originals/$_idA.heic'), isTrue);
      expect(isValidOriginalPath(_idA, 'originals/$_idA.a1b2c'), isTrue);
    });

    test('rejects everything else', () {
      for (final path in [
        '/etc/passwd',
        'originals/../x.jpg',
        'originals/$_idB.jpg',
        'originals/$_idA',
        'originals/$_idA.',
        'originals/$_idA.abcdef',
        'originals/$_idA.JPG',
        'originals/$_idA.jpg.part',
        'originals/$_idA.jpg/',
        '/originals/$_idA.jpg',
        'originals\\$_idA.jpg',
        'originals/$_idA.jpg\n',
      ]) {
        expect(isValidOriginalPath(_idA, path), isFalse, reason: path);
      }
      expect(isValidOriginalPath('abc', 'originals/abc.jpg'), isFalse);
    });
  });

  group('fileExtension (F-024)', () {
    test('lowercases the text after the last dot of the file name', () {
      expect(fileExtension('a/b.JPG'), 'jpg');
      expect(fileExtension(r'a\b.png'), 'png');
    });

    test('is null when the file name has no dot', () {
      expect(fileExtension('a.b/c'), isNull);
      expect(fileExtension('noext'), isNull);
    });

    test('is empty for a trailing dot', () {
      expect(fileExtension('x.'), '');
    });
  });

  group('isValidExtension (F-024)', () {
    test('accepts 1-5 lowercase letters or digits', () {
      for (final ext in ['jpg', 'heic', 'jpeg2']) {
        expect(isValidExtension(ext), isTrue, reason: ext);
      }
    });

    test('rejects empty, too long, uppercase and other characters', () {
      for (final ext in ['', 'jpegxl', 'JPG', 'j-g']) {
        expect(isValidExtension(ext), isFalse, reason: ext);
      }
    });
  });

  group('document schema 2', () {
    void expectSamePages(List<ScanPage> actual, List<ScanPage> expected) {
      expect(actual, hasLength(expected.length));
      for (var i = 0; i < expected.length; i++) {
        final a = actual[i];
        final e = expected[i];
        expect(a.id, e.id);
        expect(a.originalPath, e.originalPath);
        expect(a.quad.topLeft, e.quad.topLeft);
        expect(a.quad.topRight, e.quad.topRight);
        expect(a.quad.bottomRight, e.quad.bottomRight);
        expect(a.quad.bottomLeft, e.quad.bottomLeft);
        expect(a.quarterTurns, e.quarterTurns);
        expect(a.revision, e.revision);
      }
    }

    ScanDocument roundTrip(ScanDocument document) {
      final result = decodeDocument(encodeDocument(document));
      expect(result, isA<DecodedDocument>());
      return (result as DecodedDocument).document;
    }

    group('round trip (AC-1)', () {
      final created = DateTime.utc(2026, 10, 12, 9, 0, 0, 123, 456);
      final updated = DateTime.utc(2026, 10, 12, 9, 5);

      test('keeps every field of a document with 3 pages', () {
        final pages = [
          ScanPage(
            id: _idA,
            originalPath: 'originals/$_idA.jpg',
            quad: _skewed,
            quarterTurns: 1,
          ),
          ScanPage(
            id: _idB,
            originalPath: 'originals/$_idB.png',
            quad: _skewed,
            quarterTurns: 2,
            revision: 1,
          ),
          ScanPage(
            id: _idC,
            originalPath: 'originals/$_idC.heic',
            quad: _skewed,
            quarterTurns: 3,
            revision: 7,
          ),
        ];
        final original = ScanDocument(
          id: _docId,
          title: 'Hợp đồng thuê nhà — bản ký',
          createdAt: created,
          updatedAt: updated,
          pages: pages,
        );
        final decoded = roundTrip(original);
        expect(decoded.id, original.id);
        expect(decoded.title, original.title);
        expect(decoded.createdAt, created);
        expect(decoded.createdAt.isUtc, isTrue);
        expect(decoded.updatedAt, updated);
        expect(decoded.updatedAt.isUtc, isTrue);
        expectSamePages(decoded.pages, pages);
      });

      test('keeps a document without pages', () {
        final decoded = roundTrip(
          ScanDocument(
            id: _docId,
            title: 'Trống',
            createdAt: created,
            updatedAt: created,
          ),
        );
        expect(decoded.pages, isEmpty);
        expect(decoded.createdAt, created);
        expect(decoded.updatedAt, created);
      });

      test('encodes the documented schema', () {
        final map = jsonDecode(
          encodeDocument(
            ScanDocument(
              id: _docId,
              title: 'T',
              createdAt: DateTime.utc(2026, 10, 12, 9),
              updatedAt: updated,
              pages: [
                ScanPage(
                  id: _idA,
                  originalPath: 'originals/$_idA.jpg',
                  revision: 2,
                ),
              ],
            ),
          ),
        ) as Map<String, Object?>;
        expect(map, {
          'schemaVersion': documentSchemaVersion,
          'document': {
            'id': _docId,
            'title': 'T',
            'createdAt': '2026-10-12T09:00:00.000Z',
            'updatedAt': '2026-10-12T09:05:00.000Z',
          },
          'pages': [
            {
              'id': _idA,
              'original': 'originals/$_idA.jpg',
              'quad': [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0],
              'quarterTurns': 0,
              'revision': 2,
            },
          ],
        });
      });

      test('encodeManifest still writes no revision', () {
        final map = jsonDecode(
          encodeManifest(
            ScanSession(
              pages: [
                ScanPage(
                  id: _idA,
                  originalPath: 'originals/$_idA.jpg',
                  revision: 3,
                ),
              ],
            ),
          ),
        ) as Map<String, Object?>;
        expect(
          (map['pages']! as List<Object?>).single,
          isNot(contains('revision')),
        );
      });

      test('refuses to encode a page whose original path is invalid', () {
        final bad = ScanDocument(
          id: _docId,
          title: 'T',
          createdAt: created,
          updatedAt: created,
          pages: [ScanPage(id: _idA, originalPath: '/etc/passwd')],
        );
        expect(() => encodeDocument(bad), throwsArgumentError);
        final badId = ScanDocument(
          id: _docId,
          title: 'T',
          createdAt: created,
          updatedAt: created,
          pages: [ScanPage(id: 'p1', originalPath: 'originals/p1.jpg')],
        );
        expect(() => encodeDocument(badId), throwsArgumentError);
      });

      test('refuses to encode a time it could not read back', () {
        final far = DateTime.utc(10000);
        final bad = ScanDocument(
          id: _docId,
          title: 'T',
          createdAt: far,
          updatedAt: far,
        );
        expect(() => encodeDocument(bad), throwsArgumentError);
      });
    });

    test('schema 1 reads as one document with revision 0 (AC-2)', () {
      final json = jsonEncode({
        'schemaVersion': 1,
        'pages': [
          {..._validPage(_idB), 'revision': 5},
          _validPage(_idA),
          _validPage(_idC),
        ],
      });
      final session = decodeManifest(json);
      final time = DateTime.utc(2026, 10, 1, 8);
      final document = ScanDocument(
        id: _docId,
        title: 'Phiên cũ',
        createdAt: time,
        updatedAt: time,
        pages: session.pages,
      );
      expect(document.pages, hasLength(3));
      expect([for (final p in document.pages) p.id], [_idB, _idA, _idC]);
      expect([for (final p in document.pages) p.revision], [0, 0, 0]);
      expect(document.id, _docId);
      expect(document.title, 'Phiên cũ');
      expect(document.createdAt, time);
    });

    test('decodes the documented example', () {
      final result = decodeDocument(jsonEncode(_validDocument()));
      final document = (result as DecodedDocument).document;
      expect(document.id, _docId);
      expect(document.title, 'Hợp đồng');
      expect(document.createdAt, DateTime.utc(2026, 10, 12, 9));
      expect(document.updatedAt, DateTime.utc(2026, 10, 12, 9, 5, 0, 123, 456));
      expect(document.pages.single.revision, 2);
    });

    group('newer schema (FR-7)', () {
      test('schemaVersion 3 needs an app update', () {
        expect(
          decodeDocument(jsonEncode({..._validDocument(), 'schemaVersion': 3})),
          isA<DocumentNeedsAppUpdate>(),
        );
      });

      test('schemaVersion 3 is not validated further', () {
        expect(
          decodeDocument('{"schemaVersion":3,"pages":"not a list"}'),
          isA<DocumentNeedsAppUpdate>(),
        );
      });
    });

    group('decode rejects (AC-3)', () {
      const secret = 'SECRET-TITLE';
      // (input, field, user value that must not appear in the message)
      final cases = <String, (Object, String, String?)>{
        'unparsable JSON': ('{"SECRET-KEY": ', 'JSON', 'SECRET-KEY'),
        'root that is a list': ('[]', 'root', null),
        'schemaVersion 1': (
          {..._validDocument(), 'schemaVersion': 1},
          'schemaVersion',
          null,
        ),
        'schemaVersion "2"': (
          {..._validDocument(), 'schemaVersion': '2'},
          'schemaVersion',
          null,
        ),
        'schemaVersion 2.0': (
          {..._validDocument(), 'schemaVersion': 2.0},
          'schemaVersion',
          null,
        ),
        'missing schemaVersion': (
          {..._validDocument()}..remove('schemaVersion'),
          'schemaVersion',
          null,
        ),
        'missing document': (
          {..._validDocument()}..remove('document'),
          'document',
          null,
        ),
        'document not an object': (
          {..._validDocument(), 'document': 'SECRET-DOC'},
          'document',
          'SECRET-DOC',
        ),
        'document.id too short': (
          _documentWith('id', 'abc123'),
          'document.id',
          'abc123',
        ),
        'document.id uppercase': (
          _documentWith('id', _docId.toUpperCase()),
          'document.id',
          _docId.toUpperCase(),
        ),
        'empty title': (_documentWith('title', ''), 'document.title', null),
        'blank title': (_documentWith('title', '   '), 'document.title', null),
        'title of 121 code points': (
          _documentWith('title', '$secret${'x' * 109}'),
          'document.title',
          secret,
        ),
        'title with U+0007': (
          _documentWith('title', '$secret\u0007x'),
          'document.title',
          secret,
        ),
        'title not a string': (
          _documentWith('title', 7),
          'document.title',
          null,
        ),
        'missing title': (_documentWithout('title'), 'document.title', null),
        'createdAt without Z': (
          _documentWith('createdAt', '2026-10-12T09:00:00'),
          'document.createdAt',
          '2026-10-12T09',
        ),
        'createdAt with an offset': (
          _documentWith('createdAt', '2026-10-12T09:00:00+07:00'),
          'document.createdAt',
          '2026-10-12T09',
        ),
        'createdAt not a date': (
          _documentWith('createdAt', 'SECRET-DATE'),
          'document.createdAt',
          'SECRET-DATE',
        ),
        'createdAt on a day that does not exist': (
          _documentWith('createdAt', '2026-02-30T00:00:00Z'),
          'document.createdAt',
          '2026-02-30',
        ),
        'createdAt not a string': (
          _documentWith('createdAt', 1),
          'document.createdAt',
          null,
        ),
        'updatedAt without Z': (
          _documentWith('updatedAt', '2026-10-12T09:05:00'),
          'document.updatedAt',
          '2026-10-12T09',
        ),
        'updatedAt before createdAt': (
          _documentWith('updatedAt', '2026-10-12T08:59:59.999999Z'),
          'document.updatedAt',
          '2026-10-12T08',
        ),
        'pages not a list': (
          {..._validDocument(), 'pages': 'x'},
          'pages',
          null,
        ),
        'bad page original': (
          _documentPageWith('original', 'originals/../SECRET-PATH.jpg'),
          'pages[0].original',
          'SECRET-PATH',
        ),
        'revision -1': (
          _documentPageWith('revision', -1),
          'pages[0].revision',
          null,
        ),
        'revision 1.5': (
          _documentPageWith('revision', 1.5),
          'pages[0].revision',
          null,
        ),
        'revision "1"': (
          _documentPageWith('revision', '1'),
          'pages[0].revision',
          null,
        ),
        'missing revision': (
          {
            ..._validDocument(),
            'pages': [_validPage()],
          },
          'pages[0].revision',
          null,
        ),
        'duplicate page id': (
          {
            ..._validDocument(),
            'pages': [
              {..._validPage(), 'revision': 0},
              {..._validPage(), 'revision': 1},
            ],
          },
          'pages[1].id',
          null,
        ),
      };

      for (final MapEntry(key: name, value: (input, field, hidden))
          in cases.entries) {
        test(name, () {
          final json = input is String ? input : jsonEncode(input);
          try {
            decodeDocument(json);
            fail('expected FormatException');
          } on FormatException catch (e) {
            expect(e.message, contains(field));
            expect(e.source, isNull);
            if (hidden != null) {
              expect(e.toString(), isNot(contains(hidden)));
            }
          }
        });
      }
    });
  });
}
