final class ProcedureKindInUseException implements Exception {
  const ProcedureKindInUseException(this.referencesCount);

  final int referencesCount;

  @override
  String toString() =>
      'Невозможно удалить процедуру: $referencesCount активных назначений.';
}
