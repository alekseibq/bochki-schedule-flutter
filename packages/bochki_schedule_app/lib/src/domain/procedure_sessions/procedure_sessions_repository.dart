import 'procedure_session_raw.dart';

abstract interface class ProcedureSessionsRepository {
  Future<List<ProcedureSessionRaw>> list();

  Future<ProcedureSessionRaw> create(ProcedureSessionRaw procedureSession);

  Future<ProcedureSessionRaw> update(ProcedureSessionRaw procedureSession);

  Future<void> delete(String procedureSessionId);
}
