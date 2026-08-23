import 'procedure_sessions_repository.dart';

final class ClearProcedureSessionsUseCase {
  const ClearProcedureSessionsUseCase(this._repository);

  final ProcedureSessionsRepository _repository;

  Future<int> execute() => _repository.clearAll();
}
