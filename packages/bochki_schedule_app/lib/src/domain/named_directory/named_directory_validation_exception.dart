class NamedDirectoryValidationException implements Exception {
  const NamedDirectoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef NamedDirectoryExceptionFactory = Exception Function(String message);
