import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/imaging/isolate_budget.dart';
import 'package:x_scanner/imaging/page_render.dart';

Uint8List _u32(int value) =>
    (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

Uint8List _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  var crc = 0xffffffff;
  for (final byte in body) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320 : 0);
    }
  }
  return Uint8List.fromList([
    ..._u32(data.length),
    ...body,
    ..._u32(crc ^ 0xffffffff),
  ]);
}

Uint8List _png(List<int> compressed, {int width = 1, int height = 1}) =>
    Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      ..._chunk('IHDR', [..._u32(width), ..._u32(height), 8, 0, 0, 0, 0]),
      ..._chunk('IDAT', compressed),
      ..._chunk('IEND', []),
    ]);

Uint8List _jpegWithCyclicExif(Uint8List jpeg) {
  // Two empty IFDs point to each other. Only metadata changes; raster is valid.
  const tiff = [
    0x49,
    0x49,
    42,
    0,
    8,
    0,
    0,
    0,
    0,
    0,
    14,
    0,
    0,
    0,
    0,
    0,
    8,
    0,
    0,
    0,
  ];
  const exif = [69, 120, 105, 102, 0, 0, ...tiff];
  final length = exif.length + 2;
  return Uint8List.fromList([
    ...jpeg.take(2),
    0xff,
    0xe1,
    length >> 8,
    length & 255,
    ...exif,
    ...jpeg.skip(2),
  ]);
}

Map<String, Uint8List> _formats() {
  final image = img.Image(width: 3, height: 2)
    ..clear(img.ColorRgb8(10, 20, 30));
  return {
    'JPEG': img.encodeJpg(image),
    'PNG': img.encodePng(image),
    'WebP': base64Decode(
      'UklGRh4AAABXRUJQVlA4TBEAAAAvAkAAAAdQiirUo/+BiOh/AAA=',
    ),
  };
}

void main() {
  group('W-104b decoder regressions', () {
    test(
      'cyclic EXIF stops reading metadata and preserves the JPEG raster',
      () async {
        final plain = img.encodeJpg(
          img.Image(width: 3, height: 2)..clear(img.ColorRgb8(17, 17, 17)),
        );
        final expected = img.decodeJpg(plain)!;
        final original = _jpegWithCyclicExif(plain);
        final before = Uint8List.fromList(original);
        // A kill budget bounds the old decoder loop; this is not a latency target.
        final result = await runWithinBudget(() {
          final image = decodeOriented(original);
          return (image.width, image.height, image.toUint8List());
        }, const Duration(milliseconds: 500));
        expect((result.$1, result.$2), (3, 2));
        expect(result.$3, expected.toUint8List());
        expect(original, before);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test('PNG reads declared rows without consuming a malformed unused tail', () {
      // Finite ~64KiB consumption canary, not a valid PNG or a RAM benchmark.
      // The stored block's first row is complete. The reserved block is beyond
      // the native inflater's first compressed chunk; eager inflation hits it.
      final row = Uint8List(65535)..[1] = 17;
      final original = _png([0x78, 0x01, 0, 255, 255, 0, 0, ...row, 7]);
      final before = Uint8List.fromList(original);
      final decoded = decodeOriented(original);
      expect((decoded.width, decoded.height), (1, 1));
      expect(decoded.getPixel(0, 0).r, 17);
      expect(original, before);
    });

    test(
      'PNG complete zlib stream with finite surplus keeps declared raster',
      () {
        final rows = Uint8List(4096)..[1] = 17;
        final original = _png(ZLibEncoder().convert(rows));
        final before = Uint8List.fromList(original);
        final decoded = decodeOriented(original);
        expect((decoded.width, decoded.height), (1, 1));
        expect(decoded.getPixel(0, 0).r, 17);
        expect(original, before);
      },
    );

    test('PNG without a complete row reports only the sanitized failure', () {
      final bytes = _png(ZLibEncoder().convert([0]));
      expect(() => decodeOriented(bytes), throwsA(isA<ImageDecodeFailure>()));
    });

    test(
      'oversized header is nullable for UI without allocating its pixels',
      () {
        final bytes = _png(
          ZLibEncoder().convert([0, 17]),
          width: 8000,
          height: 8000,
        );
        expect(imageSizeOf(bytes), isNull);
        expect(() => decodeOriented(bytes), throwsA(isA<ImageDecodeFailure>()));
      },
    );
  });
  group('W-104b explicit instance limits', () {
    for (final entry in _formats().entries) {
      test('${entry.key} caller cap overrides a smaller library default', () {
        final previous = img.Decoder.defaultMaxPixels;
        final original = Uint8List.fromList(entry.value);
        img.Decoder.defaultMaxPixels = 1;
        try {
          final image = decodeOriented(entry.value, maxPixels: 6);
          expect((image.width, image.height), (3, 2));
          expect(img.Decoder.defaultMaxPixels, 1);
          expect(entry.value, original);
        } finally {
          img.Decoder.defaultMaxPixels = previous;
        }
      });
    }

    test('header reader uses app cap without changing the library default', () {
      final previous = img.Decoder.defaultMaxPixels;
      img.Decoder.defaultMaxPixels = 1;
      try {
        for (final bytes in _formats().values) {
          expect(imageSizeOf(bytes), (width: 3, height: 2));
        }
        expect(img.Decoder.defaultMaxPixels, 1);
      } finally {
        img.Decoder.defaultMaxPixels = previous;
      }
    });

    test('all formats accept exact cap and reject one pixel over it', () {
      for (final bytes in _formats().values) {
        final image = decodeOriented(bytes, maxPixels: 6);
        expect(image.width * image.height, 6);
        expect(
          () => decodeOriented(bytes, maxPixels: 5),
          throwsA(isA<ImageDecodeFailure>()),
        );
      }
    });

    test('nonpositive app limits never disable upstream protection', () {
      for (final bytes in _formats().values) {
        for (final cap in [0, -1]) {
          expect(
            () => decodeOriented(bytes, maxPixels: cap),
            throwsA(isA<ImageDecodeFailure>()),
          );
        }
      }
      expect(const ImageDecodeFailure().toString(), 'ImageDecodeFailure');
    });
  });
}
