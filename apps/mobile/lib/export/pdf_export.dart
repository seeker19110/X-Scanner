import 'dart:math';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Long side of every PDF page in points: the long side of A4.
const double pdfLongSidePoints = 842;

/// A borderless page with the aspect ratio and orientation of a
/// [widthPx] × [heightPx] image whose long side is [pdfLongSidePoints].
///
/// Throws [ArgumentError] if either size is not positive.
PdfPageFormat pageFormatFor(int widthPx, int heightPx) {
  if (widthPx <= 0) {
    throw ArgumentError.value(widthPx, 'widthPx', 'must be positive');
  }
  if (heightPx <= 0) {
    throw ArgumentError.value(heightPx, 'heightPx', 'must be positive');
  }
  final scale = pdfLongSidePoints / max(widthPx, heightPx);
  return PdfPageFormat(widthPx * scale, heightPx * scale, marginAll: 0);
}

/// Builds a PDF with one page per rendered JPEG/PNG in [pageImages], each
/// page sized by [pageFormatFor] and filled edge to edge by its image.
///
/// Throws [ArgumentError] for an empty list; a [PdfException] for an
/// unreadable image is passed on.
Future<Uint8List> buildPdf(
  List<Uint8List> pageImages, {
  bool compress = true,
}) async {
  if (pageImages.isEmpty) {
    throw ArgumentError.value(pageImages, 'pageImages', 'must not be empty');
  }
  final doc = pw.Document(compress: compress);
  for (final bytes in pageImages) {
    final image = pw.MemoryImage(bytes);
    doc.addPage(
      pw.Page(
        pageFormat: pageFormatFor(image.width!, image.height!),
        margin: pw.EdgeInsets.zero,
        // The page has the image's aspect ratio, so fill does not stretch.
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return doc.save();
}
