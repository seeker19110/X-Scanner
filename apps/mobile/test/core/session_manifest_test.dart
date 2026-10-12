import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';

const String _idA = '0123456789abcdef0123456789abcdef';
const String _idB = 'fedcba9876543210fedcba9876543210';

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
}
