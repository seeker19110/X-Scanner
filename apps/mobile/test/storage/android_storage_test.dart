import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/storage/android_storage.dart';
import 'package:x_scanner/storage/p1_migration.dart';

const _channel = MethodChannel('org.xscanner/storage');
const _injectedChannel = MethodChannel('org.xscanner/storage/test');
const _sensitiveMarker = 'synthetic-private-capacity-marker';
const _fiveGiB = 5 * 1024 * 1024 * 1024;

Matcher get _sanitizedFailure => isA<FileSystemException>()
    .having(
      (error) => error.message,
      'message',
      'Storage capacity is unavailable.',
    )
    .having((error) => error.path, 'path', isNull)
    .having((error) => error.osError, 'osError', isNull)
    .having(
      (error) => error.toString(),
      'description',
      isNot(contains(_sensitiveMarker)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;
  late Storage storage;

  setUp(() {
    root = Directory('${Directory.systemTemp.path}/$_sensitiveMarker');
    storage = AndroidStorage(appRoot: root);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    messenger.setMockMethodCallHandler(_injectedChannel, null);
  });

  test('uses the fixed channel and exact method with null arguments', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return 17;
    });

    expect(await storage.freeBytes(root), 17);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'availableBytes');
    expect(calls.single.arguments, isNull);
  });

  for (final capacity in <int>[0, 4096, _fiveGiB]) {
    test('preserves available capacity $capacity exactly', () async {
      messenger.setMockMethodCallHandler(_channel, (_) async => capacity);

      expect(await storage.freeBytes(root), capacity);
    });
  }

  test('reads fresh capacity on every invocation', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(_channel, (_) async {
      calls++;
      return calls == 1 ? _fiveGiB : 0;
    });

    expect(await storage.freeBytes(root), _fiveGiB);
    expect(await storage.freeBytes(root), 0);
    expect(calls, 2);
  });

  test('uses the injected MethodChannel', () async {
    var defaultCalls = 0;
    messenger.setMockMethodCallHandler(_channel, (_) async {
      defaultCalls++;
      return 1;
    });
    messenger.setMockMethodCallHandler(_injectedChannel, (call) async {
      expect(call.method, 'availableBytes');
      expect(call.arguments, isNull);
      return _fiveGiB;
    });
    final injected = AndroidStorage(appRoot: root, channel: _injectedChannel);

    expect(await injected.freeBytes(root), _fiveGiB);
    expect(defaultCalls, 0);
  });

  test(
    'compares absolute root paths without requiring filesystem IO',
    () async {
      final relativeRoot = Directory('$_sensitiveMarker/app-support');
      final relative = AndroidStorage(appRoot: relativeRoot);
      messenger.setMockMethodCallHandler(_channel, (_) async => 73);

      expect(await relative.freeBytes(relativeRoot.absolute), 73);
    },
  );

  test('rejects another root before invoking the platform', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(_channel, (_) async {
      calls++;
      return _fiveGiB;
    });

    await expectLater(
      storage.freeBytes(Directory('${root.path}-other')),
      throwsA(_sanitizedFailure),
    );
    expect(calls, 0);
  });

  final invalidResults = <String, Object?>{
    'null': null,
    'negative': -1,
    'double': 4096.0,
    'string': _sensitiveMarker,
    'boolean': false,
    'list': <Object?>[_sensitiveMarker],
    'map': <String, Object?>{'path': _sensitiveMarker},
  };
  for (final entry in invalidResults.entries) {
    test('rejects ${entry.key} capacity with a sanitized error', () async {
      messenger.setMockMethodCallHandler(_channel, (_) async => entry.value);

      await expectLater(storage.freeBytes(root), throwsA(_sanitizedFailure));
    });
  }

  for (final code in <String>[
    'capacity_unavailable',
    'invalid_arguments',
    _sensitiveMarker,
  ]) {
    test('sanitizes platform error $code and its details', () async {
      messenger.setMockMethodCallHandler(_channel, (_) async {
        throw PlatformException(
          code: code,
          message: _sensitiveMarker,
          details: <String, Object?>{'path': root.path},
          stacktrace: _sensitiveMarker,
        );
      });

      await expectLater(storage.freeBytes(root), throwsA(_sanitizedFailure));
    });
  }

  test('sanitizes a missing plugin instead of assuming capacity', () async {
    messenger.setMockMethodCallHandler(_channel, (_) async {
      throw MissingPluginException(_sensitiveMarker);
    });

    await expectLater(storage.freeBytes(root), throwsA(_sanitizedFailure));
  });
}
