import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/imaging/page_render.dart';

/// Builds a quad from eight numbers: TL, TR, BR, BL as (x, y) pairs.
PageQuad quadOf(List<double> c) => PageQuad(
  topLeft: Point<double>(c[0], c[1]),
  topRight: Point<double>(c[2], c[3]),
  bottomRight: Point<double>(c[4], c[5]),
  bottomLeft: Point<double>(c[6], c[7]),
);

/// The AC-5 perspective quad.
PageQuad ac5Quad() => quadOf([0.1, 0.1, 0.9, 0.2, 0.8, 0.9, 0.2, 0.8]);

/// AC-5 size on a 400×300 image, computed by hand from the pixel corners
/// TL(40,30) TR(360,60) BR(320,270) BL(80,240):
/// width = max(√(320²+30²), √(240²+30²)) = max(321.40, 241.87) → 321;
/// height = max(√(40²+210²), √(40²+210²)) = 213.78 → 214.
const int ac5Width = 321;
const int ac5Height = 214;

/// A synthetic uint8 RGB image filled with one colour.
img.Image solid(int width, int height, int r, int g, int b) =>
    img.Image(width: width, height: height)..clear(img.ColorRgb8(r, g, b));

Uint8List pngOf(img.Image image) => img.encodePng(image);

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('page_render_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

void expectRgb(img.Image image, int x, int y, List<int> rgb) {
  final p = image.getPixel(x, y);
  expect([p.r, p.g, p.b], rgb, reason: 'pixel ($x, $y)');
}

void main() {
  group('rectifiedSize', () {
    test('uses the longer opposite edges in pixels (AC-5)', () {
      final size = rectifiedSize(ac5Quad(), 400, 300);
      expect(size.width, ac5Width);
      expect(size.height, ac5Height);
    });

    test('full frame keeps the image size', () {
      final size = rectifiedSize(PageQuad.fullFrame, 400, 300);
      expect((size.width, size.height), (400, 300));
    });

    test('never returns a dimension below one pixel', () {
      final tiny = quadOf([0.1, 0.1, 0.2, 0.1, 0.2, 0.2, 0.1, 0.2]);
      final size = rectifiedSize(tiny, 1, 1);
      expect((size.width, size.height), (1, 1));
    });
  });

  group('decodeOriented', () {
    test('applies EXIF orientation 6 (swaps dimensions)', () {
      final image = solid(40, 20, 10, 20, 30);
      image.exif.imageIfd.orientation = 6;
      final decoded = decodeOriented(img.encodeJpg(image));
      expect((decoded.width, decoded.height), (20, 40));
    });

    test('decodes a PNG without orientation unchanged', () {
      final decoded = decodeOriented(pngOf(solid(40, 20, 1, 2, 3)));
      expect((decoded.width, decoded.height), (40, 20));
    });

    test('rejects garbage bytes', () {
      expect(
        () => decodeOriented(Uint8List.fromList(List.filled(64, 7))),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('rejects empty bytes', () {
      expect(
        () => decodeOriented(Uint8List(0)),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('maps library errors on truncated data to the failure', () {
      final png = pngOf(solid(64, 64, 200, 100, 50));
      final truncated = Uint8List.sublistView(png, 0, png.length ~/ 2);
      expect(
        () => decodeOriented(truncated),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('rejects images above the pixel ceiling', () {
      expect(
        () => decodeOriented(pngOf(solid(20, 20, 0, 0, 0)), maxPixels: 100),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('accepts an image exactly at the pixel ceiling', () {
      final decoded = decodeOriented(
        pngOf(solid(20, 20, 0, 0, 0)),
        maxPixels: 400,
      );
      expect(decoded.width * decoded.height, 400);
    });

    test('failure carries no path or content', () {
      expect(const ImageDecodeFailure().toString(), 'ImageDecodeFailure');
    });
  });

  group('rectify', () {
    test('produces the rectified size and leaves the source untouched', () {
      final source = solid(400, 300, 9, 8, 7);
      final before = Uint8List.fromList(source.toUint8List());
      final out = rectify(source, ac5Quad());
      expect((out.width, out.height), (ac5Width, ac5Height));
      expect(source.toUint8List(), before);
    });

    test('does not darken samples next to the image border', () {
      // The left edge lies on x = 0; perspective pulls some sample centres
      // within half a pixel of it, where an unclamped bilinear lookup would
      // blend in out-of-range (black) pixels.
      final source = solid(100, 100, 255, 255, 255);
      final quad = quadOf([0, 0.1, 1, 0, 1, 1, 0, 0.9]);
      final out = rectify(source, quad);
      for (final p in out) {
        expect([p.r, p.g, p.b], [255, 255, 255], reason: '(${p.x}, ${p.y})');
      }
    });

    test('normalises 16-bit sources to 8-bit output', () {
      // Image.clear is a no-op for uint16 data in image 4.10.1, so the
      // pixels are set one by one.
      final source = img.Image(width: 8, height: 8, format: img.Format.uint16);
      for (final p in source) {
        p.setRgb(32768, 32768, 32768);
      }
      expect(source.getPixel(4, 4).r, 32768);
      final out = rectify(source, PageQuad.fullFrame);
      expect(out.format, img.Format.uint8);
      expect(out.getPixel(4, 4).r, closeTo(128, 1));
    });

    test('expands palette sources to their colours', () {
      final source = img.Image(
        width: 8,
        height: 8,
        numChannels: 3,
        withPalette: true,
      );
      source.palette!.setRgb(0, 255, 0, 0);
      source.clear(img.ColorRgb8(0, 0, 0));
      final out = rectify(source, PageQuad.fullFrame);
      expectRgb(out, 4, 4, [255, 0, 0]);
    });
  });

  group('renderPageSync', () {
    test('re-decodes to the rectified size (AC-5)', () {
      final out = renderPageSync(
        pngOf(solid(400, 300, 50, 60, 70)),
        ac5Quad(),
        0,
      );
      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (ac5Width, ac5Height));
    });

    test('one quarter turn swaps width and height', () {
      final out = renderPageSync(
        pngOf(solid(400, 300, 50, 60, 70)),
        ac5Quad(),
        1,
      );
      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (ac5Height, ac5Width));
    });

    test('full frame keeps the colours of both halves (PNG)', () {
      final source = solid(40, 20, 255, 0, 0);
      img.fillRect(
        source,
        x1: 20,
        y1: 0,
        x2: 39,
        y2: 19,
        color: img.ColorRgb8(0, 0, 255),
      );
      final out = renderPageSync(
        pngOf(source),
        PageQuad.fullFrame,
        0,
        format: RenderFormat.png,
      );
      final decoded = img.decodePng(out)!;
      expect((decoded.width, decoded.height), (40, 20));
      expectRgb(decoded, 10, 10, [255, 0, 0]);
      expectRgb(decoded, 30, 10, [0, 0, 255]);
    });

    test('propagates decode failures', () {
      expect(
        () => renderPageSync(Uint8List(3), PageQuad.fullFrame, 0),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });
  });

  group('thumbnailSync', () {
    test('scales the long side down to maxSide', () {
      final out = thumbnailSync(
        pngOf(solid(3000, 1000, 1, 2, 3)),
        maxSide: 300,
      );
      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (300, 100));
    });

    test('scales portrait images by their height', () {
      final out = thumbnailSync(pngOf(solid(100, 300, 1, 2, 3)), maxSide: 30);
      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (10, 30));
    });

    test('keeps images that already fit', () {
      final out = thumbnailSync(pngOf(solid(200, 100, 1, 2, 3)), maxSide: 300);
      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (200, 100));
    });
  });

  group('isolate entry points', () {
    test(
      'renderPage renders from a file and keeps the original intact',
      () async {
        final file = File('${tempDir().path}/original.png');
        final original = pngOf(solid(400, 300, 50, 60, 70));
        file.writeAsBytesSync(original);

        final out = await renderPage(file.path, ac5Quad(), 0);

        final decoded = img.decodeJpg(out)!;
        expect((decoded.width, decoded.height), (ac5Width, ac5Height));
        expect(file.readAsBytesSync(), original);
      },
    );

    test('renderPage reports undecodable files as the failure', () async {
      final file = File('${tempDir().path}/broken.bin')
        ..writeAsBytesSync(List.filled(32, 1));
      await expectLater(
        renderPage(file.path, PageQuad.fullFrame, 0),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('thumbnail renders from a file', () async {
      final file = File('${tempDir().path}/original.png')
        ..writeAsBytesSync(pngOf(solid(3000, 1000, 1, 2, 3)));

      final out = await thumbnail(file.path, maxSide: 300);

      final decoded = img.decodeJpg(out)!;
      expect((decoded.width, decoded.height), (300, 100));
    });
  });
}
