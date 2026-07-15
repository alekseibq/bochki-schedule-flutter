import 'list_rich_procedure_sessions_use_case.dart';
import 'procedure_session_conflict_calculator.dart';
import 'procedure_session_with_conflicts.dart';
import 'schedule_conflict.dart';

final class ListProcedureSessionsWithConflictsUseCase {
  ListProcedureSessionsWithConflictsUseCase({
    required ListRichProcedureSessionsUseCase listRichProcedureSessionsUseCase,
    ProcedureSessionConflictCalculator? calculator,
  })  : _listRichProcedureSessionsUseCase = listRichProcedureSessionsUseCase,
        _calculator = calculator ?? const ProcedureSessionConflictCalculator();

  final ListRichProcedureSessionsUseCase _listRichProcedureSessionsUseCase;
  final ProcedureSessionConflictCalculator _calculator;

  Future<List<ProcedureSessionWithConflicts>> execute() async {
    final sessions = await _listRichProcedureSessionsUseCase.execute();
    final conflicts = _calculator.calculate(sessions);
    final conflictsBySessionId = <String, List<ScheduleConflict>>{};
    for (final conflict in conflicts) {
      conflictsBySessionId
          .putIfAbsent(conflict.procedureSessionId, () => <ScheduleConflict>[])
          .add(conflict);
    }

    return [
      for (final session in sessions)
        ProcedureSessionWithConflicts(
          rich: session,
          conflicts: List.unmodifiable(
            conflictsBySessionId[session.id] ?? const <ScheduleConflict>[],
          ),
        ),
    ];
  }
}
