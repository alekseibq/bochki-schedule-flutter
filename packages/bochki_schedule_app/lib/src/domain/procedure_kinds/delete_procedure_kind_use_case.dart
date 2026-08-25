import 'procedure_kind_validator.dart';
import 'procedure_kind_in_use_exception.dart';
import 'procedure_kinds_repository.dart';
import '../procedure_sessions/procedure_session_raw.dart';
import '../procedure_sessions/procedure_sessions_repository.dart';

final class DeleteProcedureKindUseCase {
  const DeleteProcedureKindUseCase(
    this._repository, {
    required ProcedureSessionsRepository procedureSessionsRepository,
  }) : _procedureSessionsRepository = procedureSessionsRepository;

  final ProcedureKindsRepository _repository;
  final ProcedureSessionsRepository _procedureSessionsRepository;

  Future<int> countReferences(String procedureKindId) async {
    ProcedureKindValidator.validateId(procedureKindId);
    return _affectedSessions(
      await _procedureSessionsRepository.list(),
      procedureKindId.trim(),
    ).length;
  }

  Future<void> execute(String procedureKindId) async {
    ProcedureKindValidator.validateId(procedureKindId);
    final normalizedId = procedureKindId.trim();
    final referencesCount = await countReferences(normalizedId);
    if (referencesCount > 0) {
      throw ProcedureKindInUseException(referencesCount);
    }
    await _repository.delete(normalizedId);
  }

  static List<ProcedureSessionRaw> _affectedSessions(
    List<ProcedureSessionRaw> sessions,
    String procedureKindId,
  ) =>
      sessions
          .where((session) => session.procedureKindId == procedureKindId)
          .toList(growable: false);
}
