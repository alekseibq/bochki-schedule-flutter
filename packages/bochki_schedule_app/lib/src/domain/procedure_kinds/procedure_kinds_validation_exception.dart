final class ProcedureKindsValidationException implements Exception {
  const ProcedureKindsValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
