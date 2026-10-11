import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';

ScanPage _page(String id) =>
    ScanPage(id: id, originalPath: 'originals/$id.jpg');

List<String> _ids(ScanSession session) =>
    session.pages.map((p) => p.id).toList();

final ScanSession _abc = ScanSession(
  pages: [_page('a'), _page('b'), _page('c')],
);

void main() {
  group('constructor', () {
    test('empty session has no pages', () {
      expect(ScanSession.empty.pages, isEmpty);
      expect(ScanSession().pages, isEmpty);
    });

    test('rejects duplicate ids', () {
      expect(
        () => ScanSession(pages: [_page('a'), _page('a')]),
        throwsArgumentError,
      );
    });

    test('pages cannot be modified', () {
      expect(() => _abc.pages.add(_page('d')), throwsUnsupportedError);
      expect(
        () => ScanSession.empty.pages.add(_page('d')),
        throwsUnsupportedError,
      );
    });

    test('later changes to the input list do not leak in', () {
      final input = [_page('a')];
      final session = ScanSession(pages: input);
      input.add(_page('b'));
      expect(_ids(session), ['a']);
    });
  });

  group('added', () {
    test('appends and leaves the old session unchanged', () {
      final next = _abc.added(_page('d'));
      expect(_ids(next), ['a', 'b', 'c', 'd']);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('rejects a duplicate id', () {
      expect(() => _abc.added(_page('b')), throwsArgumentError);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });
  });

  group('removed', () {
    test('removes and leaves the old session unchanged', () {
      final next = _abc.removed('b');
      expect(_ids(next), ['a', 'c']);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('rejects an unknown id', () {
      expect(() => _abc.removed('x'), throwsArgumentError);
      expect(() => ScanSession.empty.removed('a'), throwsArgumentError);
    });

    test('can remove the last page', () {
      expect(ScanSession(pages: [_page('a')]).removed('a').pages, isEmpty);
    });
  });

  group('moved', () {
    test('takes out at from and inserts at to in the remaining list', () {
      expect(_ids(_abc.moved(2, 0)), ['c', 'a', 'b']);
      expect(_ids(_abc.moved(0, 2)), ['b', 'c', 'a']);
      expect(_ids(_abc.moved(0, 1)), ['b', 'a', 'c']);
      expect(_ids(_abc.moved(1, 1)), ['a', 'b', 'c']);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('moved(2, 0) then removing the new second page', () {
      final moved = _abc.moved(2, 0);
      final secondId = moved.pages[1].id;
      final next = moved.removed(secondId);
      expect(secondId, 'a');
      expect(_ids(next), ['c', 'b']);
      expect(_ids(moved), ['c', 'a', 'b']);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('rejects negative and out-of-range indices', () {
      expect(() => _abc.moved(-1, 0), throwsRangeError);
      expect(() => _abc.moved(3, 0), throwsRangeError);
      expect(() => _abc.moved(0, -1), throwsRangeError);
      expect(() => _abc.moved(0, 3), throwsRangeError);
      expect(() => ScanSession.empty.moved(0, 0), throwsRangeError);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });
  });

  group('replaced', () {
    test('edits a page in place when the id is kept', () {
      final rotated = _abc.pages[1].rotatedClockwise();
      final next = _abc.replaced('b', rotated);
      expect(_ids(next), ['a', 'b', 'c']);
      expect(next.pages[1].quarterTurns, 1);
      expect(_abc.pages[1].quarterTurns, 0);
    });

    test('retake swaps in a new id at the same position', () {
      final next = _abc.replaced('b', _page('z'));
      expect(_ids(next), ['a', 'z', 'c']);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('rejects an unknown id', () {
      expect(() => _abc.replaced('x', _page('x')), throwsArgumentError);
    });

    test('rejects a new id that collides with another page', () {
      expect(() => _abc.replaced('b', _page('c')), throwsArgumentError);
      expect(_ids(_abc), ['a', 'b', 'c']);
    });

    test('keeps the quad of the replacement page', () {
      final quad = PageQuad(
        topLeft: const Point<double>(0.1, 0.1),
        topRight: const Point<double>(0.9, 0.1),
        bottomRight: const Point<double>(0.9, 0.9),
        bottomLeft: const Point<double>(0.1, 0.9),
      );
      final next = _abc.replaced('a', _abc.pages[0].withQuad(quad));
      expect(next.pages[0].quad, quad);
      expect(_abc.pages[0].quad, PageQuad.fullFrame);
    });
  });

  group('newPageId', () {
    final pattern = RegExp(r'^[0-9a-f]{32}$');

    test('matches the id pattern with a seeded random', () {
      expect(newPageId(Random(1)), matches(pattern));
    });

    test('default source matches the pattern and differs between calls', () {
      final a = newPageId();
      final b = newPageId();
      expect(a, matches(pattern));
      expect(b, matches(pattern));
      expect(a, isNot(b));
    });
  });
}
