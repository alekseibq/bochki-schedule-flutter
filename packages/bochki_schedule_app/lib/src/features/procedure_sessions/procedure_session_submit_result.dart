final class ProcedureSessionSubmitResult {
  const ProcedureSessionSubmitResult._({
    required this.didSave,
    this.conflictMessages = const [],
    this.errorMessage,
  });

  const ProcedureSessionSubmitResult.saved()
      : this._(
          didSave: true,
        );

  const ProcedureSessionSubmitResult.conflicts(List<String> conflictMessages)
      : this._(
          didSave: false,
          conflictMessages: conflictMessages,
        );

  const ProcedureSessionSubmitResult.error(String errorMessage)
      : this._(
          didSave: false,
          errorMessage: errorMessage,
        );

  final bool didSave;
  final List<String> conflictMessages;
  final String? errorMessage;

  bool get hasConflicts => conflictMessages.isNotEmpty;
}
