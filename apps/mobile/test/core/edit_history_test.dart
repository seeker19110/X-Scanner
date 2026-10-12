import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/core/edit_history.dart';

void main() {
  test('undo and redo step through states (XS-13 AC-6)', () {
    final history = EditHistory<int>(0);
    expect(history.current, 0);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);

    history
      ..push(1)
      ..push(2)
      ..push(3);
    expect(history.current, 3);
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);

    for (final expected in [2, 1, 0]) {
      history.undo();
      expect(history.current, expected);
      expect(history.canRedo, isTrue);
    }
    expect(history.canUndo, isFalse);

    history.redo();
    expect(history.current, 1);
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isTrue);
  });

  test('undo and redo are no-ops at the ends', () {
    final history = EditHistory<String>('a');
    history.undo();
    expect(history.current, 'a');
    history.redo();
    expect(history.current, 'a');
    history
      ..push('b')
      ..redo();
    expect(history.current, 'b');
  });

  test('a push after undo clears redo', () {
    final history = EditHistory<int>(0)
      ..push(1)
      ..push(2)
      ..undo()
      ..undo()
      ..push(5);
    expect(history.current, 5);
    expect(history.canRedo, isFalse);
    history.undo();
    expect(history.current, 0);
    expect(history.canUndo, isFalse);
  });

  test('keeps at most limit steps', () {
    final history = EditHistory<int>(0, limit: 2)
      ..push(1)
      ..push(2)
      ..push(3);
    history.undo();
    expect(history.current, 2);
    history.undo();
    expect(history.current, 1);
    expect(history.canUndo, isFalse);
    history.undo();
    expect(history.current, 1);
  });

  test('the default limit is 100 steps', () {
    final history = EditHistory<int>(0);
    for (var i = 1; i <= 105; i++) {
      history.push(i);
    }
    var undos = 0;
    while (history.canUndo) {
      history.undo();
      undos++;
    }
    expect(undos, 100);
    expect(history.current, 5);
  });

  test('a limit below 1 is rejected', () {
    expect(() => EditHistory<int>(0, limit: 0), throwsArgumentError);
    expect(() => EditHistory<int>(0, limit: -3), throwsArgumentError);
  });
}
