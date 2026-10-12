import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/imaging/decode_gate.dart';

void main() {
  test('overlapping jobs run one at a time, in call order (F-006)', () async {
    final gate = DecodeGate();
    final events = <String>[];
    var active = 0;
    var maxActive = 0;
    final releases = [Completer<void>(), Completer<void>(), Completer<void>()];

    Future<int> Function() job(int i) => () async {
      active++;
      if (active > maxActive) maxActive = active;
      events.add('start $i');
      await releases[i].future;
      events.add('end $i');
      active--;
      return i;
    };

    final results = [for (var i = 0; i < 3; i++) gate.run(job(i))];
    await pumpEventQueue();
    expect(events, ['start 0']);

    // Releasing out of order must not let a later job overtake.
    releases[2].complete();
    releases[1].complete();
    await pumpEventQueue();
    expect(events, ['start 0']);

    releases[0].complete();
    expect(await Future.wait(results), [0, 1, 2]);
    expect(events, [
      'start 0',
      'end 0',
      'start 1',
      'end 1',
      'start 2',
      'end 2',
    ]);
    expect(maxActive, 1);
  });

  test('a failing job reaches its own caller and does not block the next '
      '(F-006)', () async {
    final gate = DecodeGate();
    final order = <String>[];
    final failing = gate.run<int>(() async {
      order.add('failing');
      throw const FormatException('bad image');
    });
    final next = gate.run<int>(() async {
      order.add('next');
      return 7;
    });
    final syncThrow = gate.run<int>(() => throw StateError('sync'));
    final last = gate.run<String>(() async => 'ok');

    await expectLater(failing, throwsA(isA<FormatException>()));
    expect(await next, 7);
    await expectLater(syncThrow, throwsA(isA<StateError>()));
    expect(await last, 'ok');
    expect(order, ['failing', 'next']);
  });
}
