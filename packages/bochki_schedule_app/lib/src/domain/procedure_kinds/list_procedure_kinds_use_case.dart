import 'procedure_kind.dart';
import 'procedure_kinds_repository.dart';

final class ListProcedureKindsUseCase {
  const ListProcedureKindsUseCase(this._repository);

  final ProcedureKindsRepository _repository;

  Future<List<ProcedureKind>> execute() async {
    final procedureKinds = await _repository.list();
    procedureKinds.sort(
      (left, right) => ProcedureKind.sortKeyForName(left.name)
          .compareTo(ProcedureKind.sortKeyForName(right.name)),
    );
    return List<ProcedureKind>.unmodifiable(procedureKinds);
  }
}
