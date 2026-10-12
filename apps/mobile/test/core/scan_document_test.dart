import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';

const String _docId = '0123456789abcdef0123456789abcdef';
const String _idA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _idB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

final DateTime _created = DateTime.utc(2026, 10, 12, 9);
final DateTime _updated = DateTime.utc(2026, 10, 12, 9, 5);

ScanPage _page(String id) =>
    ScanPage(id: id, originalPath: 'originals/$id.jpg');

ScanDocument _document({
  String id = _docId,
  String title = 'Hợp đồng',
  DateTime? createdAt,
  DateTime? updatedAt,
  List<ScanPage> pages = const [],
}) => ScanDocument(
  id: id,
  title: title,
  createdAt: createdAt ?? _created,
  updatedAt: updatedAt ?? _updated,
  pages: pages,
);

void main() {
  group('valid documents', () {
    test('keep every field and the page order', () {
      final pages = [_page(_idB), _page(_idA)];
      final doc = _document(pages: pages);
      expect(doc.id, _docId);
      expect(doc.title, 'Hợp đồng');
      expect(doc.createdAt, _created);
      expect(doc.updatedAt, _updated);
      expect([for (final p in doc.pages) p.id], [_idB, _idA]);
    });

    test('pages cannot be modified, also through the input list', () {
      final pages = [_page(_idA)];
      final doc = _document(pages: pages);
      pages.add(_page(_idB));
      expect(doc.pages, hasLength(1));
      expect(() => doc.pages.add(_page(_idB)), throwsUnsupportedError);
    });

    test('accept a 1 code point title', () {
      expect(_document(title: 'A').title, 'A');
      expect(isValidDocumentTitle('😀'), isTrue);
    });

    test('accept 120 code points with emoji and Vietnamese marks', () {
      // 😀 is two UTF-16 units but one code point.
      final title = '😀' * 60 + 'ệ' * 60;
      expect(title.runes, hasLength(120));
      expect(title.length, greaterThan(120));
      expect(_document(title: title).title, title);
    });

    test('accept updatedAt equal to createdAt', () {
      final doc = _document(updatedAt: _created);
      expect(doc.updatedAt, doc.createdAt);
    });
  });

  group('rejects', () {
    final idCases = {
      '31 hex characters': _docId.substring(1),
      'uppercase hex': _docId.toUpperCase(),
    };
    for (final MapEntry(key: name, value: id) in idCases.entries) {
      test('id with $name', () {
        expect(() => _document(id: id), throwsArgumentError);
      });
    }

    final titleCases = {
      'empty': '',
      'only spaces': '   ',
      'a leading space': ' a',
      'a trailing space': 'a ',
      '121 code points': '😀' * 121,
      'U+0000': 'a\u0000b',
      'a tab': 'a\tb',
      'U+001F': 'a\u001fb',
      'U+007F': 'a\u007fb',
    };
    for (final MapEntry(key: name, value: title) in titleCases.entries) {
      test('title with $name', () {
        expect(isValidDocumentTitle(title), isFalse);
        expect(() => _document(title: title), throwsArgumentError);
      });
    }

    test('createdAt that is not UTC', () {
      expect(
        () => _document(createdAt: DateTime(2026, 10, 12, 9)),
        throwsArgumentError,
      );
    });

    test('updatedAt that is not UTC', () {
      expect(
        () => _document(updatedAt: DateTime(2026, 10, 12, 10)),
        throwsArgumentError,
      );
    });

    test('updatedAt before createdAt', () {
      expect(
        () => _document(
          updatedAt: _created.subtract(const Duration(microseconds: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('a duplicate page id', () {
      expect(
        () => _document(pages: [_page(_idA), _page(_idA)]),
        throwsArgumentError,
      );
    });

    test('a bad title without echoing it in the error', () {
      final title = 'SECRET-TITLE ' * 10;
      try {
        _document(title: title);
        fail('expected ArgumentError');
      } on ArgumentError catch (e) {
        expect(e.toString(), isNot(contains('SECRET-TITLE')));
        expect(e.invalidValue, isNull);
      }
    });
  });

  group('defaultDocumentTitle', () {
    test('formats the fields of the given time with leading zeros', () {
      expect(
        defaultDocumentTitle(DateTime(2026, 10, 12, 9, 5)),
        'Tài liệu 12/10/2026 09:05',
      );
      expect(
        defaultDocumentTitle(DateTime(2026, 1, 2, 0, 0)),
        'Tài liệu 02/01/2026 00:00',
      );
    });

    test('does not convert a UTC time to local time', () {
      expect(
        defaultDocumentTitle(DateTime.utc(2026, 12, 31, 23, 59)),
        'Tài liệu 31/12/2026 23:59',
      );
    });

    test('pads a short year to four digits', () {
      expect(
        defaultDocumentTitle(DateTime.utc(987, 3, 4, 5, 6)),
        'Tài liệu 04/03/0987 05:06',
      );
    });

    test('is always a valid document title', () {
      for (final time in [
        DateTime(2026, 10, 12, 9, 5),
        DateTime.utc(2026, 12, 31, 23, 59),
        DateTime.utc(1, 1, 1),
        DateTime.utc(9999, 12, 31, 23, 59),
      ]) {
        expect(isValidDocumentTitle(defaultDocumentTitle(time)), isTrue);
      }
    });
  });
}
