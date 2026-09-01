final class ProcedureSessionSubmitResult {
  const ProcedureSessionSubmitResult._({
    required this.didSave,
    this.conflictMessages = const [],
    this.errorMessage,
    this.operationId,
  });

  const ProcedureSessionSubmitResult.saved(int operationId)
      : this._(
          didSave: true,
          operationId: operationId,
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
  final int? operationId;

  bool get hasConflicts => conflictMessages.isNotEmpty;
}
