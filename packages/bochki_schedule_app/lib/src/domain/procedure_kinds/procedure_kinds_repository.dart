import 'procedure_kind.dart';

abstract interface class ProcedureKindsRepository {
  Future<List<ProcedureKind>> list();

  Future<ProcedureKind> create(ProcedureKind procedureKind);

  Future<ProcedureKind> update(ProcedureKind procedureKind);

  Future<void> delete(String procedureKindId);
}
