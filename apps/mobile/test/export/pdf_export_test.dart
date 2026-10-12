import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:x_scanner/export/pdf_export.dart';

/// A synthetic JPEG of [width] × [height].
Uint8List jpeg(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 120, 40));
  return img.encodeJpg(image);
}

/// The `[x0 y0 x1 y1]` of every `/MediaBox` in [pdf], in file order.
List<List<double>> mediaBoxes(String pdf) => [
  for (final m in RegExp(
    r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\]',
  ).allMatches(pdf))
    [for (var g = 1; g <= 4; g++) double.parse(m.group(g)!)],
];

void main() {
  group('pageFormatFor', () {
    test('portrait image maps its long side to 842 pt', () {
      final f = pageFormatFor(3000, 4000);
      expect(f.width, closeTo(631.5, 1e-9));
      expect(f.height, closeTo(842, 1e-9));
      expect(f.marginLeft, 0);
      expect(f.marginTop, 0);
    });

    test('landscape image keeps its orientation', () {
      final f = pageFormatFor(4000, 3000);
      expect(f.width, closeTo(842, 1e-9));
      expect(f.height, closeTo(631.5, 1e-9));
    });

    test('square image gives a square page', () {
      final f = pageFormatFor(1, 1);
      expect(f.width, closeTo(842, 1e-9));
      expect(f.height, closeTo(842, 1e-9));
    });

    test('non-positive sizes are rejected', () {
      expect(() => pageFormatFor(0, 10), throwsArgumentError);
      expect(() => pageFormatFor(10, 0), throwsArgumentError);
      expect(() => pageFormatFor(-1, 10), throwsArgumentError);
    });
  });

  group('buildPdf', () {
    test('3 pages keep their aspect and orientation (AC-6)', () async {
      final bytes = await buildPdf([
        jpeg(300, 400),
        jpeg(400, 300),
        jpeg(200, 200),
      ], compress: false);
      final pdf = latin1.decode(bytes);

      expect(pdf.startsWith('%PDF-'), isTrue);
      expect(
        RegExp(r'/Type\s*/Page(?![a-zA-Z])').allMatches(pdf),
        hasLength(3),
      );

      final boxes = mediaBoxes(pdf);
      expect(boxes, hasLength(3));
      final sizes = [for (final b in boxes) (w: b[2] - b[0], h: b[3] - b[1])];
      expect(sizes[0].w, closeTo(631.5, 0.01));
      expect(sizes[0].h, closeTo(842, 0.01));
      expect(sizes[1].w, closeTo(842, 0.01));
      expect(sizes[1].h, closeTo(631.5, 0.01));
      expect(sizes[2].w, closeTo(842, 0.01));
      expect(sizes[2].h, closeTo(842, 0.01));
    });

    test('a PNG page is accepted', () async {
      final png = img.encodePng(img.Image(width: 10, height: 20));
      final pdf = latin1.decode(await buildPdf([png], compress: false));
      expect(
        RegExp(r'/Type\s*/Page(?![a-zA-Z])').allMatches(pdf),
        hasLength(1),
      );
    });

    test('compressed output is a PDF too', () async {
      final bytes = await buildPdf([jpeg(30, 40)]);
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('an empty list is rejected', () async {
      await expectLater(buildPdf([]), throwsArgumentError);
    });

    test('an unreadable image fails with PdfException', () async {
      await expectLater(
        buildPdf([Uint8List.fromList(List<int>.filled(16, 7))]),
        throwsA(isA<PdfException>()),
      );
    });
  });
}
