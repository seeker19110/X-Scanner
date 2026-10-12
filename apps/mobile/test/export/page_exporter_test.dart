import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' show PdfException;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';

void main() {
  late Directory tmp;
  late Directory originals;
  late Directory exportDir;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('page_exporter_test');
    originals = Directory('${tmp.path}/originals')..createSync();
    exportDir = Directory('${tmp.path}/exports');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  File originalOf(ScanPage page) => File(page.originalPath);

  /// Three synthetic PNG originals of different sizes; the second page is
  /// turned a quarter, so the rendered sizes are 30×40, 30×50 and 20×20.
  List<ScanPage> threePages() {
    const sizes = [(30, 40), (50, 30), (20, 20)];
    return [
      for (var i = 0; i < sizes.length; i++)
        ScanPage(
          id: 'p$i',
          originalPath:
              (File('${originals.path}/p$i.png')..writeAsBytesSync(
                    img.encodePng(
                      img.Image(width: sizes[i].$1, height: sizes[i].$2),
                    ),
                  ))
                  .path,
          quarterTurns: i == 1 ? 1 : 0,
        ),
    ];
  }

  const renderedSizes = [(30, 40), (30, 50), (20, 20)];

  Map<String, List<int>> originalBytes() => {
    for (final f in originals.listSync().whereType<File>())
      f.path: f.readAsBytesSync(),
  };

  bool exportDirIsEmpty() =>
      !exportDir.existsSync() || exportDir.listSync().isEmpty;

  test('pdf: 3 pages become one X-Scanner.pdf with 3 pages', () async {
    final pages = threePages();
    final before = originalBytes();
    final files = await PageExporter(exportDir: exportDir)
        .export(pages, originalOf, ExportFormat.pdf);

    expect(files, hasLength(1));
    expect(files.single.path, '${exportDir.path}/X-Scanner.pdf');
    expect(exportDir.listSync(), hasLength(1));
    final pdf = latin1.decode(files.single.readAsBytesSync());
    expect(pdf.startsWith('%PDF-'), isTrue);
    expect(RegExp(r'/Type\s*/Page(?![a-zA-Z])').allMatches(pdf), hasLength(3));
    expect(originalBytes(), before, reason: 'originals untouched');
  });

  for (final (format, ext) in [
    (ExportFormat.jpeg, 'jpg'),
    (ExportFormat.png, 'png'),
  ]) {
    test('$ext: one file per page, named and ordered by page', () async {
      final pages = threePages();
      final before = originalBytes();
      final files = await PageExporter(exportDir: exportDir)
          .export(pages, originalOf, format);

      expect(
        [for (final f in files) f.path],
        [
          for (var i = 1; i <= 3; i++)
            '${exportDir.path}/X-Scanner-trang-0$i.$ext',
        ],
      );
      expect(exportDir.listSync(), hasLength(3));
      for (var i = 0; i < 3; i++) {
        final bytes = files[i].readAsBytesSync();
        final decoded = format == ExportFormat.png
            ? img.PngDecoder().decode(bytes)
            : img.JpegDecoder().decode(bytes);
        expect(decoded, isNotNull, reason: 'page ${i + 1} is a $ext');
        expect(
          (decoded!.width, decoded.height),
          renderedSizes[i],
          reason: 'page ${i + 1}',
        );
      }
      expect(originalBytes(), before, reason: 'originals untouched');
    });
  }

  test('page numbers have at least two digits', () async {
    final page = threePages().last;
    final pages = [
      for (var i = 0; i < 10; i++)
        ScanPage(id: 'q$i', originalPath: page.originalPath),
    ];
    final files = await PageExporter(
      exportDir: exportDir,
      renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async =>
          Uint8List(1),
    ).export(pages, originalOf, ExportFormat.jpeg);
    expect(files.first.path.endsWith('X-Scanner-trang-01.jpg'), isTrue);
    expect(files.last.path.endsWith('X-Scanner-trang-10.jpg'), isTrue);
  });

  test('pages render one at a time with the matching format', () async {
    var active = 0;
    var maxActive = 0;
    final calls = <(String, int, RenderFormat)>[];
    Future<Uint8List> renderer(
      String path,
      PageQuad quad,
      int turns, {
      RenderFormat format = RenderFormat.jpeg,
    }) async {
      active++;
      maxActive = max(maxActive, active);
      calls.add((path.split('/').last, turns, format));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      active--;
      return renderPageSync(
        File(path).readAsBytesSync(),
        quad,
        turns,
        format: format,
      );
    }

    final exporter = PageExporter(exportDir: exportDir, renderer: renderer);
    for (final format in ExportFormat.values) {
      await exporter.export(threePages(), originalOf, format);
    }
    expect(maxActive, 1);
    expect(calls, [
      for (final f in [RenderFormat.jpeg, RenderFormat.jpeg, RenderFormat.png])
        for (var i = 0; i < 3; i++) ('p$i.png', i == 1 ? 1 : 0, f),
    ]);
  });

  test('a new export removes the files of the previous one', () async {
    final exporter = PageExporter(exportDir: exportDir);
    await exporter.export(threePages(), originalOf, ExportFormat.jpeg);
    final files = await exporter.export(
      threePages(),
      originalOf,
      ExportFormat.pdf,
    );
    expect([for (final f in exportDir.listSync()) f.path], [files.single.path]);
  });

  test('an undecodable page fails the export and leaves no file', () async {
    final pages = threePages();
    File(pages[1].originalPath).writeAsBytesSync([1, 2, 3]);
    for (final format in ExportFormat.values) {
      await expectLater(
        PageExporter(exportDir: exportDir).export(pages, originalOf, format),
        throwsA(isA<ImageDecodeFailure>()),
        reason: '$format',
      );
      expect(exportDirIsEmpty(), isTrue, reason: '$format');
    }
  });

  test('any renderer error is passed on after cleaning up', () async {
    var call = 0;
    final exporter = PageExporter(
      exportDir: exportDir,
      renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async {
        if (++call == 3) throw StateError('boom');
        return img.encodeJpg(img.Image(width: 4, height: 4));
      },
    );
    await expectLater(
      exporter.export(threePages(), originalOf, ExportFormat.jpeg),
      throwsStateError,
    );
    expect(exportDirIsEmpty(), isTrue);
  });

  test('an unreadable rendered image fails the pdf without files', () async {
    final exporter = PageExporter(
      exportDir: exportDir,
      renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async =>
          Uint8List.fromList(List<int>.filled(16, 7)),
    );
    await expectLater(
      exporter.export(threePages(), originalOf, ExportFormat.pdf),
      throwsA(isA<PdfException>()),
    );
    expect(exportDirIsEmpty(), isTrue);
  });

  test('an export directory that cannot be created fails', () async {
    final blocker = File('${tmp.path}/blocker')..writeAsStringSync('x');
    final exporter = PageExporter(
      exportDir: Directory('${blocker.path}/exports'),
    );
    await expectLater(
      exporter.export(threePages(), originalOf, ExportFormat.png),
      throwsA(isA<FileSystemException>()),
    );
    expect(blocker.readAsStringSync(), 'x');
  });

  test('an empty page list is rejected without touching files', () async {
    exportDir.createSync();
    final keep = File('${exportDir.path}/keep')..writeAsStringSync('k');
    await expectLater(
      PageExporter(exportDir: exportDir)
          .export(const [], originalOf, ExportFormat.pdf),
      throwsArgumentError,
    );
    expect(keep.existsSync(), isTrue);
  });

  test('clear removes the directory and tolerates a missing one', () async {
    final exporter = PageExporter(exportDir: exportDir);
    await exporter.clear();
    expect(exportDir.existsSync(), isFalse);

    Directory('${exportDir.path}/nested').createSync(recursive: true);
    File('${exportDir.path}/nested/a.jpg').writeAsStringSync('a');
    await exporter.clear();
    expect(exportDir.existsSync(), isFalse);
    expect(originals.existsSync(), isTrue);
  });

  test('clearLeftovers also removes copies kept by the share sheet', () async {
    final shareCache = Directory('${tmp.path}/share_plus');
    final exporter = PageExporter(
      exportDir: exportDir,
      leftoverDirs: [shareCache],
    );
    File('${shareCache.path}/X-Scanner.pdf')
      ..createSync(recursive: true)
      ..writeAsStringSync('copy');
    File('${exportDir.path}/X-Scanner.pdf')
      ..createSync(recursive: true)
      ..writeAsStringSync('export');

    await exporter.clear();
    expect(shareCache.existsSync(), isTrue, reason: 'may still be read');

    await exporter.clearLeftovers();
    expect(shareCache.existsSync(), isFalse);
    expect(exportDir.existsSync(), isFalse);
    expect(originals.existsSync(), isTrue);
    await exporter.clearLeftovers();
  });

  group('mimeTypeFor', () {
    test('maps the export extensions', () {
      expect(mimeTypeFor('/x/X-Scanner.pdf'), 'application/pdf');
      expect(mimeTypeFor('/x/X-Scanner-trang-01.jpg'), 'image/jpeg');
      expect(mimeTypeFor('/x/X-Scanner-trang-01.PNG'), 'image/png');
    });

    test('rejects other extensions', () {
      expect(() => mimeTypeFor('/x/a.txt'), throwsArgumentError);
      expect(() => mimeTypeFor('/x/noext'), throwsArgumentError);
    });
  });
}
