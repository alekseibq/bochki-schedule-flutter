import 'procedure_session_raw.dart';

abstract interface class ProcedureSessionsRepository {
  Future<List<ProcedureSessionRaw>> list();

  Future<ProcedureSessionRaw> create(ProcedureSessionRaw procedureSession);

  Future<ProcedureSessionRaw> update(ProcedureSessionRaw procedureSession);

  /// Replaces a group of existing sessions as one logical operation.
  /// Implementations must not expose a partially replaced group.
  Future<void> updateMany(List<ProcedureSessionRaw> procedureSessions) async {
    for (final session in procedureSessions) {
      await update(session);
    }
  }

  Future<void> delete(String procedureSessionId);
}
