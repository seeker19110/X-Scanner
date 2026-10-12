/// Undo/redo over immutable states, at most [limit] undo steps.
class EditHistory<T> {
  /// Starts at [initial]; throws [ArgumentError] if [limit] is below 1.
  EditHistory(T initial, {this.limit = 100}) : _states = [initial] {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
  }

  /// Maximum number of undo steps kept; older steps are dropped.
  final int limit;

  final List<T> _states;
  int _index = 0;

  /// The state at the current step.
  T get current => _states[_index];

  bool get canUndo => _index > 0;
  bool get canRedo => _index < _states.length - 1;

  /// Records [state] as a new step, clearing redo and dropping the oldest
  /// step beyond [limit].
  void push(T state) {
    _states
      ..removeRange(_index + 1, _states.length)
      ..add(state);
    if (_states.length > limit + 1) _states.removeAt(0);
    _index = _states.length - 1;
  }

  /// Steps back; no-op when ![canUndo].
  void undo() {
    if (canUndo) _index--;
  }

  /// Steps forward; no-op when ![canRedo].
  void redo() {
    if (canRedo) _index++;
  }
}
