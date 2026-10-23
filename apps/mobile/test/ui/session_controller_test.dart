import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/export/export_job.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/imaging/decode_gate.dart';
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

/// [SessionStore] whose [save] can be made to fail like a full disk (or
/// with a [StateError]), whose [importOriginal] like a full disk and whose
/// [load] like an unreadable disk.
class FlakyStore extends SessionStore {
  FlakyStore(super.root);

  bool failSave = false;
  bool failSaveState = false;
  bool failImport = false;
  bool failLoad = false;

  @override
  Future<String> importOriginal(
    File source, {
    required String id,
    required String extension,
  }) => failImport
      ? Future<String>.error(const FileSystemException('disk full'))
      : super.importOriginal(source, id: id, extension: extension);

  @override
  Future<SessionLoadResult> load() => failLoad
      ? Future<SessionLoadResult>.error(const FileSystemException('io'))
      : super.load();

  @override
  Future<void> save(session) => failSave
      ? Future<void>.error(const FileSystemException('disk full'))
      : failSaveState
      ? Future<void>.error(StateError('original of a page is missing'))
      : super.save(session);
}

/// [FileSharer] that records what it was given and can be made to fail.
class FakeSharer implements FileSharer {
  final List<List<String>> shared = [];

  /// Names of the shared files that existed while sharing.
  final List<List<String>> existing = [];
  bool fail = false;

  /// Runs while sharing, before the share returns.
  void Function()? onShare;

  @override
  Future<void> share(List<File> files) async {
    onShare?.call();
    shared.add([for (final f in files) f.path.split('/').last]);
    existing.add([
      for (final f in files)
        if (f.existsSync()) f.path.split('/').last,
    ]);
    if (fail) throw StateError('share failed');
  }
}

/// Renderer returning a few bytes that waits at the 1-based calls in
/// `holds` until [release]; records the quarter turns of every call.
class HeldRenderer {
  HeldRenderer({Set<int> holds = const {}})
    : _holds = {for (final n in holds) n: Completer<void>()};

  final Map<int, Completer<void>> _holds;
  final Map<int, Completer<void>> _reached = {};
  final List<int> turns = [];

  /// Completes once call [n] has started.
  Future<void> reached(int n) =>
      _reached.putIfAbsent(n, Completer<void>.new).future;

  /// Lets call [n] return.
  void release(int n) => _holds[n]!.complete();

  Future<Uint8List> call(
    String path,
    PageQuad quad,
    int quarterTurns, {
    RenderFormat format = RenderFormat.jpeg,
  }) async {
    turns.add(quarterTurns);
    final n = turns.length;
    final reached = _reached.putIfAbsent(n, Completer<void>.new);
    if (!reached.isCompleted) reached.complete();
    await _holds[n]?.future;
    return Uint8List.fromList([1, 2, 3]);
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

  /// The saved manifest bytes and original file names, to show a failed
  /// add left the disk exactly as it was.
  ({List<int> manifest, List<String> originals}) disk() => (
    manifest: File('${root.path}/session.json').readAsBytesSync(),
    originals: [
      for (final e in Directory('${root.path}/originals').listSync())
        e.path.split('/').last,
    ]..sort(),
  );

  test('copying the original failing like a full disk reports saveFailed, '
      'keeps the session and the source image (F-010)', () async {
    await addPages(1);
    source.discarded.clear();
    final before = controller.session;
    final onDisk = disk();
    store.failImport = true;

    final captured = png();
    final picked = png();
    source.captures.add(captured);
    source.gallery.add(picked);
    await controller.capture();
    await controller.importFromGallery();

    expect(controller.takeNotice(), SessionNotice.saveFailed);
    expect(controller.takeNotice(), SessionNotice.saveFailed);
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(disk().manifest, onDisk.manifest);
    expect(disk().originals, onDisk.originals);
    expect(source.discarded, isEmpty);
    expect(File(captured).existsSync(), isTrue);
    expect(File(picked).existsSync(), isTrue);
    expect(controller.busy, isFalse);
  });

  test('an image in a format outside JPEG/PNG/WebP reports decodeFailed, '
      'keeps the pages and the picked file (W-104)', () async {
    await addPages(1);
    final before = controller.session;
    final bmp = File('${picks.path}/scan.jpg')
      ..writeAsBytesSync(img.encodeBmp(img.Image(width: 8, height: 6)));

    source.gallery.add(bmp.path);
    await controller.importFromGallery();

    expect(controller.takeNotice(), SessionNotice.decodeFailed);
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(manifestPages(), hasLength(1));
    expect(source.discarded, isNot(contains(bmp.path)));
    expect(bmp.existsSync(), isTrue);
  });

  test('a source file deleted before the decode check reports decodeFailed '
      'and keeps the session (F-028)', () async {
    await addPages(1);
    source.discarded.clear();
    final before = controller.session;
    final onDisk = disk();
    final gone = png();
    File(gone).deleteSync();

    source.captures.add(gone);
    await controller.capture();

    expect(controller.takeNotice(), SessionNotice.decodeFailed);
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(disk().manifest, onDisk.manifest);
    expect(disk().originals, onDisk.originals);
    expect(source.discarded, isEmpty);
  });

  test('(F-048) any other error of the decode check reports decodeFailed '
      'and keeps the session', () async {
    await addPages(1);
    source.discarded.clear();
    final before = controller.session;
    final onDisk = disk();
    final path = png();
    final other = SessionController(
      store: store,
      source: source,
      exporter: exporter,
      sharer: sharer,
      thumbnailer: (_) async => throw StateError('isolate failed'),
    );
    await other.restore();
    final restored = other.session;

    source.captures.add(path);
    await other.capture();

    expect(other.takeNotice(), SessionNotice.decodeFailed);
    expect(other.takeNotice(), isNull);
    expect(other.session, same(restored));
    expect(
      [for (final p in restored.pages) p.id],
      [for (final p in before.pages) p.id],
    );
    expect(disk().manifest, onDisk.manifest);
    expect(disk().originals, onDisk.originals);
    expect(source.discarded, isEmpty);
    expect(File(path).existsSync(), isTrue);
    expect(other.busy, isFalse);
  });

  test('save failing with a StateError reports saveFailed and keeps the '
      'session (F-028)', () async {
    await addPages(1);
    source.discarded.clear();
    final before = controller.session;
    final onDisk = disk();
    store.failSaveState = true;

    final path = png();
    source.captures.add(path);
    await controller.capture();
    await controller.remove(before.pages.single.id);

    expect(controller.takeNotice(), SessionNotice.saveFailed);
    expect(controller.takeNotice(), SessionNotice.saveFailed);
    expect(controller.takeNotice(), isNull);
    expect(controller.session, same(before));
    expect(disk().manifest, onDisk.manifest);
    expect(source.discarded, isEmpty);
    expect(File(path).existsSync(), isTrue);
  });

  test('an unreadable photo recovered on restore reports decodeFailed and '
      'keeps the restored session (F-028)', () async {
    await addPages(2);
    final saved = ids();
    final onDisk = disk();
    final lost = png();
    final other = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: exporter,
      sharer: sharer,
      thumbnailer: (path) => path == lost
          ? Future<Uint8List>.error(const ImageDecodeFailure())
          : thumbnail(path),
    );
    source.discarded.clear();
    source.lost.add(lost);

    await other.restore();

    expect(other.takeNotice(), SessionNotice.decodeFailed);
    expect(other.takeNotice(), isNull);
    expect([for (final p in other.session.pages) p.id], saved);
    expect(disk().manifest, onDisk.manifest);
    expect(disk().originals, onDisk.originals);
    expect(source.discarded, isEmpty);
    expect(File(lost).existsSync(), isTrue);
    // The restored session still works: its pages decode and edits save.
    await other.thumbnailFor(other.session.pages.first);
    await other.move(0, 1);
    expect([for (final p in other.session.pages) p.id], saved.reversed);
    expect(other.takeNotice(), isNull);
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
    expect(retaken.revision, 0);
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

  SessionController countingController(
    Future<Uint8List> Function(String path) thumbnailer,
  ) => SessionController(
    store: SessionStore(root),
    source: source,
    exporter: exporter,
    sharer: sharer,
    thumbnailer: thumbnailer,
  );

  test('(F-020) (F-047) a failed thumbnail is decoded again only after '
      'retryThumbnail', () async {
    await addPages(1);
    var calls = 0;
    var notified = 0;
    final other = countingController((path) async {
      calls++;
      if (calls == 1) throw const ImageDecodeFailure();
      return Uint8List.fromList([7]);
    });
    await other.restore();
    other.addListener(() => notified++);
    final page = other.session.pages.single;

    for (var i = 0; i < 2; i++) {
      await expectLater(
        other.thumbnailFor(page),
        throwsA(isA<ImageDecodeFailure>()),
      );
    }
    expect(calls, 1, reason: 'a failed preview stays cached');

    other.retryThumbnail(page);
    expect(notified, 1);
    expect(await other.thumbnailFor(page), [7]);
    expect(calls, 2);
    await other.thumbnailFor(page);
    expect(calls, 2, reason: 'a successful preview stays cached');
  });

  test(
    '(F-047) retryThumbnail keeps a running or successful preview',
    () async {
      await addPages(1);
      var calls = 0;
      var notified = 0;
      final hold = Completer<void>();
      final other = countingController((path) async {
        calls++;
        await hold.future;
        return Uint8List.fromList([9]);
      });
      await other.restore();
      other.addListener(() => notified++);
      final page = other.session.pages.single;

      // Never asked for yet: nothing to retry.
      other.retryThumbnail(page);
      final running = other.thumbnailFor(page);
      other.retryThumbnail(page);
      expect(other.thumbnailFor(page), same(running));

      hold.complete();
      expect(await running, [9]);
      other.retryThumbnail(page);
      expect(other.thumbnailFor(page), same(running));
      expect(calls, 1);
      expect(notified, 0);
    },
  );

  test('(F-047) restore forgets which previews failed', () async {
    await addPages(2);
    var fail = true;
    final other = countingController((path) async {
      if (fail) throw const ImageDecodeFailure();
      return Uint8List.fromList([5]);
    });
    await other.restore();
    final page = other.session.pages.first;
    await expectLater(
      other.thumbnailFor(page),
      throwsA(isA<ImageDecodeFailure>()),
    );
    fail = false;
    // Restoring again drops every cached preview, failed ones included, so
    // a later retry does not throw away the new preview.
    await other.restore();
    final fresh = other.thumbnailFor(other.session.pages.first);
    other.retryThumbnail(other.session.pages.first);
    expect(other.thumbnailFor(other.session.pages.first), same(fresh));
    expect(await fresh, [5]);
  });

  group('(XS-13)', () {
    final quad = PageQuad(
      topLeft: const Point<double>(0.1, 0.1),
      topRight: const Point<double>(0.9, 0.2),
      bottomRight: const Point<double>(0.8, 0.9),
      bottomLeft: const Point<double>(0.2, 0.8),
    );

    SessionController previewController({
      required Future<Uint8List> Function(String path) thumbnailer,
      required Future<Uint8List> Function(
        Uint8List thumbnail,
        PageQuad quad,
        int quarterTurns,
      )
      previewer,
      DecodeGate? decodeGate,
    }) => SessionController(
      store: SessionStore(root),
      source: source,
      exporter: exporter,
      sharer: sharer,
      thumbnailer: thumbnailer,
      previewer: previewer,
      decodeGate: decodeGate,
    );

    /// Lets queued futures run until [done] holds.
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 500 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(done(), isTrue);
    }

    test("cropped preview renders the thumbnail with the page's quad and "
        'turns (AC-1)', () async {
      await addPages(1);
      await controller.updatePage(
        controller.session.pages.single.withQuad(quad).rotatedClockwise(),
      );
      final calls = <(List<int>, PageQuad, int)>[];
      final other = previewController(
        thumbnailer: (_) async => Uint8List.fromList([1, 2, 3]),
        previewer: (thumb, q, turns) async {
          calls.add((thumb.toList(), q, turns));
          return Uint8List.fromList([9, 8]);
        },
      );
      await other.restore();
      final page = other.session.pages.single;

      expect(await other.croppedPreviewFor(page), [9, 8]);
      expect(calls, hasLength(1));
      final (thumb, usedQuad, turns) = calls.single;
      expect(thumb, [1, 2, 3]);
      expect(usedQuad, quad);
      expect(turns, 1);
      expect(await other.croppedPreviewFor(page), [9, 8]);
      expect(calls, hasLength(1), reason: 'cached for (id, revision)');
      expect(await other.thumbnailFor(page), [
        1,
        2,
        3,
      ], reason: 'the thumbnail stays the uncropped image (FR-4)');
    });

    test('stale preview of an older revision is dropped (AC-3)', () async {
      await addPages(1);
      var calls = 0;
      final hold = Completer<Uint8List>();
      final other = previewController(
        thumbnailer: (_) async => Uint8List.fromList([1]),
        // The first render is held; later ones answer with the turns.
        previewer: (thumb, q, turns) {
          calls++;
          return calls == 1
              ? hold.future
              : Future<Uint8List>.value(Uint8List.fromList([turns]));
        },
      );
      await other.restore();
      final older = other.session.pages.single;

      final stale = other.croppedPreviewFor(older);
      await until(() => calls == 1);
      await other.updatePage(older.rotatedClockwise());
      final newer = other.session.pages.single;
      expect(newer.revision, older.revision + 1);

      hold.complete(Uint8List.fromList([0]));
      expect(await stale, [0], reason: 'the old caller gets its revision');

      expect(await other.croppedPreviewFor(newer), [1]);
      expect(calls, 2, reason: 'the new revision renders on its own');
      expect(await other.croppedPreviewFor(newer), [1]);
      expect(calls, 2);

      // Nothing of the old revision is cached any more, and asking for it
      // again does not cache it either.
      expect(await other.croppedPreviewFor(older), [0]);
      expect(calls, 3);
      await other.croppedPreviewFor(older);
      expect(calls, 4);
      expect(await other.croppedPreviewFor(newer), [1]);
      expect(calls, 4);
    });

    test(
      'failed preview is cached until retried (AC-4): thumbnail fails',
      () async {
        await addPages(1);
        var thumbCalls = 0;
        var previewCalls = 0;
        var notified = 0;
        final other = previewController(
          thumbnailer: (_) async {
            thumbCalls++;
            if (thumbCalls == 1) throw const ImageDecodeFailure();
            return Uint8List.fromList([1]);
          },
          previewer: (thumb, q, turns) async {
            previewCalls++;
            return Uint8List.fromList([2]);
          },
        );
        await other.restore();
        other.addListener(() => notified++);
        final page = other.session.pages.single;

        for (var i = 0; i < 2; i++) {
          await expectLater(
            other.croppedPreviewFor(page),
            throwsA(isA<ImageDecodeFailure>()),
          );
        }
        expect((thumbCalls, previewCalls), (1, 0));

        other.retryThumbnail(page);
        expect(notified, 1);
        expect(await other.croppedPreviewFor(page), [2]);
        expect((thumbCalls, previewCalls), (2, 1));
      },
    );

    test(
      'failed preview is cached until retried (AC-4): preview fails',
      () async {
        await addPages(1);
        var thumbCalls = 0;
        var previewCalls = 0;
        var notified = 0;
        final other = previewController(
          thumbnailer: (_) async {
            thumbCalls++;
            return Uint8List.fromList([1]);
          },
          previewer: (thumb, q, turns) async {
            previewCalls++;
            if (previewCalls == 1) throw const ImageDecodeFailure();
            return Uint8List.fromList([2]);
          },
        );
        await other.restore();
        other.addListener(() => notified++);
        final page = other.session.pages.single;

        for (var i = 0; i < 2; i++) {
          await expectLater(
            other.croppedPreviewFor(page),
            throwsA(isA<ImageDecodeFailure>()),
          );
        }
        expect((thumbCalls, previewCalls), (1, 1));
        expect(await other.thumbnailFor(page), [1]);

        other.retryThumbnail(page);
        expect(notified, 1);
        expect(await other.croppedPreviewFor(page), [2]);
        expect((thumbCalls, previewCalls), (2, 2), reason: 'both redone');

        // A successful preview is kept by a retry.
        other.retryThumbnail(page);
        expect(notified, 1);
        await other.croppedPreviewFor(page);
        expect((thumbCalls, previewCalls), (2, 2));
      },
    );

    test('the previewer runs through the decode gate', () async {
      await addPages(1);
      var previewCalls = 0;
      final gate = DecodeGate();
      final other = previewController(
        thumbnailer: (_) async => Uint8List.fromList([1]),
        previewer: (thumb, q, turns) async {
          previewCalls++;
          return Uint8List.fromList([2]);
        },
        decodeGate: gate,
      );
      await other.restore();
      final page = other.session.pages.single;
      await other.thumbnailFor(page);

      // Another decode holds the gate.
      final release = Completer<void>();
      final held = gate.run(() => release.future);
      final preview = other.croppedPreviewFor(page);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(previewCalls, 0, reason: 'waits for the earlier decode');

      release.complete();
      await held;
      expect(await preview, [2]);
      expect(previewCalls, 1);
    });

    test('removing a page drops its cached preview', () async {
      await addPages(2);
      var previewCalls = 0;
      final other = previewController(
        thumbnailer: (_) async => Uint8List.fromList([1]),
        previewer: (thumb, q, turns) async {
          previewCalls++;
          return Uint8List.fromList([2]);
        },
      );
      await other.restore();
      final [first, second] = other.session.pages;
      await other.croppedPreviewFor(first);
      await other.croppedPreviewFor(second);
      expect(previewCalls, 2);

      await other.remove(first.id);
      await other.croppedPreviewFor(second);
      expect(previewCalls, 2, reason: 'other pages stay cached');
      // A removed page has no preview and its original is not decoded.
      await expectLater(other.croppedPreviewFor(first), throwsStateError);
      expect(previewCalls, 2);
    });
  });

  group('(F-021) restoring', () {
    test('is false before restore is ever called', () {
      expect(controller.restoring, isFalse);
    });

    test('is true from the restore call until it has finished', () async {
      await addPages(1);
      var notified = 0;
      final other = SessionController(
        store: SessionStore(root),
        source: source,
        exporter: exporter,
        sharer: sharer,
      )..addListener(() => notified++);
      final done = other.restore();
      expect(other.restoring, isTrue);
      expect(notified, greaterThan(0));
      await done;
      expect(other.restoring, isFalse);
      expect(other.session.pages, hasLength(1));
    });

    test('ends false when load throws a FileSystemException', () async {
      final other = SessionController(
        store: FlakyStore(root)..failLoad = true,
        source: source,
        exporter: exporter,
        sharer: sharer,
      );
      final done = other.restore();
      expect(other.restoring, isTrue);
      await done;
      expect(other.restoring, isFalse);
      expect(other.takeNotice(), SessionNotice.restoreFailed);
    });
  });

  test('a thumbnail asked for during an export waits for the render, as '
      'both share one decode gate (F-006)', () async {
    await addPages(1);
    var active = 0;
    var maxActive = 0;
    final rendering = Completer<void>();
    final release = Completer<void>();
    // Wired like lib/main.dart: one gate for the controller and exporter.
    final gate = DecodeGate();
    final c = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: PageExporter(
        exportDir: exports,
        renderer: (path, quad, turns, {format = RenderFormat.jpeg}) =>
            gate.run(() async {
              active++;
              maxActive = max(maxActive, active);
              if (!rendering.isCompleted) rendering.complete();
              await release.future;
              active--;
              return Uint8List.fromList([1, 2, 3]);
            }),
      ),
      sharer: sharer,
      thumbnailer: (path) async {
        active++;
        maxActive = max(maxActive, active);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return Uint8List.fromList([4, 5, 6]);
      },
      decodeGate: gate,
    );
    await c.restore();
    final export = c.exportAndShare(ExportFormat.png);
    await rendering.future;

    final preview = c.thumbnailFor(c.session.pages.single);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    release.complete();
    await Future.wait([export, preview]);

    expect(maxActive, 1, reason: 'one decoded original at a time');
    expect(sharer.shared.single, ['X-Scanner-trang-01.png']);
    expect(c.takeNotice(), isNull);
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

  /// A controller on the same session and exports as [controller], whose
  /// exporter renders through [renderer]; its session is restored.
  Future<SessionController> withRenderer(HeldRenderer renderer) async {
    final c = SessionController(
      store: SessionStore(root),
      source: source,
      exporter: PageExporter(exportDir: exports, renderer: renderer.call),
      sharer: sharer,
    );
    await c.restore();
    return c;
  }

  test('disposed controller does not start queued picker or export', () async {
    await addPages(1);
    final renderer = HeldRenderer(holds: {1});
    final c = await withRenderer(renderer);
    final running = c.exportAndShare(ExportFormat.jpeg);
    await renderer.reached(1);
    source.captures.add(null);
    final capture = c.capture();
    final queued = c.exportAndShare(ExportFormat.jpeg);
    c.dispose();
    renderer.release(1);
    await Future.wait([running, capture, queued]);
    expect(source.captures, hasLength(1), reason: 'picker never started');
    expect(renderer.turns, hasLength(1), reason: 'queued export never started');
    expect(sharer.shared, isEmpty);
    expect(c.session.pages, hasLength(1));
  });

  test('disposed controller ignores newly submitted operations', () async {
    source.captures.add(null);
    controller.dispose();
    await controller.capture();
    expect(source.captures, hasLength(1));
    expect(sharer.shared, isEmpty);
  });

  test('export job reports progress (AC-6)', () async {
    await addPages(3);
    final renderer = HeldRenderer(holds: {2});
    final c = await withRenderer(renderer);
    final seen = <int?>[];
    c.addListener(() => seen.add(c.exportJob?.done));
    expect(c.exportJob, isNull);

    final export = c.exportAndShare(ExportFormat.jpeg);
    await renderer.reached(2);
    final job = c.exportJob;
    expect(job, isNotNull);
    expect(job!.state, ExportState.running);
    expect(job.total, 3);
    expect(job.done, 1);
    expect(c.busy, isTrue);

    renderer.release(2);
    await export;
    expect(seen, containsAllInOrder([0, 1, 2, 3, null]));
    expect(job.state, ExportState.succeeded);
    expect(c.exportJob, isNull);
    expect(c.busy, isFalse);
    expect(sharer.shared.single, hasLength(3));
    expect(c.takeNotice(), isNull);
  });

  test('export job reports progress (AC-6): the job is gone while sharing, '
      'so there is no cancel that could not act', () async {
    await addPages(2);
    final c = await withRenderer(HeldRenderer());
    (ExportJob?, bool)? whileSharing;
    sharer.onShare = () => whileSharing = (c.exportJob, c.busy);

    await c.exportAndShare(ExportFormat.jpeg);

    expect(sharer.shared.single, hasLength(2));
    expect(whileSharing, (null, true));
  });

  test('cancelling an export shares nothing (AC-6): disposing the '
      'controller cancels its export', () async {
    await addPages(3);
    final renderer = HeldRenderer(holds: {2});
    final c = await withRenderer(renderer);

    final export = c.exportAndShare(ExportFormat.jpeg);
    await renderer.reached(2);
    final job = c.exportJob!;
    c.dispose();
    renderer.release(2);
    await export;

    expect(job.state, ExportState.cancelled);
    expect(sharer.shared, isEmpty);
    expect(exports.existsSync(), isFalse);
  });

  test('cancelling an export shares nothing (AC-6)', () async {
    await addPages(3);
    final renderer = HeldRenderer(holds: {2});
    final c = await withRenderer(renderer);
    final before = c.session;
    final onDisk = manifestPages();
    final originals = {
      for (final p in before.pages) p.id: c.originalFile(p).readAsBytesSync(),
    };

    final export = c.exportAndShare(ExportFormat.pdf);
    await renderer.reached(2);
    final job = c.exportJob!;
    c.cancelExport();
    c.cancelExport();
    renderer.release(2);
    await export;

    expect(job.state, ExportState.cancelled);
    expect(renderer.turns, hasLength(2), reason: 'page 3 not rendered');
    expect(sharer.shared, isEmpty);
    expect(c.takeNotice(), SessionNotice.exportCancelled);
    expect(c.takeNotice(), isNull);
    expect(c.exportJob, isNull);
    expect(c.busy, isFalse);
    expect(exports.existsSync(), isFalse);
    expect(c.session, same(before));
    expect(manifestPages(), onDisk);
    for (final p in before.pages) {
      expect(c.originalFile(p).readAsBytesSync(), originals[p.id]);
    }
  });

  test('cancelling an export shares nothing: cancelExport without an export '
      'does nothing (AC-6)', () async {
    controller.cancelExport();
    await addPages(1);
    var notified = 0;
    controller.addListener(() => notified++);
    controller.cancelExport();
    expect(notified, 0);

    await controller.exportAndShare(ExportFormat.jpeg);
    controller.cancelExport();
    expect(sharer.shared, hasLength(1));
    expect(controller.takeNotice(), isNull);
    expect(controller.exportJob, isNull);
  });

  test(
    'export uses the snapshot taken when the job was created (AC-5)',
    () async {
      await addPages(3);
      final renderer = HeldRenderer(holds: {1});
      final c = await withRenderer(renderer);
      final [_, second, third] = c.session.pages;

      final export = c.exportAndShare(ExportFormat.jpeg);
      await renderer.reached(1);
      // Both edits queue behind the export.
      final rotate = c.updatePage(second.rotatedClockwise());
      final remove = c.remove(third.id);
      renderer.release(1);
      await Future.wait([export, rotate, remove]);

      expect(renderer.turns, [0, 0, 0]);
      expect(sharer.shared.single, [
        for (var i = 1; i <= 3; i++) 'X-Scanner-trang-0$i.jpg',
      ]);
      expect(c.takeNotice(), isNull);
      expect(c.session.pages, hasLength(2));
      expect(c.session.pages[1].quarterTurns, 1);
    },
  );
}
