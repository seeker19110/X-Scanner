import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/scanner_benchmark.dart';

const appSha = '0123456789abcdef0123456789abcdef01234567';
const generator = 'x-scanner-geometric-v1';
const seed = 20261016;

typedef CliResult = ({int code, String output, String errors});

Future<CliResult> invoke(List<String> arguments) async {
  final output = StringBuffer();
  final errors = StringBuffer();
  final code = await runBenchmark(arguments, output: output, errors: errors);
  return (code: code, output: output.toString(), errors: errors.toString());
}

Directory temporaryDirectory() {
  final directory = Directory.systemTemp.createTempSync('scanner_benchmark_');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

Future<String> sha256(File file) async {
  final result = await Process.run('sha256sum', ['--zero', '--', file.path]);
  expect(result.exitCode, 0);
  return (result.stdout as String).substring(0, 64);
}

Map<String, dynamic> manifestOf(Directory corpus) =>
    jsonDecode(File('${corpus.path}/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

void writeManifest(Directory corpus, Map<String, dynamic> manifest) {
  File('${corpus.path}/manifest.json').writeAsStringSync(jsonEncode(manifest));
}

/// Independent tiny fixture for preflight and production-core integration.
Future<Directory> validCorpus(Directory parent) async {
  final corpus = Directory('${parent.path}/corpus')..createSync();
  final pages = <Map<String, String>>[];
  for (var page = 1; page <= 2; page++) {
    final image = img.Image(width: 32, height: 24, numChannels: 3)
      ..clear(img.ColorRgb8(30 * page, 80, 180));
    final name = 'page-${page.toString().padLeft(3, '0')}.jpg';
    final file = File('${corpus.path}/$name')
      ..writeAsBytesSync(img.encodeJpg(image, quality: 90));
    pages.add({'file': name, 'sha256': await sha256(file)});
  }
  writeManifest(corpus, {
    'schemaVersion': 1,
    'generator': generator,
    'seed': seed,
    'width': 32,
    'height': 24,
    'pageCount': 2,
    'pages': pages,
  });
  return corpus;
}

Future<void> expectRejected(Directory corpus) async {
  final result = await invoke(['thumbnail', corpus.path, appSha]);
  expect(result.code, 1);
  expect(result.output, isEmpty);
  expect(result.errors, 'scanner-benchmark: benchmark failed\n');
  expect(result.errors, isNot(contains(corpus.path)));
}

void main() {
  group('CLI validation', () {
    for (final arguments in <List<String>>[
      [],
      ['unknown'],
      ['generate'],
      ['generate', 'unused', '2', '2'],
      ['generate', 'unused', '2', '2', '1', 'extra'],
      ['thumbnail'],
      ['render-pdf', 'unused', appSha, 'extra'],
      ['thumbnail', 'unused', 'short'],
      ['render-pdf', 'unused', '${appSha}0'],
      ['thumbnail', 'unused', 'g' * 40],
      ['thumbnail', 'unused', '$appSha\n'],
    ]) {
      test('rejects invalid command shape ${arguments.join(' ')}', () async {
        final result = await invoke(arguments);
        expect(result.code, 2);
        expect(result.output, isEmpty);
        expect(result.errors, 'scanner-benchmark: invalid arguments\n');
      });
    }

    for (final dimensions in <List<String>>[
      ['0', '24', '1'],
      ['32', '-1', '1'],
      ['x', '24', '1'],
      ['32', '24', '0'],
      ['32', '24', '101'],
      ['65536', '1', '1'],
      ['1', '65536', '1'],
      ['10000', '5001', '1'],
      ['9223372036854775807', '9223372036854775807', '1'],
      ['18446744073709551616', '24', '1'],
    ]) {
      test(
        'rejects dimensions/pages $dimensions before creating a path',
        () async {
          final destination = '${temporaryDirectory().path}/must-not-exist';
          final result = await invoke(['generate', destination, ...dimensions]);
          expect(result.code, 2);
          expect(
            FileSystemEntity.typeSync(destination),
            FileSystemEntityType.notFound,
          );
        },
      );
    }

    test(
      'refuses an existing directory without changing its contents',
      () async {
        final existing = temporaryDirectory();
        final sentinel = File('${existing.path}/original')
          ..writeAsStringSync('keep');
        final result = await invoke([
          'generate',
          existing.path,
          '32',
          '24',
          '2',
        ]);
        expect(result.code, 1);
        expect(sentinel.readAsStringSync(), 'keep');
        expect(existing.listSync(), hasLength(1));
      },
    );

    test(
      'refuses an existing file and a dangling destination symlink',
      () async {
        final parent = temporaryDirectory();
        final file = File('${parent.path}/original')..writeAsStringSync('keep');
        final link = Link('${parent.path}/link')
          ..createSync('${parent.path}/absent');
        for (final destination in [file.path, link.path]) {
          expect(
            (await invoke(['generate', destination, '32', '24', '1'])).code,
            1,
          );
        }
        expect(file.readAsStringSync(), 'keep');
        expect(link.targetSync(), '${parent.path}/absent');
      },
    );
  });

  group('deterministic geometric corpus', () {
    test(
      'has stable manifest/checksums and different pages without private data',
      () async {
        final parent = temporaryDirectory();
        final first = Directory('${parent.path}/first');
        final second = Directory('${parent.path}/second');
        for (final corpus in [first, second]) {
          final result = await invoke([
            'generate',
            corpus.path,
            '32',
            '24',
            '2',
          ]);
          expect(result.code, 0);
          expect(result.errors, isEmpty);
          expect(result.output, isEmpty);
        }
        final manifest = manifestOf(first);
        expect(manifest, manifestOf(second));
        expect(manifest['schemaVersion'], 1);
        expect(manifest['generator'], generator);
        expect(manifest['seed'], seed);
        expect(
          [manifest['width'], manifest['height'], manifest['pageCount']],
          [32, 24, 2],
        );
        final pages = (manifest['pages'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(pages.map((page) => page['sha256']).toSet(), hasLength(2));
        for (var index = 0; index < pages.length; index++) {
          final name = 'page-${(index + 1).toString().padLeft(3, '0')}.jpg';
          expect(pages[index]['file'], name);
          final file = File('${first.path}/$name');
          expect(await sha256(file), pages[index]['sha256']);
          expect(
            file.readAsBytesSync(),
            File('${second.path}/$name').readAsBytesSync(),
          );
          final decoded = img.decodeJpg(file.readAsBytesSync())!;
          expect((decoded.width, decoded.height), (32, 24));
        }
        expect(jsonEncode(manifest), isNot(contains(parent.path)));
        expect(
          manifest.keys,
          unorderedEquals([
            'schemaVersion',
            'generator',
            'seed',
            'width',
            'height',
            'pageCount',
            'pages',
          ]),
        );
      },
    );

    test('even 100 one-pixel pages retain distinct JPEG checksums', () async {
      final corpus = Directory('${temporaryDirectory().path}/tiny');
      expect(
        (await invoke(['generate', corpus.path, '1', '1', '100'])).code,
        0,
      );
      final pages = (manifestOf(corpus)['pages'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(pages.map((page) => page['sha256']).toSet(), hasLength(100));
    });
  });

  group('bounded checksum preflight', () {
    test('rejects a changed valid JPEG with the old checksum', () async {
      final corpus = await validCorpus(temporaryDirectory());
      final originalHash =
          ((manifestOf(corpus)['pages'] as List<dynamic>).first
              as Map<String, dynamic>)['sha256'];
      final changed = img.Image(width: 32, height: 24, numChannels: 3)
        ..clear(img.ColorRgb8(240, 20, 50));
      final file = File('${corpus.path}/page-001.jpg')
        ..writeAsBytesSync(img.encodeJpg(changed, quality: 90));
      final decoded = img.decodeJpg(file.readAsBytesSync())!;
      expect((decoded.width, decoded.height), (32, 24));
      expect(await sha256(file), isNot(originalHash));
      await expectRejected(corpus);
    });

    test('rejects actual JPEG dimensions that differ from the manifest, '
        'even when its checksum is correct', () async {
      final corpus = await validCorpus(temporaryDirectory());
      final changed = img.Image(width: 33, height: 24, numChannels: 3)
        ..clear(img.ColorRgb8(30, 80, 180));
      final file = File('${corpus.path}/page-001.jpg')
        ..writeAsBytesSync(img.encodeJpg(changed, quality: 90));
      final manifest = manifestOf(corpus);
      final pages = (manifest['pages'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      pages.first['sha256'] = await sha256(file);
      writeManifest(corpus, manifest);
      expect(pages.first['sha256'], await sha256(file));
      final decoded = img.decodeJpg(file.readAsBytesSync())!;
      expect((decoded.width, decoded.height), (33, 24));
      expect((manifest['width'], manifest['height']), (32, 24));
      await expectRejected(corpus);
    });

    for (final mutation in [
      'schema',
      'generator',
      'seed',
      'count',
      'dimensions',
      'traversal',
      'duplicate',
      'checksum',
      'filename',
    ]) {
      test('rejects invalid manifest $mutation', () async {
        final corpus = await validCorpus(temporaryDirectory());
        final manifest = manifestOf(corpus);
        final pages = (manifest['pages'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        switch (mutation) {
          case 'schema':
            manifest['schemaVersion'] = 2;
          case 'generator':
            manifest['generator'] = 'other';
          case 'seed':
            manifest['seed'] = 0;
          case 'count':
            manifest['pageCount'] = 3;
          case 'dimensions':
            manifest['width'] = 9223372036854775807;
          case 'traversal':
            pages[0]['file'] = '../private.jpg';
          case 'duplicate':
            pages[1]['file'] = pages[0]['file'];
          case 'checksum':
            pages[0]['sha256'] = 'invalid';
          case 'filename':
            pages[0]['file'] = 'renamed.jpg';
        }
        writeManifest(corpus, manifest);
        await expectRejected(corpus);
      });
    }

    test('rejects a partial corpus with no completed manifest', () async {
      final corpus = temporaryDirectory();
      File('${corpus.path}/page-001.jpg').writeAsBytesSync([1, 2, 3]);
      await expectRejected(corpus);
    });

    test('rejects an oversized manifest before reading its contents', () async {
      final corpus = temporaryDirectory();
      final file = File('${corpus.path}/manifest.json')
          .openSync(mode: FileMode.write);
      file.truncateSync(64 * 1024 + 1);
      file.closeSync();
      await expectRejected(corpus);
    });

    test('rejects an oversized original before hashing or decoding', () async {
      final corpus = await validCorpus(temporaryDirectory());
      final file = File('${corpus.path}/page-001.jpg')
          .openSync(mode: FileMode.write);
      file.truncateSync(64 * 1024 * 1024 + 1);
      file.closeSync();
      await expectRejected(corpus);
    });

    for (final target in ['directory', 'manifest', 'original']) {
      test('rejects a symlink $target without deleting its target', () async {
        final parent = temporaryDirectory();
        final corpus = await validCorpus(parent);
        if (target == 'directory') {
          final link = Link('${parent.path}/linked')..createSync(corpus.path);
          await expectRejected(Directory(link.path));
        } else {
          final name = target == 'manifest' ? 'manifest.json' : 'page-001.jpg';
          final file = File('${corpus.path}/$name');
          final moved = file.renameSync('${parent.path}/private-$name');
          Link(file.path).createSync(moved.path);
          await expectRejected(corpus);
          expect(moved.existsSync(), isTrue);
        }
        expect(corpus.existsSync(), isTrue);
      });
    }

    test(
      'works with newline/backslash in the corpus path (sha256sum --zero)',
      () async {
        final parent = Directory('${temporaryDirectory().path}/line\nslash\\')
          ..createSync();
        final corpus = await validCorpus(parent);
        final result = await invoke(['thumbnail', corpus.path, appSha]);
        expect(result.code, 0);
        expect(result.errors, isEmpty);
        expect(jsonDecode(result.output), isA<Map<String, dynamic>>());
      },
    );
  });

  group('production core measurements', () {
    for (final stage in ['thumbnail', 'render-pdf']) {
      test(
        '$stage reports real output/metadata and preserves every input',
        () async {
          final corpus = await validCorpus(temporaryDirectory());
          final before = <String, String>{};
          for (final file in corpus.listSync().cast<File>()) {
            before[file.path] = await sha256(file);
          }
          final result = await invoke([stage, corpus.path, appSha]);
          expect(result.code, 0);
          expect(result.errors, isEmpty);
          final record = jsonDecode(result.output) as Map<String, dynamic>;
          expect(record['schemaVersion'], 1);
          expect(record['appSha'], appSha);
          expect(record['fixtureId'], 'x-scanner-geometric-v1-32x24-2');
          expect(
            record['fixtureSha256'],
            before['${corpus.path}/manifest.json'],
          );
          expect(
            [record['width'], record['height'], record['pageCount']],
            [32, 24, 2],
          );
          expect(record['stage'], stage);
          expect(record['buildMode'], 'host-dart');
          expect(record['recipeRevision'], 0);
          expect(record['outcome'], 'success');
          expect(record['durationMs'], isNonNegative);
          expect(record['renderDurationMs'], isNonNegative);
          expect(
            record['packageDurationMs'],
            stage == 'thumbnail' ? isNull : isNonNegative,
          );
          expect(
            record['writeDurationMs'],
            stage == 'thumbnail' ? isNull : isNonNegative,
          );
          expect(record['outputBytes'], greaterThan(0));
          expect(record['peakProcessRssBytes'], greaterThan(0));
          expect(record['currentRssBytes'], greaterThan(0));
          expect(record['cancelLatencyMs'], isNull);
          expect(record['ioCache'], 'uncontrolled');
          expect(record['rssScope'], 'process-lifetime-including-setup');
          final engines = record['engines'] as Map<String, dynamic>;
          expect(
            engines['pubspecLockSha256'],
            await sha256(File('pubspec.lock')),
          );
          expect(engines['imageVersion'], isNull);
          expect(engines['pdfVersion'], isNull);
          expect(
            engines['thumbnailCore'],
            'lib/imaging/page_render.dart#thumbnail',
          );
          expect(
            engines['renderCore'],
            'lib/imaging/page_render.dart#renderPage',
          );
          expect(engines['pdfCore'], 'lib/export/pdf_export.dart#buildPdf');
          final host = record['host'] as Map<String, dynamic>;
          expect(host['os'], Platform.operatingSystem);
          expect(host['architecture'], isNotEmpty);
          expect(record['runtime'], isA<Map<String, dynamic>>());
          expect(result.output, isNot(contains(corpus.path)));
          expect(result.output, isNot(contains(Platform.localHostname)));
          expect(corpus.listSync(), hasLength(3));
          for (final entry in before.entries) {
            expect(await sha256(File(entry.key)), entry.value);
          }
        },
      );
    }

    test(
      'filesystem failures have a fixed error with no path/details',
      () async {
        final missing = '${temporaryDirectory().path}/private-missing.jpg';
        final result = await invoke(['render-pdf', missing, appSha]);
        expect(result.code, 1);
        expect(result.output, isEmpty);
        expect(result.errors, 'scanner-benchmark: benchmark failed\n');
      },
    );
  });
}
