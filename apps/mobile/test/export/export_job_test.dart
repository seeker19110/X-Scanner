import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/scan_page.dart';
import 'package:x_scanner/export/export_job.dart';

void main() {
  List<ScanPage> pages(int count) => [
    for (var i = 0; i < count; i++)
      ScanPage(id: 'p$i', originalPath: 'originals/p$i.png'),
  ];

  /// A job that ran through all of its pages.
  ExportJob finished(int count) {
    final job = ExportJob(pages(count), ExportFormat.jpeg)..start();
    for (var i = 0; i < count; i++) {
      job.pageDone();
    }
    return job;
  }

  test('new job is queued with a frozen snapshot (AC-1)', () {
    final input = pages(3);
    final job = ExportJob(input, ExportFormat.pdf);

    expect(job.state, ExportState.queued);
    expect(job.done, 0);
    expect(job.total, 3);
    expect(job.files, isNull);
    expect(job.failure, isNull);
    expect(job.cancelRequested, isFalse);
    expect(job.format, ExportFormat.pdf);

    final first = input.first;
    input
      ..removeLast()
      ..[0] = first.rotatedClockwise();
    expect(job.pages, hasLength(3));
    expect(job.pages.first, same(first));
    expect(() => job.pages.add(first), throwsUnsupportedError);
    expect(() => job.pages[0] = first, throwsUnsupportedError);
  });

  test('new job is queued with a frozen snapshot: no pages is rejected '
      '(AC-1)', () {
    expect(() => ExportJob(const [], ExportFormat.png), throwsArgumentError);
  });

  test('job reports progress and its files when it succeeds (AC-1)', () {
    final job = ExportJob(pages(2), ExportFormat.jpeg);
    final seen = <(ExportState, int)>[];
    job.addListener(() => seen.add((job.state, job.done)));

    job.start();
    job.pageDone();
    job.pageDone();
    final files = [File('a.jpg'), File('b.jpg')];
    job.succeed(files);
    files.clear();

    expect(seen, [
      (ExportState.running, 0),
      (ExportState.running, 1),
      (ExportState.running, 2),
      (ExportState.succeeded, 2),
    ]);
    expect([for (final f in job.files!) f.path], ['a.jpg', 'b.jpg']);
    expect(() => job.files!.add(File('c.jpg')), throwsUnsupportedError);
    expect(job.failure, isNull);
  });

  test('illegal transitions throw (AC-1)', () {
    final queued = ExportJob(pages(2), ExportFormat.jpeg);
    expect(() => queued.succeed(const []), throwsStateError);
    expect(queued.pageDone, throwsStateError);
    expect(() => queued.fail(ExportFailure.renderFailed), throwsStateError);
    expect(queued.markCancelled, throwsStateError);
    expect(queued.state, ExportState.queued);

    final running = ExportJob(pages(2), ExportFormat.jpeg)..start();
    expect(running.start, throwsStateError, reason: 'start twice');
    expect(
      () => running.succeed(const []),
      throwsStateError,
      reason: 'pages still to do',
    );
    running
      ..pageDone()
      ..pageDone();
    expect(running.pageDone, throwsStateError, reason: 'done > total');
    expect(running.done, 2);
    expect(
      () => running.fail(ExportFailure.cancelled),
      throwsArgumentError,
      reason: 'a cancel goes through markCancelled',
    );
    expect(running.state, ExportState.running);
  });

  test('a failed job keeps its failure and no files (AC-1)', () {
    final job = ExportJob(pages(2), ExportFormat.pdf)..start();
    job.pageDone();
    job.fail(ExportFailure.writeFailed);
    expect(job.state, ExportState.failed);
    expect(job.failure, ExportFailure.writeFailed);
    expect(job.files, isNull);
    expect(job.done, 1);
  });

  test('final states do not change (AC-1)', () {
    final succeeded = finished(1)..succeed([File('a.jpg')]);
    var notified = 0;
    succeeded.addListener(() => notified++);
    succeeded.cancel();
    expect(succeeded.state, ExportState.succeeded);
    expect(succeeded.cancelRequested, isFalse);
    expect(succeeded.failure, isNull);
    expect(succeeded.files, hasLength(1));
    expect(notified, 0);
    expect(succeeded.start, throwsStateError);
    expect(succeeded.pageDone, throwsStateError);
    expect(() => succeeded.succeed(const []), throwsStateError);
    expect(() => succeeded.fail(ExportFailure.renderFailed), throwsStateError);
    expect(succeeded.markCancelled, throwsStateError);

    final failed = ExportJob(pages(1), ExportFormat.png)
      ..start()
      ..fail(ExportFailure.renderFailed);
    failed.cancel();
    expect(failed.state, ExportState.failed);
    expect(failed.failure, ExportFailure.renderFailed);
    expect(failed.markCancelled, throwsStateError);

    final cancelled = ExportJob(pages(1), ExportFormat.png)..cancel();
    expect(cancelled.start, throwsStateError);
    expect(() => cancelled.fail(ExportFailure.writeFailed), throwsStateError);
    expect(cancelled.state, ExportState.cancelled);
  });

  test('final states do not change: cancel of a queued job ends it at once '
      'and is idempotent (AC-1)', () {
    final job = ExportJob(pages(2), ExportFormat.pdf);
    var notified = 0;
    job.addListener(() => notified++);

    job.cancel();
    expect(job.state, ExportState.cancelled);
    expect(job.failure, ExportFailure.cancelled);
    expect(job.cancelRequested, isTrue);
    expect(job.files, isNull);
    expect(notified, 1);

    job.cancel();
    expect(job.state, ExportState.cancelled);
    expect(notified, 1);
  });

  test('final states do not change: cancel of a running job waits for its '
      'runner (AC-1)', () {
    final job = ExportJob(pages(3), ExportFormat.jpeg)..start();
    job.pageDone();
    var notified = 0;
    job.addListener(() => notified++);

    job.cancel();
    job.cancel();
    expect(job.state, ExportState.running);
    expect(job.cancelRequested, isTrue);
    expect(job.failure, isNull);
    expect(notified, 1);

    job.markCancelled();
    expect(job.state, ExportState.cancelled);
    expect(job.failure, ExportFailure.cancelled);
    expect(job.files, isNull);
    expect(job.done, 1);
    expect(notified, 2);
  });
}
