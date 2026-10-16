import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/page_quad.dart';
import 'homography.dart';
import 'isolate_budget.dart';

/// Largest decoded image (width × height) accepted, checked from the header
/// before any pixel buffer is allocated, and largest rectified output.
// DEBT: 50 MP decode limit chosen without device memory measurement | trần: about 150 MB per decoded original | xem lại khi: P2 device benchmark (spec §2, §19).
const int maxDecodedPixels = 50000000;

/// Largest original file read into memory, checked from the file length
/// before any byte is read.
// DEBT: cap chosen without measuring real originals; a 50 MP PNG photo could exceed it | trần: 64 MiB per original | xem lại khi: P2 device benchmark or a user report of a refused large photo.
const int maxOriginalBytes = 64 * 1024 * 1024;

/// The bytes could not be decoded into an image within limits.
///
/// Deliberately carries no path or content.
class ImageDecodeFailure implements Exception {
  /// Creates the failure.
  const ImageDecodeFailure();

  @override
  String toString() => 'ImageDecodeFailure';
}

const List<int> _jpegMagic = [0xFF, 0xD8, 0xFF];
const List<int> _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const List<int> _riffMagic = [0x52, 0x49, 0x46, 0x46]; // RIFF
const List<int> _webpMagic = [0x57, 0x45, 0x42, 0x50]; // WEBP

/// The decoder for [bytes] if they start like a JPEG, PNG or WebP file, else
/// `null`. Only these formats are accepted as originals, whatever the file
/// is named: fewer decoders face untrusted input, and none is picked by a
/// loose guess such as TGA.
img.Decoder? _decoderFor(Uint8List bytes) {
  bool startsWith(List<int> magic, [int offset = 0]) {
    if (bytes.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[offset + i] != magic[i]) return false;
    }
    return true;
  }

  if (startsWith(_jpegMagic)) return img.JpegDecoder();
  if (startsWith(_pngMagic)) return img.PngDecoder();
  if (startsWith(_riffMagic) && startsWith(_webpMagic, 8)) {
    return img.WebPDecoder();
  }
  return null;
}

/// The decoder for [bytes] and their header, or `null` for a format other
/// than JPEG, PNG or WebP, an unreadable header, a non-positive side or an
/// animated WebP.
///
/// An animated WebP reports its canvas, not the size of the frame that
/// decoding allocates, so the pixel ceiling could not hold for it. (An
/// animated PNG decodes frame 0 at its header size.)
({img.Decoder decoder, img.DecodeInfo info})? _startDecode(Uint8List bytes) {
  final decoder = _decoderFor(bytes);
  final info = decoder?.startDecode(bytes);
  if (decoder == null || info == null || info.width <= 0 || info.height <= 0) {
    return null;
  }
  if (info is img.WebPInfo &&
      (info.hasAnimation ||
          info.format == img.WebPFormat.animated ||
          info.frames.isNotEmpty)) {
    return null;
  }
  return (decoder: decoder, info: info);
}

/// Width and height of the image in [bytes], read from its header only
/// (no pixels are decoded), or `null` when the header is not accepted (see
/// [_startDecode]).
({int width, int height})? imageSizeOf(Uint8List bytes) {
  final info = _startDecode(bytes)?.info;
  if (info == null) return null;
  return (width: info.width, height: info.height);
}

/// Decodes the first frame of [bytes] and bakes its EXIF orientation in.
///
/// Throws [ImageDecodeFailure] for formats other than JPEG, PNG and WebP
/// (recognised by content, not file name), animated WebP, invalid or
/// oversized
/// headers (more than [maxPixels] pixels) and any decoder error.
img.Image decodeOriented(Uint8List bytes, {int maxPixels = maxDecodedPixels}) {
  try {
    final start = _startDecode(bytes);
    if (start == null) throw const ImageDecodeFailure();
    final (:decoder, :info) = start;
    if (info.width * info.height > maxPixels) {
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
/// Exact full-frame output at unchanged dimensions copies normalized pixels
/// without resampling. The output always owns its pixels and omits metadata.
img.Image rectify(
  img.Image source,
  PageQuad quad, {
  int maxPixels = maxDecodedPixels,
}) {
  final src = source.format == img.Format.uint8 && !source.hasPalette
      ? source
      : source.convert(format: img.Format.uint8, noAnimation: true);
  final size = rectifiedSize(quad, src.width, src.height, maxPixels: maxPixels);
  final out = img.Image(
    width: size.width,
    height: size.height,
    numChannels: src.numChannels,
  );
  if (quad == PageQuad.fullFrame &&
      size.width == src.width &&
      size.height == src.height) {
    final bytes = out.toUint8List();
    bytes.setRange(0, bytes.length, src.toUint8List());
    return out;
  }
  // DEBT: generic interpolation does not preserve gray-alpha channels | trần: non-full-frame or resized 2-channel sources | xem lại khi: W-104b decoder upgrade (2026-10-18) or gray-alpha crop regression work.
  final c = _pixelCorners(quad, src.width, src.height);
  final homography = Homography.unitSquareTo(
    topLeft: c.tl,
    topRight: c.tr,
    bottomRight: c.br,
    bottomLeft: c.bl,
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
/// isolate within [decodeBudget]. The original file is only read, and not
/// at all when it holds more than [maxBytes].
///
/// Throws [ImageDecodeFailure] if the original cannot be read or decoded
/// within these limits.
Future<Uint8List> renderPage(
  String originalPath,
  PageQuad quad,
  int quarterTurns, {
  RenderFormat format = RenderFormat.jpeg,
  int maxBytes = maxOriginalBytes,
}) => runWithinBudget(
  () => renderPageSync(
    _readOriginalSync(originalPath, maxBytes),
    quad,
    quarterTurns,
    format: format,
  ),
  decodeBudget,
);

/// Renders [thumbnailBytes] cropped by [quad] and rotated by [quarterTurns]
/// exactly as [renderPageSync] renders an export, in a background isolate
/// within [decodeBudget]. Throws [ImageDecodeFailure] if the bytes cannot be
/// decoded.
Future<Uint8List> croppedPreview(
  Uint8List thumbnailBytes,
  PageQuad quad,
  int quarterTurns,
) => runWithinBudget(
  () => renderPageSync(thumbnailBytes, quad, quarterTurns),
  decodeBudget,
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
/// isolate within [decodeBudget]. The original file is only read, and not
/// at all when it holds more than [maxBytes].
///
/// Throws [ImageDecodeFailure] if the original cannot be read or decoded
/// within these limits.
Future<Uint8List> thumbnail(
  String originalPath, {
  int maxSide = 1024,
  int maxBytes = maxOriginalBytes,
}) => runWithinBudget(
  () => thumbnailSync(
    _readOriginalSync(originalPath, maxBytes),
    maxSide: maxSide,
  ),
  decodeBudget,
);

/// Reads the file at [path], or throws [ImageDecodeFailure] without reading
/// when it holds more than [maxBytes]. Bytes appended after the length was
/// taken are not read.
Uint8List _readOriginalSync(String path, int maxBytes) {
  final file = File(path).openSync();
  try {
    final length = file.lengthSync();
    if (length > maxBytes) throw const ImageDecodeFailure();
    return file.readSync(length);
  } finally {
    file.closeSync();
  }
}

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
