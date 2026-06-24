abstract interface class IdGenerator {
  int nextId();
}

final class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator({int startAt = 1})
      : assert(startAt > 0, 'startAt must be positive'),
        _currentValue = startAt - 1;

  int _currentValue;

  int get currentValue => _currentValue;

  @override
  int nextId() {
    _currentValue += 1;
    return _currentValue;
  }
}
