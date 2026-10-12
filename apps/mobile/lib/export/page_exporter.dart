import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../core/page_quad.dart';
import '../core/scan_page.dart';
import '../imaging/page_render.dart';
import 'pdf_export.dart';

/// File types the session can be exported to.
enum ExportFormat { pdf, jpeg, png }

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

  /// Renders [pages] in order, one at a time, from the originals given by
  /// [originalOf] and writes them as [format]: one `X-Scanner.pdf`, built
  /// in a background isolate, or one `X-Scanner-trang-NN.jpg`/`.png` per
  /// page, numbered with at least two digits and as many as the page count
  /// needs so names sort in page order. Returns the files in page order.
  ///
  /// Throws [ArgumentError] for an empty [pages]. Any other failure removes
  /// the exported files and is rethrown.
  Future<List<File>> export(
    List<ScanPage> pages,
    File Function(ScanPage page) originalOf,
    ExportFormat format,
  ) async {
    // DEBT: a PDF holds every rendered page in memory, and Isolate.run copies those JPEGs into the PDF isolate, so the peak is about twice their size | trần: about 100 pages of 12 MP on a 4 GB device, not measured | xem lại khi: P2 measures export on devices (spec §2).
    if (pages.isEmpty) {
      throw ArgumentError.value(pages, 'pages', 'must not be empty');
    }
    await clear();
    try {
      await exportDir.create(recursive: true);
      return format == ExportFormat.pdf
          ? [await _writePdf(pages, originalOf)]
          : await _writeImages(pages, originalOf, format);
    } catch (_) {
      await clear();
      rethrow;
    }
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

  Future<File> _writePdf(
    List<ScanPage> pages,
    File Function(ScanPage page) originalOf,
  ) async {
    final images = <Uint8List>[];
    for (final page in pages) {
      images.add(await _render(page, originalOf, RenderFormat.jpeg));
    }
    return _write('$_baseName.pdf', await _buildPdfInIsolate(images));
  }

  /// Runs [buildPdf] off the UI isolate. Static so the closure captures
  /// only [images]; a [PdfException] is rethrown here as it was raised.
  static Future<Uint8List> _buildPdfInIsolate(List<Uint8List> images) =>
      Isolate.run(() => buildPdf(images));

  Future<List<File>> _writeImages(
    List<ScanPage> pages,
    File Function(ScanPage page) originalOf,
    ExportFormat format,
  ) async {
    final (renderFormat, extension) = format == ExportFormat.png
        ? (RenderFormat.png, 'png')
        : (RenderFormat.jpeg, 'jpg');
    final digits = max(2, '${pages.length}'.length);
    final files = <File>[];
    for (var i = 0; i < pages.length; i++) {
      final bytes = await _render(pages[i], originalOf, renderFormat);
      final number = '${i + 1}'.padLeft(digits, '0');
      files.add(await _write('$_baseName-trang-$number.$extension', bytes));
    }
    return List.unmodifiable(files);
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
