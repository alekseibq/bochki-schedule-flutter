import 'procedure_kind.dart';
import 'procedure_kind_validator.dart';
import 'procedure_kinds_repository.dart';

final class CreateProcedureKindUseCase {
  const CreateProcedureKindUseCase(this._repository);

  final ProcedureKindsRepository _repository;

  Future<ProcedureKind> execute(ProcedureKind procedureKind) async {
    final validatedProcedureKind = ProcedureKindValidator.validateForSave(
      procedureKind,
      existingProcedureKinds: await _repository.list(),
    );
    return _repository.create(validatedProcedureKind);
  }
}
