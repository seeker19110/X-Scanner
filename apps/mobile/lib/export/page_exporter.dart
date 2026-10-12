import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../core/page_quad.dart';
import '../core/scan_page.dart';
import '../imaging/page_render.dart';
import 'export_job.dart';
import 'pdf_export.dart';

export 'export_job.dart' show ExportFormat;

/// Renders one page of an original image; see [renderPage].
typedef PageRenderer = Future<Uint8List> Function(
  String originalPath,
  PageQuad quad,
  int quarterTurns, {
  RenderFormat format,
});

/// Writes rendered pages into [exportDir], which it owns: every export
/// starts by deleting it and a failed export leaves nothing behind.
///
/// Originals are only read, through the renderer. Nothing is logged.
class PageExporter {
  /// Creates an exporter writing into [exportDir]. [leftoverDirs] hold
  /// copies made outside it (the share sheet's cache) that are only safe
  /// to delete later, by [clearLeftovers].
  PageExporter({
    required this.exportDir,
    this.leftoverDirs = const [],
    this._renderer = renderPage,
  });

  /// Directory holding the exported files; deleted by [clear].
  final Directory exportDir;

  /// Other directories that may still hold exported copies.
  final List<Directory> leftoverDirs;
  final PageRenderer _renderer;

  static const String _baseName = 'X-Scanner';

  /// Runs [job]: renders its pages in order, one at a time, from the
  /// originals given by [originalOf] and writes them as its format: one
  /// `X-Scanner.pdf`, built in a background isolate, or one
  /// `X-Scanner-trang-NN.jpg`/`.png` per page, numbered with at least two
  /// digits and as many as the page count needs so names sort in page
  /// order. The files, in page order, are published only through
  /// [ExportJob.succeed].
  ///
  /// Does not throw: a cancel is honoured before every page and once more
  /// before publishing, and a failure ends the job with its
  /// [ExportFailure]. Either way the exported files are removed before the
  /// job ends. A job cancelled while queued is not run; running a job
  /// that already ran is a [StateError].
  Future<void> run(
    ExportJob job,
    File Function(ScanPage page) originalOf,
  ) async {
    // DEBT: a PDF holds every rendered page in memory, and Isolate.run copies those JPEGs into the PDF isolate, so the peak is about twice their size | trần: about 100 pages of 12 MP on a 4 GB device, not measured | xem lại khi: P2 measures export on devices (spec §2).
    // Checked before the clear, which would delete the files of a job
    // that already ran. A job cancelled while queued still clears.
    if (job.state != ExportState.queued && job.state != ExportState.cancelled) {
      throw StateError('the job already ran');
    }
    await clear();
    // Cancelled while queued, possibly during the clear above.
    if (job.state == ExportState.cancelled) return;
    job.start();
    final pages = job.pages;
    final pdf = job.format == ExportFormat.pdf;
    final (renderFormat, extension) = job.format == ExportFormat.png
        ? (RenderFormat.png, 'png')
        : (RenderFormat.jpeg, 'jpg');
    final digits = max(2, '${pages.length}'.length);
    final images = <Uint8List>[];
    final files = <File>[];
    try {
      await _step(
        ExportFailure.writeFailed,
        () => exportDir.create(recursive: true),
      );
      for (var i = 0; i < pages.length; i++) {
        _stopIfCancelled(job);
        final bytes = await _step(
          ExportFailure.renderFailed,
          () => _render(pages[i], originalOf, renderFormat),
        );
        if (pdf) {
          images.add(bytes);
        } else {
          final number = '${i + 1}'.padLeft(digits, '0');
          files.add(
            await _step(
              ExportFailure.writeFailed,
              () => _write('$_baseName-trang-$number.$extension', bytes),
            ),
          );
        }
        job.pageDone();
      }
      if (pdf) {
        files.add(
          await _step(
            ExportFailure.writeFailed,
            () async =>
                _write('$_baseName.pdf', await _buildPdfInIsolate(images)),
          ),
        );
      }
      _stopIfCancelled(job);
    } on _Stop catch (stop) {
      // Listeners only see the job end once its files are gone.
      await clear();
      if (stop.failure == ExportFailure.cancelled) {
        job.markCancelled();
      } else {
        job.fail(stop.failure);
      }
      return;
    }
    job.succeed(files);
  }

  /// Deletes [exportDir] and everything in it; a missing directory or a
  /// failed delete is ignored.
  Future<void> clear() => _deleteQuietly(exportDir);

  /// Like [clear], and also deletes [leftoverDirs]. Call it when no share
  /// can still be reading those copies, e.g. at app start.
  Future<void> clearLeftovers() async {
    await clear();
    for (final dir in leftoverDirs) {
      await _deleteQuietly(dir);
    }
  }

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      // Best effort: a leftover temporary file is retried on the next clear.
    }
  }

  /// Runs [buildPdf] off the UI isolate. Static so the closure captures
  /// only [images]; a [PdfException] is rethrown here as it was raised.
  static Future<Uint8List> _buildPdfInIsolate(List<Uint8List> images) =>
      Isolate.run(() => buildPdf(images));

  /// Runs [action]; any error it throws becomes a [_Stop] with
  /// [failure]. Decode, isolate, file system errors and a `PdfException`
  /// all mean the same to the job; none of their details are kept.
  static Future<T> _step<T>(
    ExportFailure failure,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      throw _Stop(failure);
    }
  }

  static void _stopIfCancelled(ExportJob job) {
    if (job.cancelRequested) throw const _Stop(ExportFailure.cancelled);
  }

  Future<Uint8List> _render(
    ScanPage page,
    File Function(ScanPage page) originalOf,
    RenderFormat format,
  ) => _renderer(
    originalOf(page).path,
    page.quad,
    page.quarterTurns,
    format: format,
  );

  Future<File> _write(String name, Uint8List bytes) =>
      File('${exportDir.path}/$name').writeAsBytes(bytes, flush: true);
}

/// Ends a run early with [failure].
class _Stop implements Exception {
  const _Stop(this.failure);

  final ExportFailure failure;
}
