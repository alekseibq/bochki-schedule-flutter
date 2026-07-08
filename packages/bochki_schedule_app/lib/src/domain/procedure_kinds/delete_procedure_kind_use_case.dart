import 'procedure_kind_validator.dart';
import 'procedure_kinds_repository.dart';

final class DeleteProcedureKindUseCase {
  const DeleteProcedureKindUseCase(this._repository);

  final ProcedureKindsRepository _repository;

  Future<void> execute(String procedureKindId) async {
    ProcedureKindValidator.validateId(procedureKindId);
    await _repository.delete(procedureKindId.trim());
  }
}
