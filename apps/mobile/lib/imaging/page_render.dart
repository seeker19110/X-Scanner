import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/page_quad.dart';
import 'homography.dart';

/// Largest decoded image (width × height) accepted, checked from the header
/// before any pixel buffer is allocated, and largest rectified output.
// DEBT: 50 MP decode limit chosen without device memory measurement | trần: about 150 MB per decoded original | xem lại khi: P2 device benchmark (spec §2, §19).
const int maxDecodedPixels = 50000000;

/// The bytes could not be decoded into an image within limits.
///
/// Deliberately carries no path or content.
class ImageDecodeFailure implements Exception {
  /// Creates the failure.
  const ImageDecodeFailure();

  @override
  String toString() => 'ImageDecodeFailure';
}

/// Decodes the first frame of [bytes] and bakes its EXIF orientation in.
///
/// Throws [ImageDecodeFailure] for unknown formats, invalid or oversized
/// headers (more than [maxPixels] pixels) and any decoder error.
img.Image decodeOriented(Uint8List bytes, {int maxPixels = maxDecodedPixels}) {
  try {
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) throw const ImageDecodeFailure();
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width * info.height > maxPixels) {
      throw const ImageDecodeFailure();
    }
    final image = decoder.decode(bytes, frame: 0);
    if (image == null) throw const ImageDecodeFailure();
    // bakeOrientation always copies the pixels; skip it when there is
    // nothing to bake so a large original is held in memory only once.
    final ifd = image.exif.imageIfd;
    final upright = !ifd.hasOrientation || ifd.orientation == 1;
    return upright ? image : img.bakeOrientation(image);
  } on ImageDecodeFailure {
    rethrow;
  } catch (_) {
    // Decoders throw assorted exceptions and errors (e.g. RangeError on
    // truncated data); none of them may escape with content attached.
    throw const ImageDecodeFailure();
  }
}

/// Output size of [rectify]: the longer of each pair of opposite edges of
/// [quad] measured in pixels of an [imageWidth] × [imageHeight] image,
/// rounded and at least 1.
///
/// A skewed [quad] can measure more pixels than the image holds; a size
/// above [maxPixels] is scaled down by the same factor on both sides,
/// rounded down, so the aspect stays within one pixel. When a side is held
/// at 1 the other is shortened to [maxPixels].
({int width, int height}) rectifiedSize(
  PageQuad quad,
  int imageWidth,
  int imageHeight, {
  int maxPixels = maxDecodedPixels,
}) {
  final c = _pixelCorners(quad, imageWidth, imageHeight);
  var width = max(1, max(c.tr.distanceTo(c.tl), c.br.distanceTo(c.bl)).round());
  var height = max(
    1,
    max(c.bl.distanceTo(c.tl), c.br.distanceTo(c.tr)).round(),
  );
  if (width * height > maxPixels) {
    final scale = sqrt(maxPixels / (width * height));
    width = max(1, (width * scale).floor());
    height = max(1, (height * scale).floor());
    // Left over only by a side held at 1 or by floating-point rounding.
    if (width * height > maxPixels) {
      if (width >= height) {
        width = max(1, maxPixels ~/ height);
      } else {
        height = max(1, maxPixels ~/ width);
      }
    }
  }
  return (width: width, height: height);
}

/// Perspective-corrects the [quad] region of [source] into a new upright
/// 8-bit image of [rectifiedSize], sampling bilinearly at each projected
/// pixel centre. [source] is not modified.
///
/// Sample positions are clamped to the outermost pixel centres so border
/// samples never blend in out-of-range (black) pixels. Non-8-bit or
/// palette sources are first converted to 8-bit so channel values are
/// rescaled rather than truncated. The output holds at most [maxPixels].
img.Image rectify(
  img.Image source,
  PageQuad quad, {
  int maxPixels = maxDecodedPixels,
}) {
  final src = source.format == img.Format.uint8 && !source.hasPalette
      ? source
      : source.convert(format: img.Format.uint8, noAnimation: true);
  final size = rectifiedSize(quad, src.width, src.height, maxPixels: maxPixels);
  final c = _pixelCorners(quad, src.width, src.height);
  final homography = Homography.unitSquareTo(
    topLeft: c.tl,
    topRight: c.tr,
    bottomRight: c.br,
    bottomLeft: c.bl,
  );
  final out = img.Image(
    width: size.width,
    height: size.height,
    numChannels: src.numChannels,
  );
  final maxX = src.width - 1;
  final maxY = src.height - 1;
  for (var j = 0; j < size.height; j++) {
    final v = (j + 0.5) / size.height;
    for (var i = 0; i < size.width; i++) {
      final p = homography.map((i + 0.5) / size.width, v);
      out.setPixel(
        i,
        j,
        src.getPixelInterpolate(
          (p.x - 0.5).clamp(0, maxX),
          (p.y - 0.5).clamp(0, maxY),
          interpolation: img.Interpolation.linear,
        ),
      );
    }
  }
  return out;
}

/// Encoding of rendered pages.
enum RenderFormat { jpeg, png }

/// Decodes [originalBytes], rectifies [quad], rotates clockwise by
/// [quarterTurns] × 90° and encodes as [format]. Both the decoded original
/// and the rectified page hold at most [maxPixels].
///
/// Throws [ImageDecodeFailure] if the original cannot be decoded.
Uint8List renderPageSync(
  Uint8List originalBytes,
  PageQuad quad,
  int quarterTurns, {
  RenderFormat format = RenderFormat.jpeg,
  int maxPixels = maxDecodedPixels,
}) {
  var page = rectify(
    decodeOriented(originalBytes, maxPixels: maxPixels),
    quad,
    maxPixels: maxPixels,
  );
  if (quarterTurns != 0) {
    page = img.copyRotate(page, angle: 90 * quarterTurns);
  }
  return switch (format) {
    RenderFormat.jpeg => img.encodeJpg(page, quality: 90),
    RenderFormat.png => img.encodePng(page),
  };
}

/// Runs [renderPageSync] on the file at [originalPath] in a background
/// isolate. The original file is only read.
Future<Uint8List> renderPage(
  String originalPath,
  PageQuad quad,
  int quarterTurns, {
  RenderFormat format = RenderFormat.jpeg,
}) => Isolate.run(
  () => renderPageSync(
    File(originalPath).readAsBytesSync(),
    quad,
    quarterTurns,
    format: format,
  ),
);

/// Decodes [originalBytes] and encodes a JPEG whose longer side is at most
/// [maxSide], keeping the aspect ratio.
///
/// Throws [ImageDecodeFailure] if the original cannot be decoded.
Uint8List thumbnailSync(
  Uint8List originalBytes, {
  int maxSide = 1024,
  int maxPixels = maxDecodedPixels,
}) {
  var image = decodeOriented(originalBytes, maxPixels: maxPixels);
  if (max(image.width, image.height) > maxSide) {
    final landscape = image.width >= image.height;
    image = img.copyResize(
      image,
      width: landscape ? maxSide : null,
      height: landscape ? null : maxSide,
      interpolation: img.Interpolation.average,
    );
  }
  return img.encodeJpg(image, quality: 85);
}

/// Runs [thumbnailSync] on the file at [originalPath] in a background
/// isolate. The original file is only read.
Future<Uint8List> thumbnail(String originalPath, {int maxSide = 1024}) =>
    Isolate.run(
      () =>
          thumbnailSync(File(originalPath).readAsBytesSync(), maxSide: maxSide),
    );

/// The corners of [quad] in continuous pixel coordinates.
({Point<double> tl, Point<double> tr, Point<double> br, Point<double> bl})
_pixelCorners(PageQuad quad, int width, int height) {
  Point<double> scale(Point<double> p) =>
      Point<double>(p.x * width, p.y * height);
  return (
    tl: scale(quad.topLeft),
    tr: scale(quad.topRight),
    br: scale(quad.bottomRight),
    bl: scale(quad.bottomLeft),
  );
}
