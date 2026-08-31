import '../../domain/procedure_kinds/create_procedure_kind_use_case.dart';
import '../../domain/procedure_kinds/delete_procedure_kind_use_case.dart';
import '../../domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_kinds/update_procedure_kind_use_case.dart';

/// Operations required by the procedure kinds UI, independent of its host.
abstract interface class ProcedureKindsOperations {
  Future<List<ProcedureKind>> list();

  Future<ProcedureKind> create(ProcedureKind procedureKind);

  Future<ProcedureKind> update(ProcedureKind procedureKind);

  Future<int> countReferences(String procedureKindId);

  Future<void> delete(String procedureKindId);
}

final class UseCaseProcedureKindsOperations
    implements ProcedureKindsOperations {
  const UseCaseProcedureKindsOperations({
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required CreateProcedureKindUseCase createProcedureKindUseCase,
    required UpdateProcedureKindUseCase updateProcedureKindUseCase,
    required DeleteProcedureKindUseCase deleteProcedureKindUseCase,
  })  : _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _createProcedureKindUseCase = createProcedureKindUseCase,
        _updateProcedureKindUseCase = updateProcedureKindUseCase,
        _deleteProcedureKindUseCase = deleteProcedureKindUseCase;

  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final CreateProcedureKindUseCase _createProcedureKindUseCase;
  final UpdateProcedureKindUseCase _updateProcedureKindUseCase;
  final DeleteProcedureKindUseCase _deleteProcedureKindUseCase;

  @override
  Future<List<ProcedureKind>> list() => _listProcedureKindsUseCase.execute();

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) =>
      _createProcedureKindUseCase.execute(procedureKind);

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) =>
      _updateProcedureKindUseCase.execute(procedureKind);

  @override
  Future<int> countReferences(String procedureKindId) =>
      _deleteProcedureKindUseCase.countReferences(procedureKindId);

  @override
  Future<void> delete(String procedureKindId) =>
      _deleteProcedureKindUseCase.execute(procedureKindId);
}
