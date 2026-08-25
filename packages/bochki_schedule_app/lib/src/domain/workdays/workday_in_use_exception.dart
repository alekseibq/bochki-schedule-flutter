final class WorkdayInUseException implements Exception {
  const WorkdayInUseException(this.referencesCount);

  final int referencesCount;

  @override
  String toString() =>
      'Невозможно удалить день: найдено $referencesCount назначенных процедур.';
}
