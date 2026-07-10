final class WorkdaysValidationException implements Exception {
  const WorkdaysValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
