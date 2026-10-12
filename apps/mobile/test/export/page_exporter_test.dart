import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/export/export_job.dart';
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

  /// Runs a new job for [pages] on [exporter] and returns it once ended.
  Future<ExportJob> runJob(
    PageExporter exporter,
    List<ScanPage> pages,
    ExportFormat format,
  ) async {
    final job = ExportJob(pages, format);
    await exporter.run(job, originalOf);
    return job;
  }

  /// Runs a job that must succeed and returns its files.
  Future<List<File>> exportFiles(
    PageExporter exporter,
    List<ScanPage> pages,
    ExportFormat format,
  ) async {
    final job = await runJob(exporter, pages, format);
    expect(job.state, ExportState.succeeded, reason: '$format');
    return job.files!;
  }

  /// Expects [job] to have ended as [state] with [failure], with the
  /// export directory already empty when listeners saw it end.
  void expectEnded(
    ExportJob job,
    ExportState state,
    ExportFailure failure,
    List<bool> emptyWhenEnded, {
    String? reason,
  }) {
    expect(job.state, state, reason: reason);
    expect(job.failure, failure, reason: reason);
    expect(job.files, isNull, reason: reason);
    expect(emptyWhenEnded, [true], reason: reason);
    expect(exportDirIsEmpty(), isTrue, reason: reason);
  }

  /// Records, when [job] reaches a final state, whether the export
  /// directory was empty at that moment.
  List<bool> watchEnd(ExportJob job) {
    final seen = <bool>[];
    job.addListener(() {
      if (job.state != ExportState.queued && job.state != ExportState.running) {
        seen.add(exportDirIsEmpty());
      }
    });
    return seen;
  }

  test('pdf: 3 pages become one X-Scanner.pdf with 3 pages', () async {
    final pages = threePages();
    final before = originalBytes();
    final files = await exportFiles(
      PageExporter(exportDir: exportDir),
      pages,
      ExportFormat.pdf,
    );

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
      final files = await exportFiles(
        PageExporter(exportDir: exportDir),
        pages,
        format,
      );

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
    final files = await exportFiles(
      PageExporter(
        exportDir: exportDir,
        renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async =>
            Uint8List(1),
      ),
      pages,
      ExportFormat.jpeg,
    );
    expect(files.first.path.endsWith('X-Scanner-trang-01.jpg'), isTrue);
    expect(files.last.path.endsWith('X-Scanner-trang-10.jpg'), isTrue);
  });

  test('100 pages get three-digit numbers that sort in page order', () async {
    final page = threePages().last;
    final pages = [
      for (var i = 0; i < 100; i++)
        ScanPage(id: 'q$i', originalPath: page.originalPath),
    ];
    final files = await exportFiles(
      PageExporter(
        exportDir: exportDir,
        renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async =>
            Uint8List(1),
      ),
      pages,
      ExportFormat.jpeg,
    );
    final names = [for (final f in files) f.path.split('/').last];
    expect(names, [
      for (var i = 1; i <= 100; i++)
        'X-Scanner-trang-${'$i'.padLeft(3, '0')}.jpg',
    ]);
    expect(names.first, 'X-Scanner-trang-001.jpg');
    expect(names.last, 'X-Scanner-trang-100.jpg');
    expect([...names]..sort(), names);
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
      await exportFiles(exporter, threePages(), format);
    }
    expect(maxActive, 1);
    expect(calls, [
      for (final f in [RenderFormat.jpeg, RenderFormat.jpeg, RenderFormat.png])
        for (var i = 0; i < 3; i++) ('p$i.png', i == 1 ? 1 : 0, f),
    ]);
  });

  test('a new export removes the files of the previous one', () async {
    final exporter = PageExporter(exportDir: exportDir);
    await exportFiles(exporter, threePages(), ExportFormat.jpeg);
    final files = await exportFiles(exporter, threePages(), ExportFormat.pdf);
    expect([for (final f in exportDir.listSync()) f.path], [files.single.path]);
  });

  test('job reports progress page by page (AC-2)', () async {
    for (final (format, names) in [
      (ExportFormat.pdf, ['X-Scanner.pdf']),
      (
        ExportFormat.jpeg,
        [for (var i = 1; i <= 3; i++) 'X-Scanner-trang-0$i.jpg'],
      ),
    ]) {
      final job = ExportJob(threePages(), format);
      final done = <int>[];
      final states = <ExportState>[];
      job.addListener(() {
        done.add(job.done);
        if (states.isEmpty || states.last != job.state) states.add(job.state);
      });

      await PageExporter(exportDir: exportDir).run(job, originalOf);

      expect(job.state, ExportState.succeeded, reason: '$format');
      expect(job.done, 3, reason: '$format');
      expect(job.failure, isNull, reason: '$format');
      expect(
        [for (final f in job.files!) f.path],
        [for (final name in names) '${exportDir.path}/$name'],
        reason: '$format',
      );
      expect(exportDir.listSync(), hasLength(names.length));
      expect(states, [ExportState.running, ExportState.succeeded]);
      expect(done, containsAllInOrder([1, 2, 3]), reason: '$format');
      expect(done.last, 3, reason: '$format');
      for (var i = 1; i < done.length; i++) {
        expect(done[i], greaterThanOrEqualTo(done[i - 1]), reason: '$format');
      }
    }
  });

  test('cancel stops at the next page (AC-3)', () async {
    for (final format in ExportFormat.values) {
      final renderer = _HeldRenderer(holds: {2});
      final job = ExportJob(threePages(), format);
      final ended = watchEnd(job);
      final running = PageExporter(
        exportDir: exportDir,
        renderer: renderer.call,
      ).run(job, originalOf);
      await renderer.reached(2);

      job.cancel();
      expect(job.state, ExportState.running, reason: '$format');
      renderer.release(2);
      await running;

      expectEnded(
        job,
        ExportState.cancelled,
        ExportFailure.cancelled,
        ended,
        reason: '$format',
      );
      expect(job.done, lessThanOrEqualTo(2), reason: '$format');
      expect(renderer.calls, hasLength(2), reason: 'page 3 not rendered');
    }
  });

  test('cancel before publishing leaves no files (AC-3)', () async {
    for (final format in [ExportFormat.jpeg, ExportFormat.pdf]) {
      final renderer = _HeldRenderer(holds: {3});
      final job = ExportJob(threePages(), format);
      final ended = watchEnd(job);
      final running = PageExporter(
        exportDir: exportDir,
        renderer: renderer.call,
      ).run(job, originalOf);
      await renderer.reached(3);

      job.cancel();
      renderer.release(3);
      await running;

      expectEnded(
        job,
        ExportState.cancelled,
        ExportFailure.cancelled,
        ended,
        reason: '$format',
      );
      expect(renderer.calls, hasLength(3), reason: '$format');
    }
  });

  test('a job cancelled while queued is not run', () async {
    exportDir.createSync();
    File('${exportDir.path}/stale.jpg').writeAsStringSync('s');
    final renderer = _HeldRenderer();
    final job = ExportJob(threePages(), ExportFormat.jpeg)..cancel();

    await PageExporter(
      exportDir: exportDir,
      renderer: renderer.call,
    ).run(job, originalOf);

    expect(job.state, ExportState.cancelled);
    expect(renderer.calls, isEmpty);
    expect(exportDirIsEmpty(), isTrue);
  });

  test('running a job that already ran throws and keeps its files', () async {
    final exporter = PageExporter(exportDir: exportDir);
    final job = await runJob(exporter, threePages(), ExportFormat.jpeg);
    expect(job.state, ExportState.succeeded);

    await expectLater(exporter.run(job, originalOf), throwsStateError);

    expect(job.state, ExportState.succeeded);
    for (final f in job.files!) {
      expect(f.existsSync(), isTrue, reason: f.path);
    }
  });

  test('render failure fails the job (AC-4)', () async {
    for (final format in ExportFormat.values) {
      final renderer = _HeldRenderer(failing: {2});
      final job = ExportJob(threePages(), format);
      final ended = watchEnd(job);

      await PageExporter(
        exportDir: exportDir,
        renderer: renderer.call,
      ).run(job, originalOf);

      expectEnded(
        job,
        ExportState.failed,
        ExportFailure.renderFailed,
        ended,
        reason: '$format',
      );
      expect(job.done, 1, reason: '$format');
      expect(renderer.calls, hasLength(2), reason: '$format');
    }
  });

  test('render failure fails the job: an undecodable original', () async {
    final pages = threePages();
    File(pages[1].originalPath).writeAsBytesSync([1, 2, 3]);
    for (final format in ExportFormat.values) {
      final job = await runJob(
        PageExporter(exportDir: exportDir),
        pages,
        format,
      );
      expect(job.state, ExportState.failed, reason: '$format');
      expect(job.failure, ExportFailure.renderFailed, reason: '$format');
      expect(exportDirIsEmpty(), isTrue, reason: '$format');
    }
  });

  test('write failure fails the job: an unreadable rendered image fails the '
      'pdf (AC-4)', () async {
    final job = ExportJob(threePages(), ExportFormat.pdf);
    final ended = watchEnd(job);
    await PageExporter(
      exportDir: exportDir,
      renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async =>
          Uint8List.fromList(List<int>.filled(16, 7)),
    ).run(job, originalOf);

    expectEnded(job, ExportState.failed, ExportFailure.writeFailed, ended);
    expect(job.done, 3);
  });

  test('write failure fails the job: an export directory that cannot be '
      'created (AC-4)', () async {
    final blocker = File('${tmp.path}/blocker')..writeAsStringSync('x');
    final renderer = _HeldRenderer();
    for (final format in ExportFormat.values) {
      final job = await runJob(
        PageExporter(
          exportDir: Directory('${blocker.path}/exports'),
          renderer: renderer.call,
        ),
        threePages(),
        format,
      );
      expect(job.state, ExportState.failed, reason: '$format');
      expect(job.failure, ExportFailure.writeFailed, reason: '$format');
      expect(job.files, isNull, reason: '$format');
    }
    expect(renderer.calls, isEmpty);
    expect(blocker.readAsStringSync(), 'x');
  });

  test('write failure fails the job: a page file that cannot be written '
      '(AC-4)', () async {
    final job = ExportJob(threePages(), ExportFormat.png);
    final ended = watchEnd(job);
    var call = 0;
    await PageExporter(
      exportDir: exportDir,
      renderer: (path, quad, turns, {format = RenderFormat.jpeg}) async {
        // A directory in the way of the second page's file.
        if (++call == 2) {
          Directory('${exportDir.path}/X-Scanner-trang-02.png').createSync();
        }
        return Uint8List(1);
      },
    ).run(job, originalOf);

    expectEnded(job, ExportState.failed, ExportFailure.writeFailed, ended);
    expect(job.done, 1);
  });

  test(
    'export uses the snapshot taken when the job was created (AC-5)',
    () async {
      final pages = threePages();
      final renderer = _HeldRenderer(holds: {1});
      final job = ExportJob(pages, ExportFormat.jpeg);
      final running = PageExporter(
        exportDir: exportDir,
        renderer: renderer.call,
      ).run(job, originalOf);
      await renderer.reached(1);

      // The caller's list changes: page 3 removed, page 2 turned again.
      final turned = pages[1].rotatedClockwise();
      pages
        ..removeLast()
        ..[1] = turned;
      renderer.release(1);
      await running;

      expect(job.state, ExportState.succeeded);
      expect(job.files, hasLength(3));
      expect(renderer.calls, [
        for (var i = 0; i < 3; i++) (PageQuad.fullFrame, i == 1 ? 1 : 0),
      ]);
    },
  );

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

/// Renderer returning a small JPEG. Records the quad and quarter turns of
/// every call; waits at the 1-based calls in `holds` until [release] and
/// throws at those in `failing`.
class _HeldRenderer {
  _HeldRenderer({Set<int> holds = const {}, this.failing = const {}})
    : _holds = {for (final n in holds) n: Completer<void>()};

  final Set<int> failing;
  final Map<int, Completer<void>> _holds;
  final Map<int, Completer<void>> _reached = {};
  final List<(PageQuad, int)> calls = [];

  static final Uint8List _jpeg = img.encodeJpg(img.Image(width: 4, height: 4));

  /// Completes once call [n] has started.
  Future<void> reached(int n) =>
      _reached.putIfAbsent(n, Completer<void>.new).future;

  /// Lets call [n] return.
  void release(int n) => _holds[n]!.complete();

  Future<Uint8List> call(
    String path,
    PageQuad quad,
    int turns, {
    RenderFormat format = RenderFormat.jpeg,
  }) async {
    calls.add((quad, turns));
    final n = calls.length;
    final reached = _reached.putIfAbsent(n, Completer<void>.new);
    if (!reached.isCompleted) reached.complete();
    await _holds[n]?.future;
    if (failing.contains(n)) throw StateError('render failed');
    return _jpeg;
  }
}
