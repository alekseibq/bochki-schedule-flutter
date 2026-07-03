final class ParticipantsValidationException implements Exception {
  const ParticipantsValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
