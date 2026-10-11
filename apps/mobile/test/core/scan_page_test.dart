import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/page_quad.dart';
import 'package:x_scanner/core/scan_page.dart';

final PageQuad _cropped = PageQuad(
  topLeft: const Point<double>(0.1, 0.1),
  topRight: const Point<double>(0.9, 0.1),
  bottomRight: const Point<double>(0.9, 0.9),
  bottomLeft: const Point<double>(0.1, 0.9),
);

void main() {
  test('defaults to full frame and no rotation', () {
    final page = ScanPage(id: 'p1', originalPath: 'originals/p1.jpg');
    expect(page.id, 'p1');
    expect(page.originalPath, 'originals/p1.jpg');
    expect(page.quad, PageQuad.fullFrame);
    expect(page.quarterTurns, 0);
  });

  test('edits keep the original', () {
    final original = ScanPage(id: 'p1', originalPath: 'originals/p1.jpg');

    final cropped = original.withQuad(_cropped);
    expect(identical(cropped, original), isFalse);
    expect(cropped.id, 'p1');
    expect(cropped.originalPath, 'originals/p1.jpg');
    expect(cropped.quad, _cropped);
    expect(cropped.quarterTurns, 0);

    final rotated = cropped.rotatedClockwise();
    expect(identical(rotated, cropped), isFalse);
    expect(rotated.id, 'p1');
    expect(rotated.originalPath, 'originals/p1.jpg');
    expect(rotated.quad, _cropped);
    expect(rotated.quarterTurns, 1);

    // Earlier pages are untouched.
    expect(original.quad, PageQuad.fullFrame);
    expect(original.quarterTurns, 0);
    expect(cropped.quarterTurns, 0);
  });

  test('normalizes quarter turns', () {
    expect(
      ScanPage(id: 'a', originalPath: 'o', quarterTurns: 5).quarterTurns,
      1,
    );
    expect(
      ScanPage(id: 'a', originalPath: 'o', quarterTurns: -1).quarterTurns,
      3,
    );
    expect(
      ScanPage(id: 'a', originalPath: 'o', quarterTurns: 4).quarterTurns,
      0,
    );
    expect(
      ScanPage(id: 'a', originalPath: 'o', quarterTurns: -6).quarterTurns,
      2,
    );

    var page = ScanPage(id: 'a', originalPath: 'o');
    for (var i = 0; i < 4; i++) {
      page = page.rotatedClockwise();
    }
    expect(page.quarterTurns, 0);

    final fromThree = ScanPage(id: 'a', originalPath: 'o', quarterTurns: 3);
    expect(fromThree.rotatedClockwise().quarterTurns, 0);
  });

  test('rejects empty or blank id and originalPath', () {
    expect(() => ScanPage(id: '', originalPath: 'o'), throwsArgumentError);
    expect(() => ScanPage(id: '  \t', originalPath: 'o'), throwsArgumentError);
    expect(() => ScanPage(id: 'a', originalPath: ''), throwsArgumentError);
    expect(() => ScanPage(id: 'a', originalPath: ' \n '), throwsArgumentError);
  });
}
