final class ProcedureSessionsValidationException implements Exception {
  const ProcedureSessionsValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
