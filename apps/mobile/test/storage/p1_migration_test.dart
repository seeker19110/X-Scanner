import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/storage/document_store.dart';
import 'package:x_scanner/storage/library_store.dart';
import 'package:x_scanner/storage/p1_migration.dart';

/// Fixed whole-second modification time of `session.json`.
final DateTime _mtime = DateTime(2026, 3, 4, 5, 6, 7);

const String _docA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _docB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

/// Synthetic, distinct bytes for page [n]; no real images are used.
List<int> _bytes(int n) =>
    List<int>.generate(100 + 37 * n, (i) => (i * 13 + n) % 256);

/// A distinct skewed quad per page.
PageQuad _quad(int n) => PageQuad(
  topLeft: Point<double>(0.01 * n, 0.02 + 0.01 * n),
  topRight: Point<double>(0.93 - 0.01 * n, 0.12),
  bottomRight: Point<double>(0.88, 0.97 - 0.01 * n),
  bottomLeft: Point<double>(0.02 + 0.01 * n, 0.9),
);

class _FakeStorage implements Storage {
  _FakeStorage(this.free, {this.fail = false});

  int free;
  final bool fail;

  @override
  Future<int> freeBytes(Directory dir) async {
    if (fail) {
      throw const FileSystemException('statfs failed');
    }
    return free;
  }
}

/// Simulates the process being killed: not a [FileSystemException], so no
/// cleanup code in the migration runs.
final class _Killed extends Error {}

/// Records every disk-changing call made through the IO overrides and
/// injects a failure at call number [at] (1-based).
class _Faults {
  _Faults(this.root, {this.at, this.kill = true});

  final String root;
  final int? at;
  final bool kill;
  final List<String> ops = [];

  void hit(String op, String path) {
    final relative = path.startsWith(root) ? path.substring(root.length) : path;
    ops.add('$op $relative');
    if (ops.length == at) {
      if (kill) {
        throw _Killed();
      }
      throw FileSystemException('injected', path);
    }
  }
}

final class _RealIO extends IOOverrides {}

class _CountingFile implements File {
  _CountingFile(this._real, this._faults);

  final File _real;
  final _Faults _faults;

  @override
  String get path => _real.path;

  @override
  Future<bool> exists() => _real.exists();

  @override
  Future<int> length() => _real.length();

  @override
  Future<DateTime> lastModified() => _real.lastModified();

  @override
  Future<Uint8List> readAsBytes() => _real.readAsBytes();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    if (mode != FileMode.read) {
      _faults.hit('sync', path);
    }
    return _real.open(mode: mode);
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    _faults.hit('write', path);
    return _real.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  @override
  Future<File> copy(String newPath) async {
    _faults.hit('copy', newPath);
    return _real.copy(newPath);
  }

  @override
  Future<File> rename(String newPath) async {
    _faults.hit('rename', path);
    return _real.rename(newPath);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    _faults.hit('delete', path);
    return _real.delete(recursive: recursive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not counted');
}

class _CountingDirectory implements Directory {
  _CountingDirectory(this._real, this._faults);

  final Directory _real;
  final _Faults _faults;

  @override
  String get path => _real.path;

  @override
  Uri get uri => _real.uri;

  @override
  Future<bool> exists() => _real.exists();

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => _real.list(recursive: recursive, followLinks: followLinks);

  @override
  Future<Directory> create({bool recursive = false}) async {
    _faults.hit('mkdir', path);
    return _real.create(recursive: recursive);
  }

  @override
  Future<Directory> rename(String newPath) async {
    _faults.hit('rename', path);
    return _real.rename(newPath);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    _faults.hit('delete', path);
    return _real.delete(recursive: recursive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not counted');
}

/// Runs [body] with every [File] and [Directory] counted by [faults].
Future<T> _counted<T>(_Faults faults, Future<T> Function() body) {
  final real = _RealIO();
  return IOOverrides.runZoned(
    body,
    createFile: (path) => _CountingFile(real.createFile(path), faults),
    createDirectory: (path) =>
        _CountingDirectory(real.createDirectory(path), faults),
  );
}

void main() {
  late Directory root;
  late _FakeStorage storage;

  setUp(() {
    root = Directory.systemTemp.createTempSync('p1_migration_test');
    storage = _FakeStorage(1 << 40);
  });

  tearDown(() => root.deleteSync(recursive: true));

  String at(String relative) => '${root.path}/$relative';

  Directory session() => Directory(at('session'));
  Directory documents() => Directory(at('documents'));
  File journal() => File(at('migration.json'));

  P1Migration migration({String Function()? newDocId, Storage? using}) =>
      P1Migration(appRoot: root, storage: using ?? storage, newDocId: newDocId);

  /// Writes P1 data with [k] pages and returns its pages.
  List<ScanPage> writeP1(int k, {int seed = 0}) {
    final random = Random(seed);
    final pages = <ScanPage>[];
    Directory(at('session/originals')).createSync(recursive: true);
    for (var n = 1; n <= k; n++) {
      final id = newPageId(random);
      final path = 'originals/$id.jpg';
      File(at('session/$path')).writeAsBytesSync(_bytes(n + seed * 10));
      pages.add(
        ScanPage(
          id: id,
          originalPath: path,
          quad: _quad(n),
          quarterTurns: n % 4,
        ),
      );
    }
    File(at('session/session.json'))
      ..writeAsStringSync(encodeManifest(ScanSession(pages: pages)))
      ..setLastModifiedSync(_mtime);
    return pages;
  }

  /// Every entity under [dir] by relative path: file bytes, `dir`, or
  /// `link -> target`.
  Map<String, Object> tree(Directory dir) {
    final result = <String, Object>{};
    if (!dir.existsSync()) {
      return result;
    }
    for (final e in dir.listSync(recursive: true, followLinks: false)) {
      final relative = e.path.substring(dir.path.length + 1);
      result[relative] = switch (e) {
        File() => e.readAsBytesSync(),
        Link() => 'link -> ${e.targetSync()}',
        _ => 'dir',
      };
    }
    return result;
  }

  /// Names of entries directly under [dir], sorted.
  List<String> names(Directory dir) => dir.existsSync()
      ? (dir
            .listSync(followLinks: false)
            .map((e) => e.path.split('/').last)
            .toList()
          ..sort())
      : <String>[];

  /// Folders under `documents/` named by a valid id (no `.part`).
  List<String> documentFolders() => [
    for (final name in names(documents()))
      if (isValidPageId(name) &&
          FileSystemEntity.typeSync(
                at('documents/$name'),
                followLinks: false,
              ) ==
              FileSystemEntityType.directory)
        name,
  ];

  List<String> rollbacks() => [
    for (final name in names(root))
      if (name.startsWith('session.migrated')) name,
  ];

  List<String> partFolders() => [
    for (final name in names(documents()))
      if (name.endsWith('.part')) name,
  ];

  /// Checks that [docId] is the single library document holding [pages]
  /// and the P1 bytes [p1].
  Future<void> expectMigrated(
    String docId,
    List<ScanPage> pages,
    Map<String, Object> p1,
  ) async {
    final entries = await LibraryStore(documents()).list();
    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry, isA<LibraryDocument>());
    final document = (entry as LibraryDocument).document;
    expect(document.id, docId);
    expect(document.title, defaultDocumentTitle(_mtime.toLocal()));
    expect(document.createdAt, _mtime.toUtc());
    expect(document.updatedAt, _mtime.toUtc());
    expect(
      [for (final p in document.pages) p.id],
      [for (final p in pages) p.id],
    );
    for (var i = 0; i < pages.length; i++) {
      expect(document.pages[i].originalPath, pages[i].originalPath);
      expect(document.pages[i].quad, pages[i].quad);
      expect(document.pages[i].quarterTurns, pages[i].quarterTurns);
      expect(document.pages[i].revision, 0);
    }
    final loaded = await LibraryStore(documents()).open(docId).load();
    expect(loaded, isA<DocumentLoaded>());
    for (final page in pages) {
      expect(
        File(at('documents/$docId/${page.originalPath}')).readAsBytesSync(),
        p1[page.originalPath],
      );
    }
  }

  group('AC-6 migrates P1 data into one document', () {
    for (final k in [0, 1, 3]) {
      test('k = $k', () async {
        final pages = writeP1(k);
        final p1 = tree(session());
        final outcome = await migration(newDocId: () => _docA).run();
        expect(outcome, isA<MigrationDone>());
        expect((outcome as MigrationDone).docId, _docA);
        await expectMigrated(_docA, pages, p1);
        expect(session().existsSync(), isFalse);
        expect(rollbacks(), ['session.migrated']);
        expect(tree(Directory(at('session.migrated'))), p1);
        expect(journal().existsSync(), isFalse);
        expect(partFolders(), isEmpty);
        expect(names(root), ['documents', 'session.migrated']);
      });
    }
  });

  group('AC-14 the rollback copy is kept', () {
    test('later runs are not needed and change nothing', () async {
      final pages = writeP1(3);
      final p1 = tree(session());
      expect(await migration().run(), isA<MigrationDone>());
      final docId = documentFolders().single;
      for (var i = 0; i < 2; i++) {
        expect(await migration().run(), isA<MigrationNotNeeded>());
        expect(tree(Directory(at('session.migrated'))), p1);
        expect(documentFolders(), [docId]);
      }
      await expectMigrated(docId, pages, p1);
    });

    test('a new session/ goes to a new document and rollback', () async {
      writeP1(2);
      final first = tree(session());
      expect(
        await migration(newDocId: () => _docA).run(),
        isA<MigrationDone>(),
      );
      writeP1(1, seed: 1);
      final second = tree(session());
      final outcome = await migration(newDocId: () => _docB).run();
      expect((outcome as MigrationDone).docId, _docB);
      expect(documentFolders(), [_docA, _docB]);
      expect(rollbacks(), ['session.migrated', 'session.migrated-2']);
      expect(tree(Directory(at('session.migrated'))), first);
      expect(tree(Directory(at('session.migrated-2'))), second);
    });

    test('rollback names skip every existing entry', () async {
      Directory(at('session.migrated')).createSync();
      File(at('session.migrated-2')).writeAsStringSync('keep');
      writeP1(1);
      final p1 = tree(session());
      expect(await migration().run(), isA<MigrationDone>());
      expect(tree(Directory(at('session.migrated'))), isEmpty);
      expect(File(at('session.migrated-2')).readAsStringSync(), 'keep');
      expect(tree(Directory(at('session.migrated-3'))), p1);
    });
  });

  group('AC-7 fault injection', () {
    /// Every place a P1 original's bytes may live.
    void expectNoOriginalLost(
      List<ScanPage> pages,
      Map<String, Object> p1,
      String label,
    ) {
      expect(documentFolders().length, lessThanOrEqualTo(1), reason: label);
      final places = [
        'session',
        ...rollbacks(),
        for (final id in documentFolders()) 'documents/$id',
      ];
      for (final page in pages) {
        final found = places.any((place) {
          final file = File(at('$place/${page.originalPath}'));
          return file.existsSync() &&
              _listEquals(file.readAsBytesSync(), p1[page.originalPath]!);
        });
        expect(found, isTrue, reason: '$label: ${page.originalPath}');
      }
    }

    Future<void> expectFinal(
      MigrationOutcome last,
      List<ScanPage> pages,
      Map<String, Object> p1,
      String label,
    ) async {
      expectNoOriginalLost(pages, p1, label);
      // The recovery runs inject nothing, so they must finish.
      expect(last, isA<MigrationDone>(), reason: label);
      expect(
        File(at('migration.json.tmp')).existsSync(),
        isFalse,
        reason: label,
      );
      final docId = documentFolders().single;
      await expectMigrated(docId, pages, p1);
      expect(session().existsSync(), isFalse, reason: label);
      expect(rollbacks(), ['session.migrated'], reason: label);
      expect(tree(Directory(at('session.migrated'))), p1, reason: label);
      expect(journal().existsSync(), isFalse, reason: label);
      expect(partFolders(), isEmpty, reason: label);
    }

    /// Runs a clean migration until it is not [MigrationFailed].
    Future<MigrationOutcome> recover() async {
      MigrationOutcome last = const MigrationFailed(MigrationFailure.io);
      for (var attempt = 0; attempt < 3; attempt++) {
        last = await migration().run();
        if (last is! MigrationFailed) {
          break;
        }
      }
      return last;
    }

    Future<List<String>> cleanOps() async {
      writeP1(3);
      final faults = _Faults(root.path);
      expect(
        await _counted(faults, () => migration().run()),
        isA<MigrationDone>(),
      );
      root.deleteSync(recursive: true);
      root.createSync();
      return faults.ops;
    }

    test('the clean run covers steps 2 to 7', () async {
      final ops = await cleanOps();
      expect(ops.first, startsWith('write /migration.json.tmp'));
      expect(ops, contains('rename /migration.json.tmp'));
      expect(ops.where((o) => o.startsWith('copy ')), hasLength(3));
      expect(ops.where((o) => o.startsWith('sync ')), hasLength(3));
      expect(
        ops,
        contains(matches(RegExp(r'^write .*\.part/document\.json$'))),
      );
      expect(ops, contains(matches(RegExp(r'^rename /documents/.*\.part$'))));
      expect(ops, contains('rename /session'));
      expect(ops.last, 'delete /migration.json');
      // Every one of these is a fault index in the tests below.
      expect(ops, hasLength(19));
    });

    for (final kill in [true, false]) {
      final mode = kill ? 'killed' : 'I/O error';
      test('$mode at every disk operation', () async {
        final total = (await cleanOps()).length;
        expect(total, greaterThan(10));
        for (var i = 1; i <= total; i++) {
          final label = '$mode at $i';
          root.deleteSync(recursive: true);
          root.createSync();
          final pages = writeP1(3);
          final p1 = tree(session());
          final faults = _Faults(root.path, at: i, kill: kill);
          final run = _counted(faults, () => migration().run());
          if (kill) {
            await expectLater(run, throwsA(isA<_Killed>()), reason: label);
          } else {
            final outcome = await run;
            expect(
              outcome is MigrationDone ||
                  (outcome is MigrationFailed &&
                      outcome.reason == MigrationFailure.io),
              isTrue,
              reason: label,
            );
          }
          expect(faults.ops.length, greaterThanOrEqualTo(i), reason: label);
          expectNoOriginalLost(pages, p1, label);
          await expectFinal(await recover(), pages, p1, label);
        }
      });
    }
  });

  group('AC-8 free space', () {
    late List<ScanPage> pages;
    late Map<String, Object> p1;
    late int size;

    setUp(() {
      pages = writeP1(3);
      p1 = tree(session());
      size = 0;
      for (final page in pages) {
        size += (p1[page.originalPath]! as List<int>).length;
      }
    });

    test('one byte short fails and changes nothing', () async {
      storage.free = size + (size / 10).ceil() - 1;
      final outcome = await migration().run();
      expect(outcome, isA<MigrationFailed>());
      expect(
        (outcome as MigrationFailed).reason,
        MigrationFailure.insufficientSpace,
      );
      expect(tree(session()), p1);
      expect(documents().existsSync(), isFalse);
      expect(journal().existsSync(), isFalse);
      expect(names(root), ['session']);
    });

    test('exactly enough succeeds', () async {
      storage.free = size + (size / 10).ceil();
      expect(await migration().run(), isA<MigrationDone>());
      await expectMigrated(documentFolders().single, pages, p1);
    });

    test('a failing free space query is an I/O failure', () async {
      final outcome = await migration(using: _FakeStorage(0, fail: true)).run();
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(session()), p1);
      expect(names(root), ['session']);
    });
  });

  group('AC-9 unreadable P1 data', () {
    Future<void> expectUnreadable() async {
      final before = tree(session());
      expect(await migration().run(), isA<MigrationSourceUnreadable>());
      expect(tree(session()), before);
      expect(names(root), ['session']);
    }

    test('session.json is not JSON', () async {
      writeP1(1);
      File(at('session/session.json')).writeAsStringSync('{not json');
      await expectUnreadable();
    });

    test('session.json is not UTF-8', () async {
      writeP1(1);
      File(at('session/session.json')).writeAsBytesSync([0x7b, 0xff, 0xfe]);
      await expectUnreadable();
    });

    test('a referenced original is missing', () async {
      final pages = writeP1(2);
      File(at('session/${pages[1].originalPath}')).deleteSync();
      await expectUnreadable();
    });

    test('a referenced original is a link', () async {
      final pages = writeP1(1);
      final path = at('session/${pages[0].originalPath}');
      File(path).renameSync(at('outside.jpg'));
      Link(path).createSync(at('outside.jpg'));
      final before = tree(session());
      expect(await migration().run(), isA<MigrationSourceUnreadable>());
      expect(tree(session()), before);
      expect(documents().existsSync(), isFalse);
    });

    test('session/originals that is a link', () async {
      writeP1(1);
      Directory(at('session/originals')).renameSync(at('outside'));
      Link(at('session/originals')).createSync(at('outside'));
      final before = tree(root);
      expect(await migration().run(), isA<MigrationSourceUnreadable>());
      expect(tree(root), before);
    });

    test('a copying journal and its .part are removed', () async {
      writeP1(1);
      File(at('session/session.json')).writeAsStringSync('[]');
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': 'copying', 'docId': _docA}),
      );
      Directory(at('documents/$_docA.part/originals'))
          .createSync(recursive: true);
      final before = tree(session());
      expect(await migration().run(), isA<MigrationSourceUnreadable>());
      expect(tree(session()), before);
      expect(journal().existsSync(), isFalse);
      expect(partFolders(), isEmpty);
    });
  });

  group('step 5 verification', () {
    test('a copy with different bytes is an I/O failure', () async {
      final pages = writeP1(2);
      final p1 = tree(session());
      final faults = _Faults(root.path);
      final real = _RealIO();
      final outcome = await IOOverrides.runZoned(
        () => migration().run(),
        createFile: (path) => _CorruptingCopy(real.createFile(path), faults),
        createDirectory: (path) =>
            _CountingDirectory(real.createDirectory(path), faults),
      );
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(session()), p1);
      expect(partFolders(), isEmpty);
      expect(documentFolders(), isEmpty);
      expect(journal().existsSync(), isFalse);
      expect(pages, hasLength(2));
    });
  });

  group('step 6 target', () {
    test('an existing document folder is never overwritten', () async {
      writeP1(1);
      final p1 = tree(session());
      File(at('documents/$_docA/keep.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('keep');
      final outcome = await migration(newDocId: () => _docA).run();
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(Directory(at('documents/$_docA'))), {
        'keep.txt': utf8.encode('keep'),
      });
      expect(tree(session()), p1);
      expect(partFolders(), isEmpty);
      expect(journal().existsSync(), isFalse);
    });

    test('an invalid generated id writes nothing', () async {
      writeP1(1);
      final p1 = tree(session());
      await expectLater(
        migration(newDocId: () => '../x').run(),
        throwsStateError,
      );
      expect(tree(session()), p1);
      expect(names(root), ['session']);
    });
  });

  group('FR-7 recovery', () {
    Future<void> expectUnchangedFailure(String journalContent) async {
      writeP1(1);
      journal().writeAsStringSync(journalContent);
      Directory(at('documents/$_docA.part')).createSync(recursive: true);
      final before = tree(root);
      final outcome = await migration().run();
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(root), before);
    }

    for (final entry in {
      'not JSON': '{',
      'not an object': '[]',
      'wrong version': jsonEncode({
        'version': 2,
        'state': 'copying',
        'docId': _docA,
      }),
      'unknown state': jsonEncode({
        'version': 1,
        'state': 'done',
        'docId': _docA,
      }),
      'traversal id': jsonEncode({
        'version': 1,
        'state': 'committed',
        'docId': '../session',
      }),
      'missing id': jsonEncode({'version': 1, 'state': 'copying'}),
    }.entries) {
      test('a journal that is ${entry.key} changes nothing', () async {
        await expectUnchangedFailure(entry.value);
      });
    }

    test('a journal that is not UTF-8 changes nothing', () async {
      writeP1(1);
      journal().writeAsBytesSync([0xff]);
      final before = tree(root);
      final outcome = await migration().run();
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(root), before);
    });

    /// Commits [pages] as document [docId] by a full run, then puts the
    /// tree back into the state after step 6 with [state] in the journal.
    Future<Map<String, Object>> afterCommit(String state) async {
      final p1 = tree(session());
      expect(
        await migration(newDocId: () => _docA).run(),
        isA<MigrationDone>(),
      );
      Directory(at('session.migrated')).renameSync(at('session'));
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': state, 'docId': _docA}),
      );
      return p1;
    }

    for (final state in ['committed', 'copying']) {
      test('$state with the document committed finishes step 7', () async {
        final pages = writeP1(3);
        final p1 = await afterCommit(state);
        final outcome = await migration(newDocId: () => _docB).run();
        expect((outcome as MigrationDone).docId, _docA);
        await expectMigrated(_docA, pages, p1);
        expect(session().existsSync(), isFalse);
        expect(tree(Directory(at('session.migrated'))), p1);
        expect(journal().existsSync(), isFalse);
      });
    }

    test('committed whose folder is missing copies again and keeps '
        'session/ until the copy is committed', () async {
      final pages = writeP1(3);
      final p1 = await afterCommit('committed');
      Directory(at('documents/$_docA')).renameSync(at('documents/$_docA.part'));
      final outcome = await migration(newDocId: () => _docB).run();
      expect((outcome as MigrationDone).docId, _docA);
      await expectMigrated(_docA, pages, p1);
      expect(tree(Directory(at('session.migrated'))), p1);
      expect(journal().existsSync(), isFalse);
    });

    test(
      'copying with an empty document folder never moves session/',
      () async {
        final pages = writeP1(2);
        final p1 = tree(session());
        journal().writeAsStringSync(
          jsonEncode({'version': 1, 'state': 'copying', 'docId': _docA}),
        );
        Directory(at('documents/$_docA')).createSync(recursive: true);
        final first = await migration().run();
        expect((first as MigrationFailed).reason, MigrationFailure.io);
        expect(tree(session()), p1);
        expect(rollbacks(), isEmpty);
        final next = await migration(newDocId: () => _docB).run();
        expect((next as MigrationDone).docId, _docB);
        expect(tree(Directory(at('session.migrated'))), p1);
        for (final page in pages) {
          expect(
            File(at('documents/$_docB/${page.originalPath}')).readAsBytesSync(),
            p1[page.originalPath],
          );
        }
      },
    );

    test('committed whose document is incomplete and without session/ '
        'changes nothing', () async {
      writeP1(1);
      expect(
        await migration(newDocId: () => _docA).run(),
        isA<MigrationDone>(),
      );
      File(at('documents/$_docA/document.json')).deleteSync();
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': 'committed', 'docId': _docA}),
      );
      final before = tree(root);
      final outcome = await migration().run();
      expect((outcome as MigrationFailed).reason, MigrationFailure.io);
      expect(tree(root), before);
    });

    test('committed without session/ only removes the journal', () async {
      final pages = writeP1(1);
      final p1 = tree(session());
      expect(
        await migration(newDocId: () => _docA).run(),
        isA<MigrationDone>(),
      );
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': 'committed', 'docId': _docA}),
      );
      final outcome = await migration().run();
      expect((outcome as MigrationDone).docId, _docA);
      expect(journal().existsSync(), isFalse);
      expect(rollbacks(), ['session.migrated']);
      await expectMigrated(_docA, pages, p1);
    });

    test('copying with a partial .part reruns with the same id', () async {
      final pages = writeP1(3);
      final p1 = tree(session());
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': 'copying', 'docId': _docA}),
      );
      File(at('documents/$_docA.part/originals/${pages[0].id}.jpg'))
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      final outcome = await migration(newDocId: () => _docB).run();
      expect((outcome as MigrationDone).docId, _docA);
      expect(documentFolders(), [_docA]);
      await expectMigrated(_docA, pages, p1);
      expect(partFolders(), isEmpty);
    });

    test('copying without session.json removes .part and journal', () async {
      journal().writeAsStringSync(
        jsonEncode({'version': 1, 'state': 'copying', 'docId': _docA}),
      );
      Directory(at('documents/$_docA.part/originals'))
          .createSync(recursive: true);
      expect(await migration().run(), isA<MigrationNotNeeded>());
      expect(journal().existsSync(), isFalse);
      expect(partFolders(), isEmpty);
    });
  });

  group('step 8 and nothing to migrate', () {
    test('without session/ nothing is created', () async {
      expect(await migration().run(), isA<MigrationNotNeeded>());
      expect(names(root), isEmpty);
    });

    test('session/ without session.json is not touched', () async {
      writeP1(1);
      File(at('session/session.json')).deleteSync();
      final before = tree(root);
      expect(await migration().run(), isA<MigrationNotNeeded>());
      expect(tree(root), before);
    });

    test('orphan .part folders are removed, nothing else', () async {
      writeP1(1);
      expect(
        await migration(newDocId: () => _docA).run(),
        isA<MigrationDone>(),
      );
      Directory(at('documents/$_docB.part/originals'))
          .createSync(recursive: true);
      File(at('documents/$_docB.part/document.json')).writeAsStringSync('x');
      Directory(at('documents/notes.part')).createSync();
      File(at('documents/${'c' * 32}.part')).writeAsStringSync('file');
      final outside = Directory(at('outside'))..createSync();
      File('${outside.path}/keep.txt').writeAsStringSync('keep');
      Link(at('documents/${'d' * 32}.part')).createSync(outside.path);
      final rollback = tree(Directory(at('session.migrated')));
      final document = tree(Directory(at('documents/$_docA')));

      expect(await migration().run(), isA<MigrationNotNeeded>());

      expect(names(documents()), [
        _docA,
        '${'c' * 32}.part',
        '${'d' * 32}.part',
        'notes.part',
      ]);
      expect(tree(outside), {'keep.txt': utf8.encode('keep')});
      expect(tree(Directory(at('session.migrated'))), rollback);
      expect(tree(Directory(at('documents/$_docA'))), document);
    });

    test('orphan .part folders stay while a journal is open', () async {
      writeP1(1);
      File(at('session/session.json')).writeAsStringSync('{');
      Directory(at('documents/$_docB.part')).createSync(recursive: true);
      journal().writeAsStringSync('{');
      await migration().run();
      expect(partFolders(), ['$_docB.part']);
    });
  });
}

bool _listEquals(List<int> a, Object b) {
  if (b is! List<int> || a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// A counted file whose [copy] writes one changed byte, like a bad disk.
class _CorruptingCopy extends _CountingFile {
  _CorruptingCopy(super.real, super.faults);

  @override
  Future<File> copy(String newPath) async {
    final copied = await super.copy(newPath);
    final target = _RealIO().createFile(newPath);
    final bytes = await target.readAsBytes();
    bytes[0] ^= 0xff;
    await target.writeAsBytes(bytes, flush: true);
    return copied;
  }
}
