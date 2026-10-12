import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/imaging/isolate_budget.dart';
import 'package:x_scanner/imaging/page_render.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('isolate_budget'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('returns the result of a job that finishes within the budget', () async {
    expect(await runWithinBudget(() => 6 * 7, const Duration(seconds: 10)), 42);
  });

  test('passes an ImageDecodeFailure of the job to the caller', () async {
    await expectLater(
      runWithinBudget<int>(
        () => throw const ImageDecodeFailure(),
        const Duration(seconds: 10),
      ),
      throwsA(isA<ImageDecodeFailure>()),
    );
  });

  test('maps any other error of the job to ImageDecodeFailure', () async {
    await expectLater(
      runWithinBudget<int>(
        () => throw RangeError('secret content'),
        const Duration(seconds: 10),
      ),
      throwsA(isA<ImageDecodeFailure>()),
    );
  });

  test('an over-budget job is reported only once its isolate has stopped, '
      'so the decode gate never holds two decodes at once', () async {
    final watch = Stopwatch()..start();
    await expectLater(
      // A native sleep cannot be interrupted; the kill lands when it ends.
      runWithinBudget<void>(
        () => sleep(const Duration(milliseconds: 600)),
        const Duration(milliseconds: 50),
      ),
      throwsA(isA<ImageDecodeFailure>()),
    );
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(500));
  });

  test('a job that cannot be sent to an isolate fails as '
      'ImageDecodeFailure', () async {
    final port = ReceivePort();
    addTearDown(port.close);
    await expectLater(
      // A ReceivePort cannot cross isolates, so spawning fails.
      runWithinBudget(() => port.hashCode, const Duration(seconds: 10)),
      throwsA(isA<ImageDecodeFailure>()),
    );
  });

  test('a job over budget fails and is really stopped, not only no longer '
      'awaited', () async {
    final beat = File('${dir.path}/beat');
    final path = beat.path;

    await expectLater(
      runWithinBudget<void>(() {
        // Never returns; writes a heartbeat while it is still running.
        for (var i = 0; ; i++) {
          File(path).writeAsStringSync('$i');
          sleep(const Duration(milliseconds: 5));
        }
      }, const Duration(milliseconds: 300)),
      throwsA(isA<ImageDecodeFailure>()),
    );

    final atFailure = beat.readAsStringSync();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(beat.readAsStringSync(), atFailure);
  });
}
