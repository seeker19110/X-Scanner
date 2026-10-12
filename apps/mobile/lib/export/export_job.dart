import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/scan_page.dart';

/// File types the session can be exported to.
enum ExportFormat { pdf, jpeg, png }

/// Life cycle of an [ExportJob]: `queued → running → succeeded | failed |
/// cancelled`, or `queued → cancelled`; the last three are final.
enum ExportState { queued, running, succeeded, failed, cancelled }

/// Why an [ExportJob] did not succeed. Closed on purpose: no message,
/// path or content is ever attached (XS-08 FR-5).
enum ExportFailure { renderFailed, writeFailed, cancelled }

/// One export of a fixed snapshot of pages (XS-08 FR-5). Notifies its
/// listeners on every change of state or progress.
///
/// The runner moves it on with [start], [pageDone], [succeed], [fail] and
/// [markCancelled]; any other order throws a [StateError].
class ExportJob extends ChangeNotifier {
  /// Takes a snapshot of [pages]; later changes to that list or to the
  /// session do not reach the job. Throws [ArgumentError] when empty.
  ExportJob(List<ScanPage> pages, this.format) : pages = _snapshot(pages);

  /// The pages to export, in order; unmodifiable.
  final List<ScanPage> pages;

  /// The file type to export to.
  final ExportFormat format;

  ExportState _state = ExportState.queued;
  int _done = 0;
  ExportFailure? _failure;
  List<File>? _files;
  bool _cancelRequested = false;

  /// The current state; starts [ExportState.queued].
  ExportState get state => _state;

  /// Pages finished so far, `0..total`; never decreases.
  int get done => _done;

  /// The number of pages, at least 1.
  int get total => pages.length;

  /// Set only in [ExportState.failed] and [ExportState.cancelled].
  ExportFailure? get failure => _failure;

  /// The exported files in page order; set only in
  /// [ExportState.succeeded] and unmodifiable.
  List<File>? get files => _files;

  /// Whether [cancel] was called before the job ended.
  bool get cancelRequested => _cancelRequested;

  bool get _isFinal =>
      _state != ExportState.queued && _state != ExportState.running;

  /// Asks the job to stop. Idempotent; no effect in a final state. A
  /// queued job becomes cancelled at once; a running one stops at the
  /// next check of its runner.
  void cancel() {
    if (_isFinal || _cancelRequested) return;
    _cancelRequested = true;
    if (_state == ExportState.queued) {
      _state = ExportState.cancelled;
      _failure = ExportFailure.cancelled;
    }
    notifyListeners();
  }

  /// `queued → running`.
  void start() {
    _expect(ExportState.queued, 'start');
    _state = ExportState.running;
    notifyListeners();
  }

  /// Counts one more page as done while running; never past [total].
  void pageDone() {
    _expect(ExportState.running, 'pageDone');
    if (_done >= total) throw StateError('all $total pages are done');
    _done++;
    notifyListeners();
  }

  /// `running → succeeded` with [files], once every page is done.
  void succeed(List<File> files) {
    _expect(ExportState.running, 'succeed');
    if (_done != total) throw StateError('only $_done of $total pages done');
    _files = List.unmodifiable(files);
    _state = ExportState.succeeded;
    notifyListeners();
  }

  /// `running → failed` with [failure]; a cancel goes through
  /// [markCancelled] instead.
  void fail(ExportFailure failure) {
    if (failure == ExportFailure.cancelled) {
      throw ArgumentError.value(failure, 'failure', 'use markCancelled');
    }
    _expect(ExportState.running, 'fail');
    _end(ExportState.failed, failure);
  }

  /// `running → cancelled`, after the runner saw [cancelRequested].
  void markCancelled() {
    _expect(ExportState.running, 'markCancelled');
    _end(ExportState.cancelled, ExportFailure.cancelled);
  }

  void _end(ExportState state, ExportFailure failure) {
    _state = state;
    _failure = failure;
    notifyListeners();
  }

  void _expect(ExportState expected, String transition) {
    if (_state != expected) {
      throw StateError(
        '$transition needs ${expected.name}, not ${_state.name}',
      );
    }
  }

  static List<ScanPage> _snapshot(List<ScanPage> pages) {
    if (pages.isEmpty) {
      throw ArgumentError.value(pages, 'pages', 'must not be empty');
    }
    return List.unmodifiable(pages);
  }
}
