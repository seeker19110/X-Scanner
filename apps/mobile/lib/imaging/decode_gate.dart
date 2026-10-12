/// Runs image-decoding jobs one at a time, in call order.
///
/// A decoded original can take hundreds of megabytes, so the spec (§8)
/// allows at most one decoded original in memory at once. Every decode of
/// an original — thumbnails, the decode check when a page is added and the
/// renders of an export — must go through the same gate.
///
/// Jobs never wait for anything but earlier jobs of this gate, so a caller
/// holding another queue (e.g. the session write queue) cannot deadlock it.
class DecodeGate {
  /// Tail of the queue; never completes with an error.
  Future<void> _tail = Future<void>.value();

  /// Runs [job] after every earlier job has finished, successfully or not,
  /// and returns its result. An error of [job], also one thrown
  /// synchronously, goes to this caller only and does not stop later jobs.
  Future<T> run<T>(Future<T> Function() job) {
    final result = _tail.then((_) => job());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
