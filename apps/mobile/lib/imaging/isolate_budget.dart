import 'dart:async';
import 'dart:isolate';

import 'page_render.dart';

/// Wall-clock budget of one decode job: a thumbnail or an export render.
// DEBT: budget chosen without device measurement; a 50 MP render on a slow device may come close | trần: 60 s per job | xem lại khi: P2 device benchmark (spec §2, §19).
const Duration decodeBudget = Duration(seconds: 60);

/// Runs [job] in a new isolate and returns its result, or throws
/// [ImageDecodeFailure] when [job] throws, cannot be sent to an isolate or
/// runs longer than [budget].
///
/// Unlike [Future.timeout], an over-budget job is killed, so a decoder
/// stuck in a loop on a crafted image stops using CPU and memory. The
/// failure is reported only once the isolate has exited, so a caller that
/// queues decodes (`DecodeGate`) never has two in memory at once. Errors
/// of [job] are not passed on, so no content they may carry leaves the
/// isolate.
Future<T> runWithinBudget<T>(T Function() job, Duration budget) async {
  final result = Completer<T>();
  // Set up before the isolate starts so no reply can arrive unhandled. The
  // reply is the job's record, or null for a failed job; onExit sends null
  // when the isolate has exited, also after a kill.
  final port = RawReceivePort((Object? message) {
    if (result.isCompleted) return;
    if (message is (T,)) {
      result.complete(message.$1);
    } else {
      result.completeError(const ImageDecodeFailure());
    }
  });
  Timer? timer;
  try {
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn<(T Function(), SendPort)>(
        _runJob,
        (job, port.sendPort),
        onExit: port.sendPort,
        errorsAreFatal: true,
      );
    } catch (_) {
      throw const ImageDecodeFailure();
    }
    timer = Timer(budget, () => isolate.kill(priority: Isolate.immediate));
    return await result.future;
  } finally {
    timer?.cancel();
    port.close();
  }
}

/// Isolate entry of [runWithinBudget]: replies with a one-field record of
/// the job's result, or `null` when the job throws.
void _runJob<T>((T Function(), SendPort) message) {
  final (job, reply) = message;
  Object? result;
  try {
    result = (job(),);
  } catch (_) {
    result = null;
  }
  Isolate.exit(reply, result);
}
