import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/storage/session_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/session_controller.dart';

/// Scripted [PageSource]: each call takes the next queued result;
/// [discarded] records every [discard] call, which also runs [onDiscard].
class FakeSource implements PageSource {
  final List<String> discarded = [];
  void Function(String path)? onDiscard;
  final List<String?> captures = [];
  final List<String?> gallery = [];
  final List<String?> lost = [];

  @override
  Future<String?> capture() async => captures.removeAt(0);

  @override
  Future<String?> pickFromGallery() async => gallery.removeAt(0);

  @override
  Future<String?> retrieveLost() async =>
      lost.isEmpty ? null : lost.removeAt(0);

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
    onDiscard?.call(path);
  }
}

/// [SessionStore] whose [save] can be made to fail like a full disk and
/// whose [load] like an unreadable disk.
class FlakyStore extends SessionStore {
  FlakyStore(super.root);

  bool failSave = false;
  bool failLoad = false;

  @override
  Future<SessionLoadResult> load() => failLoad
      ? Future<SessionLoadResult>.error(const FileSystemException('io'))
      : super.load();

  @override
  Future<void> save(session) => failSave
      ? Future<void>.error(const FileSystemException('disk full'))
      : super.save(session);
}

/// [FileSharer] that records what it was given and can be made to fail.
class FakeSharer implements FileSharer {
  final List<List<String>> shared = [];

  /// Names of the shared files that existed while sharing.
  final List<List<String>> existing = [];
  bool fail = false;

  @override
  Future<void> share(List<File> files) async {
    shared.add([for (final f in files) f.path.split('/').last]);
    existing.add([
      for (final f in files)
        if (f.existsSync()) f.path.split('/').last,
    ]);
    if (fail) throw StateError('share failed');
  }
}

void main() {
  late Directory tmp;
  late Directory root;
  late Directory picks;
  late FlakyStore store;
  late FakeSource source;
  late Directory exports;
  late PageExporter exporter;
  late FakeSharer sharer;
  late SessionController controller;
  var n = 0;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('session_controller_test');
    root = Directory('${tmp.path}/session')..createSync();
    picks = Directory('${tmp.path}/picks')..createSync();
    store = FlakyStore(root);
    source = FakeSource();
    exports = Directory('${tmp.path}/exports');
    exporter = PageExporter(
      exportDir: exports,
      leftoverDirs: [Directory('${tmp.path}/share_plus')],
    );
    sharer = FakeSharer();
    controller = SessionController(
      store: store,
      source: source,
      exporter: exporter,
      sharer: sharer,
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Writes a synthetic PNG of a unique size and returns its path.
  String png({String name = ''}) {
    n++;
    final image = img.Image(width: 4 + n, height: 3 + n);
    img.fill(image, color: img.ColorRgb8(n * 20 % 256, 40, 90));
    final file = File('${picks.path}/${name.isEmpty ? 'p$n.png' : name}')
      ..writeAsBytesSync(img.encodePng(image));
    return file.path;
  }

  String garbage() => (File(
    '${picks.path}/junk${++n}.jpg',
  )..writeAsBytesSync(List<int>.generate(64, (i) => i))).path;

  List<Object?> manifestPages() {
    final json = jsonDecode(
      File('${root.path}/session.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return json['pages']! as List<Object?>;
  }

  List<String> ids() => [for (final p in controller.session.pages) p.id];

  Future<void> addPages(int count) async {
    for (var i = 0; i < count; i++) {
      source.captures.add(png());
      await controller.capture();
    }
  }

  test('cancelled capture adds no page and no notice (AC-7)', () async {
    source.captures.add(null);
    source.gallery.add(null);
    await controller.capture();
    await controller.importFromGallery();
    expect(controller.session.pages, isEmpty);
    expect(controller.takeNotice(), isNull);
    expect(controller.busy, isFalse);
    expect(File('${root.path}/session.json').existsSync(), isFalse);
  });

  test(
    'undecodable image reports decodeFailed and keeps pages (AC-7)',
    () async {
      await addPages(1);
      final before = controller.session;
      final original = controller.originalFile(before.pages.single);
      final bytes = original.readAsBytesSync();

      source.gallery.add(garbage());
      await controller.importFromGallery();

      expect(controller.takeNotice(), SessionNotice.decodeFailed);
      expect(controller.takeNotice(), isNull);
      expect(controller.session, same(before));
      expect(original.readAsBytesSync(), bytes);
      expect(manifestPages(), hasLength(1));
      expect(Directory('${root.path}/originals').listSync(), hasLength(1));
    },
  );

  test('two valid pages are added and saved in order', () async {
    final first = png();
    final second = png();
    source.captures.add(first);
    source.gallery.add(second);
    await controller.capture();
    await controller.importFromGallery();

    final pages = controller.session.pages;
    expect(pages, hasLength(2));
    expect(manifestPages(), hasLength(2));
    expect(
      controller.originalFile(pages[0]).readAsBytesSync(),
      File(first).readAsBytesSync(),
    );
    expect(
      controller.originalFile(pages[1]).readAsBytesSync(),
      File(second).readAsBytesSync(),
    );
    expect(pages[0].originalPath, 'originals/${pages[0].id}.png');
    expect(controller.takeNotice(), isNull);
    expect(File(first).existsSync(), isTrue, reason: 'source untouched');
  });

  test('two captures started together finish in call order', () async {
    final first = png();
    final second = png();
    source.captures.addAll([first, second]);
    final a = controller.capture();
    final b = controller.capture();
    expect(controller.busy, isTrue);
    await Future.wait([a, b]);

    final pages = controller.session.pages;
    expect(pages, hasLength(2));
    expect(
      controller.originalFile(pages[0]).readAsBytesSync(),
      File(first).readAsBytesSync(),
    );
    expect(
      controller.originalFile(pages[1]).readAsBytesSync(),
      File(second).readAsBytesSync(),
    );
    expect(controller.busy, isFalse);
  });

  test('extension comes from the file name, else jpg', () async {
    source.captures.addAll([
      png(name: 'IMG_1.JPEG'),
      png(name: 'noext'),
      png(name: 'a.toolong'),
      png(name: 'b.p-g'),
    ]);
    for (var i = 0; i < 4; i++) {
      await controller.capture();
    }
    expect(
      [
        for (final p in controller.session.pages)
          p.originalPath.split('.').last,
      ],
      ['jpeg', 'jpg', 'jpg', 'jpg'],
    );
  });

  test('restore loads the saved session', () async {
    await addPages(2);
    final saved = ids();
    final other = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: exporter,
      sharer: sharer,
    );
    await other.restore();
    expect([for (final p in other.session.pages) p.id], saved);
    expect(other.takeNotice(), isNull);
  });

  test('restore on a corrupt manifest gives an empty session and '
      'restoreFailed', () async {
    File('${root.path}/session.json').writeAsStringSync('{not json');
    await controller.restore();
    expect(controller.session.pages, isEmpty);
    expect(controller.takeNotice(), SessionNotice.restoreFailed);
  });

  test('(F-001) restore failing with an I/O error, then capture, keeps the '
      'saved session', () async {
    await addPages(2);
    final manifest = File('${root.path}/session.json');
    final onDisk = manifest.readAsBytesSync();
    final originals = Directory('${root.path}/originals')
        .listSync()
        .map((e) => e.path)
        .toList();

    final failing = FlakyStore(root)..failLoad = true;
    final other = SessionController(
      store: failing,
      source: source,
      exporter: exporter,
      sharer: sharer,
    );
    await other.restore();
    expect(other.takeNotice(), SessionNotice.restoreFailed);
    final before = other.session;

    source.captures.add(png());
    await other.capture();
    expect(other.takeNotice(), SessionNotice.saveFailed);
    expect(other.session, same(before));
    expect(manifest.readAsBytesSync(), onDisk);
    for (final path in originals) {
      expect(File(path).existsSync(), isTrue);
    }
  });

  test('restore adds a photo recovered after the app was killed', () async {
    source.lost.add(png());
    await controller.restore();
    expect(controller.session.pages, hasLength(1));
    expect(manifestPages(), hasLength(1));
    expect(controller.takeNotice(), isNull);
  });

  test('a failed save reports saveFailed and keeps the session', () async {
    await addPages(2);
    final before = controller.session;
    final onDisk = manifestPages();
    store.failSave = true;

    source.captures.add(png());
    await controller.capture();
    expect(controller.takeNotice(), SessionNotice.saveFailed);
    expect(controller.session, same(before));

    await controller.remove(before.pages.first.id);
    await controller.move(0, 1);
    await controller.updatePage(before.pages.first.rotatedClockwise());
    await controller.clearAll();
    source.captures.add(png());
    await controller.retake(before.pages.first.id);
    for (var i = 0; i < 5; i++) {
      expect(controller.takeNotice(), SessionNotice.saveFailed);
    }
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(manifestPages(), onDisk);
    expect(controller.busy, isFalse);
  });

  test('move, remove, updatePage, retake and clearAll update the session '
      'and the manifest', () async {
    await addPages(3);
    final [a, b, c] = ids();

    await controller.move(2, 0);
    expect(ids(), [c, a, b]);
    expect([for (final p in manifestPages()) (p! as Map)['id']], [c, a, b]);

    await controller.remove(a);
    expect(ids(), [c, b]);
    expect(manifestPages(), hasLength(2));

    final quad = PageQuad(
      topLeft: const Point<double>(0.1, 0.1),
      topRight: const Point<double>(0.9, 0.1),
      bottomRight: const Point<double>(0.9, 0.9),
      bottomLeft: const Point<double>(0.1, 0.9),
    );
    final edited = controller.session.pages[1]
        .withQuad(quad)
        .rotatedClockwise();
    await controller.updatePage(edited);
    expect(controller.session.pages[1].quad, quad);
    expect(controller.session.pages[1].quarterTurns, 1);
    expect((manifestPages()[1]! as Map)['quarterTurns'], 1);

    final oldOriginal = controller.originalFile(controller.session.pages[1]);
    final retakePath = png();
    source.captures.add(retakePath);
    await controller.retake(b);
    final retaken = controller.session.pages[1];
    expect(retaken.id, isNot(b));
    expect(ids(), [c, retaken.id]);
    expect(retaken.quad, PageQuad.fullFrame);
    expect(retaken.quarterTurns, 0);
    expect(
      controller.originalFile(retaken).readAsBytesSync(),
      File(retakePath).readAsBytesSync(),
    );
    expect(oldOriginal.existsSync(), isFalse);
    expect((manifestPages()[1]! as Map)['id'], retaken.id);

    await controller.clearAll();
    expect(controller.session.pages, isEmpty);
    expect(manifestPages(), isEmpty);
    expect(controller.takeNotice(), isNull);
  });

  group('picker copy is discarded only after the page is saved (F-005)', () {
    /// Records the number of saved pages each time [FakeSource.discard]
    /// runs, so a test can tell the call came after the save.
    List<int> savedPagesAtDiscard() {
      final counts = <int>[];
      source.onDiscard = (_) => counts.add(manifestPages().length);
      return counts;
    }

    test('capture (F-005)', () async {
      final counts = savedPagesAtDiscard();
      final path = png();
      source.captures.add(path);
      await controller.capture();
      expect(source.discarded, [path]);
      expect(counts, [1]);
    });

    test('import from the photo picker (F-005)', () async {
      final counts = savedPagesAtDiscard();
      final path = png();
      source.gallery.add(path);
      await controller.importFromGallery();
      expect(source.discarded, [path]);
      expect(counts, [1]);
    });

    test('retake (F-005)', () async {
      await addPages(1);
      source.discarded.clear();
      final page = controller.session.pages.single;
      final counts = <String>[];
      source.onDiscard = (_) =>
          counts.add((manifestPages().single! as Map)['id']! as String);
      final path = png();
      source.captures.add(path);
      await controller.retake(page.id);
      expect(source.discarded, [path]);
      expect(counts, [controller.session.pages.single.id]);
      expect(counts.single, isNot(page.id));
    });

    test('photo recovered on restore (F-005)', () async {
      final counts = savedPagesAtDiscard();
      final path = png();
      source.lost.add(path);
      await controller.restore();
      expect(source.discarded, [path]);
      expect(counts, [1]);
    });

    test('an undecodable image is not discarded (F-005)', () async {
      source.captures.add(garbage());
      source.gallery.add(garbage());
      await controller.capture();
      await controller.importFromGallery();
      expect(controller.takeNotice(), SessionNotice.decodeFailed);
      expect(controller.takeNotice(), SessionNotice.decodeFailed);
      expect(source.discarded, isEmpty);
    });

    test('a failed save does not discard the source image (F-005)', () async {
      await addPages(1);
      source.discarded.clear();
      store.failSave = true;
      final path = png();
      source.captures.add(path);
      source.gallery.add(png());
      source.captures.add(png());
      await controller.capture();
      await controller.importFromGallery();
      await controller.retake(controller.session.pages.single.id);
      for (var i = 0; i < 3; i++) {
        expect(controller.takeNotice(), SessionNotice.saveFailed);
      }
      expect(source.discarded, isEmpty);
      expect(File(path).existsSync(), isTrue);
    });
  });

  test('cancelled retake keeps the page', () async {
    await addPages(1);
    final before = controller.session;
    source.captures.add(null);
    await controller.retake(before.pages.single.id);
    expect(controller.session, same(before));
    expect(controller.takeNotice(), isNull);
  });

  test('thumbnails are cached per page and generated one at a time', () async {
    var active = 0;
    var maxActive = 0;
    var calls = 0;
    final c = SessionController(
      store: store,
      source: source,
      exporter: exporter,
      sharer: sharer,
      thumbnailer: (path) async {
        calls++;
        active++;
        maxActive = max(maxActive, active);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return Uint8List.fromList(utf8.encode(path.split('/').last));
      },
    );
    for (var i = 0; i < 3; i++) {
      source.captures.add(png());
      await c.capture();
    }
    expect(calls, 3, reason: 'one decode check per added page');

    // A fresh controller has an empty cache.
    final d = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: exporter,
      sharer: sharer,
      thumbnailer: (path) async {
        calls++;
        active++;
        maxActive = max(maxActive, active);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return Uint8List.fromList(utf8.encode(path.split('/').last));
      },
    );
    await d.restore();
    calls = 0;
    final results = await Future.wait([
      for (final p in d.session.pages) d.thumbnailFor(p),
    ]);
    expect(calls, 3);
    expect(maxActive, 1);
    expect(
      utf8.decode(results.first),
      d.session.pages.first.originalPath.split('/').last,
    );
    await d.thumbnailFor(d.session.pages.first);
    expect(calls, 3, reason: 'cached');

    // Pages added through a controller are cached without a second decode.
    calls = 0;
    await c.thumbnailFor(c.session.pages.last);
    expect(calls, 0);
  });

  test('a failing thumbnail is reported to the caller', () async {
    await addPages(1);
    final page = controller.session.pages.single;
    final other = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: exporter,
      sharer: sharer,
    );
    await other.restore();
    controller.originalFile(page).writeAsBytesSync([1, 2, 3]);
    await expectLater(
      other.thumbnailFor(other.session.pages.single),
      throwsA(isA<ImageDecodeFailure>()),
    );
  });

  test('exportAndShare shares the export, then removes it (FR-7)', () async {
    await addPages(2);
    final before = controller.session;
    final future = controller.exportAndShare(ExportFormat.pdf);
    expect(controller.busy, isTrue);
    await future;

    expect(sharer.shared, [
      ['X-Scanner.pdf'],
    ]);
    expect(sharer.existing, sharer.shared, reason: 'files exist while shared');
    expect(exports.existsSync(), isFalse);
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(controller.busy, isFalse);

    await controller.exportAndShare(ExportFormat.jpeg);
    expect(sharer.shared.last, [
      'X-Scanner-trang-01.jpg',
      'X-Scanner-trang-02.jpg',
    ]);
    expect(exports.existsSync(), isFalse);
  });

  test('a failed share reports exportFailed and keeps the session', () async {
    await addPages(2);
    final before = controller.session;
    final onDisk = manifestPages();
    final original = controller.originalFile(before.pages.first);
    final bytes = original.readAsBytesSync();
    sharer.fail = true;

    await controller.exportAndShare(ExportFormat.png);

    expect(sharer.shared, hasLength(1));
    expect(controller.takeNotice(), SessionNotice.exportFailed);
    expect(controller.takeNotice(), isNull);
    expect(exports.existsSync(), isFalse);
    expect(controller.session, same(before));
    expect(manifestPages(), onDisk);
    expect(original.readAsBytesSync(), bytes);
    expect(controller.busy, isFalse);
  });

  test('a failed export reports exportFailed without sharing', () async {
    await addPages(2);
    final before = controller.session;
    controller.originalFile(before.pages.last).writeAsBytesSync([1, 2, 3]);

    await controller.exportAndShare(ExportFormat.jpeg);

    expect(sharer.shared, isEmpty);
    expect(controller.takeNotice(), SessionNotice.exportFailed);
    expect(exports.existsSync(), isFalse);
    expect(controller.session, same(before));
  });

  test('exporting an empty session does nothing', () async {
    await controller.exportAndShare(ExportFormat.pdf);
    expect(sharer.shared, isEmpty);
    expect(controller.takeNotice(), isNull);
    expect(exports.existsSync(), isFalse);
    expect(controller.busy, isFalse);
  });

  test('restore removes export files left behind (FR-7)', () async {
    Directory('${exports.path}/old').createSync(recursive: true);
    File('${exports.path}/X-Scanner.pdf').writeAsStringSync('stale');
    final shareCopy = File('${tmp.path}/share_plus/X-Scanner.pdf')
      ..createSync(recursive: true);
    await controller.restore();
    expect(exports.existsSync(), isFalse);
    expect(shareCopy.existsSync(), isFalse);
    expect(controller.takeNotice(), isNull);
  });
}
