import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/export/pdf_export.dart';
import 'package:x_scanner/imaging/isolate_budget.dart';
import 'package:x_scanner/imaging/page_render.dart';

const _generator = 'x-scanner-geometric-v1';
const _seed = 20261016;
const _maxManifestBytes = 64 * 1024;
const _maxJpegSide = 65535;

typedef _Corpus = ({
  int width,
  int height,
  List<String> originals,
  String manifestSha256,
});

/// Runs the local corpus/host benchmark CLI and returns its exit status.
Future<int> runBenchmark(
  List<String> arguments, {
  required StringSink output,
  required StringSink errors,
}) async {
  try {
    switch (arguments) {
      case ['generate', final path, final width, final height, final pages]:
        final w = int.tryParse(width);
        final h = int.tryParse(height);
        final count = int.tryParse(pages);
        if (!_validDimensions(w, h, count)) return _usage(errors);
        await _generate(path, w!, h!, count!);
      case [final stage, final path, final appSha]
          when stage == 'thumbnail' || stage == 'render-pdf':
        if (!_hex(appSha, 40)) return _usage(errors);
        final corpus = await _loadCorpus(path);
        // Run from apps/mobile: the lock hash identifies the actual pinned
        // dependencies without stale version constants in this tool.
        final lockHash = await _sha256(
          _readBounded('pubspec.lock', _maxManifestBytes),
        );
        final measurement = await _measure(corpus, stage);
        output.writeln(
          jsonEncode({
            'schemaVersion': 1,
            'appSha': appSha,
            'fixtureId':
                '$_generator-${corpus.width}x${corpus.height}-${corpus.originals.length}',
            'fixtureSha256': corpus.manifestSha256,
            'width': corpus.width,
            'height': corpus.height,
            'pageCount': corpus.originals.length,
            'host': {
              'os': Platform.operatingSystem,
              'architecture': Abi.current().toString(),
            },
            'runtime': {
              'name': 'Dart',
              'version': Platform.version.split(' ').first,
            },
            'buildMode': 'host-dart',
            'engines': {
              'thumbnailCore': 'lib/imaging/page_render.dart#thumbnail',
              'renderCore': 'lib/imaging/page_render.dart#renderPage',
              'pdfCore': 'lib/export/pdf_export.dart#buildPdf',
              'pubspecLockSha256': lockHash,
              'imageVersion': null,
              'pdfVersion': null,
            },
            'recipeRevision': 0,
            'stage': stage,
            ...measurement,
            'peakProcessRssBytes': ProcessInfo.maxRss,
            'currentRssBytes': ProcessInfo.currentRss,
            'cancelLatencyMs': null,
            'ioCache': 'uncontrolled',
            'rssScope': 'process-lifetime-including-setup',
            'outcome': 'success',
          }),
        );
      default:
        return _usage(errors);
    }
    return 0;
  } catch (_) {
    // Filesystem, decoder and process exceptions can carry private paths.
    errors.writeln('scanner-benchmark: benchmark failed');
    return 1;
  }
}

int _usage(StringSink errors) {
  errors.writeln('scanner-benchmark: invalid arguments');
  return 2;
}

bool _hex(String value, int length) =>
    value.length == length && RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);

bool _validDimensions(int? width, int? height, int? pages) =>
    width != null &&
    height != null &&
    pages != null &&
    width > 0 &&
    height > 0 &&
    width <= _maxJpegSide &&
    height <= _maxJpegSide &&
    pages >= 1 &&
    pages <= 100 &&
    // Divide before multiplying: a huge input must not wrap into the budget.
    width <= maxDecodedPixels ~/ height;

String _pageName(int index) =>
    'page-${(index + 1).toString().padLeft(3, '0')}.jpg';

Future<void> _generate(String path, int width, int height, int count) async {
  // Directory.create accepts an already existing directory. mkdir without -p
  // claims the new path atomically, also refusing files and dangling links.
  final mkdir = await Process.run('mkdir', ['--', path]);
  if (mkdir.exitCode != 0) throw const FileSystemException();
  final pages = <Map<String, String>>[];
  for (var index = 0; index < count; index++) {
    final marker = (index + _seed) % 108;
    final image = img.Image(width: width, height: height, numChannels: 3)
      ..clear(
        img.ColorRgb8(
          (marker % 6) * 51,
          ((marker ~/ 6) % 6) * 51,
          (marker ~/ 36) * 102,
        ),
      );
    if (width >= 8 && height >= 8) {
      img.fillRect(
        image,
        x1: width ~/ 8,
        y1: height ~/ 8,
        x2: width * 7 ~/ 8,
        y2: height * 7 ~/ 8,
        color: img.ColorRgb8(240, 240, 240),
      );
      img.fillRect(
        image,
        x1: width ~/ 4,
        y1: height ~/ 4,
        x2: width ~/ 2,
        y2: height * 3 ~/ 4,
        color: img.ColorRgb8(20, 20, 20),
      );
    }
    final bytes = img.encodeJpg(image, quality: 90);
    if (bytes.length > maxOriginalBytes) throw const ImageDecodeFailure();
    final name = _pageName(index);
    await _writeNew('$path/$name', bytes);
    pages.add({'file': name, 'sha256': await _sha256(bytes)});
  }
  // Write the complete manifest last. A failed generation leaves its partial
  // directory intact; a later command never deletes it or retries over it.
  await _writeNew(
    '$path/manifest.json',
    utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'generator': _generator,
        'seed': _seed,
        'width': width,
        'height': height,
        'pageCount': count,
        'pages': pages,
      }),
    ),
  );
}

Future<void> _writeNew(String path, List<int> bytes) async {
  final file = await File(path).create(exclusive: true);
  await file.writeAsBytes(bytes, flush: true);
}

/// Reads at most the length checked on the opened handle, never a growing
/// readAsBytes allocation. Inputs must be regular files, including manifests.
Uint8List _readBounded(String path, int maxBytes) {
  if (FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw const FileSystemException();
  }
  final file = File(path).openSync();
  try {
    final length = file.lengthSync();
    if (length > maxBytes) throw const ImageDecodeFailure();
    final bytes = file.readSync(length);
    if (bytes.length != length) throw const ImageDecodeFailure();
    return bytes;
  } finally {
    file.closeSync();
  }
}

/// Hash only the bounded bytes already read, through stdin. No shell is used;
/// filenames (including newlines/backslashes) never enter checksum output.
Future<String> _sha256(List<int> bytes) async {
  final process = await Process.start('sha256sum', ['--zero']);
  final output = process.stdout.transform(ascii.decoder).join();
  final errors = process.stderr.drain<void>();
  try {
    process.stdin.add(bytes);
    await process.stdin.close();
    final result = await output;
    await errors;
    if (await process.exitCode != 0 ||
        result.length != 68 ||
        !result.endsWith('  -\u0000')) {
      throw const ProcessException('sha256sum', ['--zero']);
    }
    final hash = result.substring(0, 64);
    if (!_hex(hash, 64)) throw const FormatException();
    return hash.toLowerCase();
  } catch (_) {
    process.kill();
    rethrow;
  }
}

Future<_Corpus> _loadCorpus(String path) async {
  if (FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const FileSystemException();
  }
  final bytes = _readBounded('$path/manifest.json', _maxManifestBytes);
  final manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final width = manifest['width'] as int?;
  final height = manifest['height'] as int?;
  final count = manifest['pageCount'] as int?;
  if (manifest.length != 7 ||
      manifest['schemaVersion'] != 1 ||
      manifest['generator'] != _generator ||
      manifest['seed'] != _seed ||
      !_validDimensions(width, height, count)) {
    throw const FormatException();
  }
  final pages = manifest['pages'] as List<dynamic>;
  if (pages.length != count) throw const FormatException();
  final originals = <String>[];
  for (var index = 0; index < pages.length; index++) {
    final page = pages[index] as Map<String, dynamic>;
    final hash = page['sha256'] as String;
    final name = _pageName(index);
    if (page.length != 2 || page['file'] != name || !_hex(hash, 64)) {
      throw const FormatException();
    }
    final original = '$path/$name';
    final data = _readBounded(original, maxOriginalBytes);
    if (await _sha256(data) != hash.toLowerCase()) {
      throw const FormatException();
    }
    // Even a header parser can face malformed input. Keep type/dimension
    // probing inside the same killable budget used by the production decoder.
    await runWithinBudget(() {
      if (data.length < 3 ||
          data[0] != 0xff ||
          data[1] != 0xd8 ||
          data[2] != 0xff) {
        throw const ImageDecodeFailure();
      }
      final size = imageSizeOf(data);
      if (size == null || size.width != width || size.height != height) {
        throw const ImageDecodeFailure();
      }
      return true;
    }, decodeBudget);
    originals.add(original);
  }
  return (
    width: width!,
    height: height!,
    originals: originals,
    manifestSha256: await _sha256(bytes),
  );
}

double _milliseconds(Stopwatch watch) => watch.elapsedMicroseconds / 1000;

Future<Uint8List> _package(List<Uint8List> images) =>
    Isolate.run(() => buildPdf(images));

Future<Map<String, Object?>> _measure(_Corpus corpus, String stage) async {
  final duration = Stopwatch()..start();
  final render = Stopwatch();
  var outputBytes = 0;
  if (stage == 'thumbnail') {
    render.start();
    for (final original in corpus.originals) {
      outputBytes += (await thumbnail(original)).length;
    }
    render.stop();
    duration.stop();
    return {
      'durationMs': _milliseconds(duration),
      'renderDurationMs': _milliseconds(render),
      'packageDurationMs': null,
      'writeDurationMs': null,
      'outputBytes': outputBytes,
    };
  }
  final temporary = await Directory.systemTemp.createTemp(
    'x_scanner_benchmark_',
  );
  try {
    final images = <Uint8List>[];
    render.start();
    // Each render returns its own full-resolution JPEG. Retain those separate
    // buffers for buildPdf, matching the app's current export memory behavior.
    for (final original in corpus.originals) {
      images.add(await renderPage(original, PageQuad.fullFrame, 0));
    }
    render.stop();
    final package = Stopwatch()..start();
    final pdf = await _package(images);
    package.stop();
    final write = Stopwatch()..start();
    await File('${temporary.path}/benchmark.pdf')
        .writeAsBytes(pdf, flush: true);
    write.stop();
    duration.stop();
    return {
      'durationMs': _milliseconds(duration),
      'renderDurationMs': _milliseconds(render),
      'packageDurationMs': _milliseconds(package),
      'writeDurationMs': _milliseconds(write),
      'outputBytes': pdf.length,
    };
  } finally {
    // Only the unique directory created by this invocation belongs to us.
    await temporary.delete(recursive: true);
  }
}

Future<void> main(List<String> arguments) async {
  exitCode = await runBenchmark(arguments, output: stdout, errors: stderr);
}
