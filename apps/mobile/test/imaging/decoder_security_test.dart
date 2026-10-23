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
  group('scaled JPEG thumbnail protection', () {
    final original = img.encodeJpg(
      img.Image(width: 65, height: 33)..clear(img.ColorRgb8(30, 90, 150)),
    );

    test('the original header cap holds even when the raster would fit', () {
      for (final cap in [0, -1, 65 * 33 - 1]) {
        expect(
          () => decodeOriented(original, maxPixels: cap, jpegScale: 8),
          throwsA(isA<ImageDecodeFailure>()),
        );
        expect(
          () => thumbnailSync(original, maxSide: 9, maxPixels: cap),
          throwsA(isA<ImageDecodeFailure>()),
        );
      }
      final reduced = decodeOriented(
        original,
        maxPixels: 65 * 33,
        jpegScale: 8,
      );
      expect((reduced.width, reduced.height), (9, 5));
    });

    test('an oversized JPEG header is refused before reduced decoding', () {
      final bytes = Uint8List.fromList(original);
      var patched = false;
      for (var i = 0; i + 8 < bytes.length; i++) {
        if (bytes[i] == 0xff && bytes[i + 1] == 0xc0) {
          bytes[i + 5] = bytes[i + 7] = 8000 >> 8;
          bytes[i + 6] = bytes[i + 8] = 8000 & 255;
          patched = true;
          break;
        }
      }
      expect(patched, isTrue, reason: 'fixture has a baseline SOF header');
      expect(imageSizeOf(bytes), isNull);
      expect(
        () => thumbnailSync(bytes, maxSide: 8),
        throwsA(isA<ImageDecodeFailure>()),
      );
    });

    test('invalid scale and malformed JPEG errors are sanitized', () {
      for (final scale in [-1, 0, 3, 16]) {
        expect(
          () => decodeOriented(original, jpegScale: scale),
          throwsA(isA<ImageDecodeFailure>()),
        );
      }
      for (final bytes in [
        Uint8List.fromList([0xff, 0xd8, 0xff]),
        Uint8List.sublistView(original, 0, original.length ~/ 2),
      ]) {
        expect(
          () => thumbnailSync(bytes, maxSide: 8),
          throwsA(isA<ImageDecodeFailure>()),
        );
      }
    });

    test('malformed EXIF offsets keep the reduced JPEG raster readable', () {
      final bytes = _jpegWithCyclicExif(original);
      // TIFF's first-IFD offset is outside the bounded APP1 metadata block.
      bytes.setRange(16, 20, [0xff, 0xff, 0xff, 0x7f]);
      final before = Uint8List.fromList(bytes);
      final result = img.decodeJpg(thumbnailSync(bytes, maxSide: 9))!;
      expect((result.width, result.height), (9, 5));
      final p = result.getPixel(4, 2);
      expect(p.r, closeTo(30, 5));
      expect(p.g, closeTo(90, 5));
      expect(p.b, closeTo(150, 5));
      expect(bytes, before);
    });

    test('a progressive JPEG thumbnail keeps its target and color', () {
      // Synthetic 65×33 solid RGB (30,90,150), Pillow quality90/progressive.
      final bytes = base64Decode(
        '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoH'
        'BwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQME'
        'BAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU'
        'FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wgARCAAhAEEDASIAAhEBAxEB/8QAFQAB'
        'AQAAAAAAAAAAAAAAAAAAAAf/xAAVAQEBAAAAAAAAAAAAAAAAAAAABv/aAAwDAQACEAMQ'
        'AAABnotZAAAAAAAAAAAAAAD/xAAUEAEAAAAAAAAAAAAAAAAAAABQ/9oACAEBAAEFAjf/'
        'xAAUEQEAAAAAAAAAAAAAAAAAAAAw/9oACAEDAQE/AX//xAAUEQEAAAAAAAAAAAAAAAAA'
        'AAAw/9oACAECAQE/AX//xAAUEAEAAAAAAAAAAAAAAAAAAABQ/9oACAEBAAY/Ajf/xAAU'
        'EAEAAAAAAAAAAAAAAAAAAABQ/9oACAEBAAE/ITf/2gAMAwEAAgADAAAAEP8A/wD/AP8A'
        '/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP/EABQRAQAAAAAAAAAAAAAAAAAAADD/2gAIAQMB'
        'AT8Qf//EABQRAQAAAAAAAAAAAAAAAAAAADD/2gAIAQIBAT8Qf//EABQQAQAAAAAAAAAA'
        'AAAAAAAAAFD/2gAIAQEAAT8QN//Z',
      );
      final before = Uint8List.fromList(bytes);
      final result = img.decodeJpg(thumbnailSync(bytes, maxSide: 9))!;
      expect((result.width, result.height), (9, 5));
      final p = result.getPixel(4, 2);
      expect(p.r, closeTo(30, 5));
      expect(p.g, closeTo(90, 5));
      expect(p.b, closeTo(150, 5));
      expect(bytes, before);
    });
  });

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
          final thumb = thumbnailSync(original, maxSide: 2);
          return (image.width, image.height, image.toUint8List(), thumb);
        }, const Duration(milliseconds: 500));
        expect((result.$1, result.$2), (3, 2));
        expect(result.$3, expected.toUint8List());
        final thumb = img.decodeJpg(result.$4)!;
        expect((thumb.width, thumb.height), (2, 1));
        expect(thumb.getPixel(0, 0).r, closeTo(17, 2));
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
