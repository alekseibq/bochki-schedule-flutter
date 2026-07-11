import 'procedure_session_raw.dart';
import 'procedure_session_time.dart';
import 'procedure_sessions_repository.dart';

final class ListProcedureSessionsUseCase {
  const ListProcedureSessionsUseCase(this._repository);

  final ProcedureSessionsRepository _repository;

  Future<List<ProcedureSessionRaw>> execute() async {
    final procedureSessions = await _repository.list();
    procedureSessions.sort((left, right) {
      final byDay = left.dayId.compareTo(right.dayId);
      if (byDay != 0) {
        return byDay;
      }

      final byStartTime = ProcedureSessionTime.toMinutes(left.startTime)
          .compareTo(ProcedureSessionTime.toMinutes(right.startTime));
      if (byStartTime != 0) {
        return byStartTime;
      }

      final byProcedureKind =
          left.procedureKindId.compareTo(right.procedureKindId);
      if (byProcedureKind != 0) {
        return byProcedureKind;
      }

      return left.id.compareTo(right.id);
    });
    return List<ProcedureSessionRaw>.unmodifiable(procedureSessions);
  }
}
