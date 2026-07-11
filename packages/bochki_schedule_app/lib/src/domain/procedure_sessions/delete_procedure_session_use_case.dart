import 'procedure_session_validator.dart';
import 'procedure_sessions_repository.dart';

final class DeleteProcedureSessionUseCase {
  const DeleteProcedureSessionUseCase(this._repository);

  final ProcedureSessionsRepository _repository;

  Future<void> execute(String procedureSessionId) {
    ProcedureSessionValidator.validateId(procedureSessionId);
    return _repository.delete(procedureSessionId);
  }
}
