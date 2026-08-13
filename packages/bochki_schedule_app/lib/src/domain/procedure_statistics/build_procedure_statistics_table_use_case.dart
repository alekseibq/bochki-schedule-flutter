import '../humans/list_humans_use_case.dart';
import '../procedure_kinds/list_procedure_kinds_use_case.dart';
import '../procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../workdays/list_workdays_use_case.dart';
import 'procedure_statistics_table.dart';

final class BuildProcedureStatisticsTableUseCase {
  BuildProcedureStatisticsTableUseCase(
      {required ListWorkdaysUseCase listWorkdaysUseCase,
      required ListHumansUseCase listHumansUseCase,
      required ListProcedureKindsUseCase listProcedureKindsUseCase,
      required ListRichProcedureSessionsUseCase
          listRichProcedureSessionsUseCase})
      : _days = listWorkdaysUseCase,
        _humans = listHumansUseCase,
        _kinds = listProcedureKindsUseCase,
        _sessions = listRichProcedureSessionsUseCase;
  final ListWorkdaysUseCase _days;
  final ListHumansUseCase _humans;
  final ListProcedureKindsUseCase _kinds;
  final ListRichProcedureSessionsUseCase _sessions;
  Future<ProcedureStatisticsTable> execute(
      {String? dayId,
      required ProcedureStatisticsPeopleFilter peopleFilter,
      required ProcedureStatisticsMode mode}) async {
    await _days.execute();
    final people = (await _humans.execute())
        .where((h) => switch (peopleFilter) {
              ProcedureStatisticsPeopleFilter.all => true,
              ProcedureStatisticsPeopleFilter.participants => !h.isAssistant,
              ProcedureStatisticsPeopleFilter.assistants => h.isAssistant
            })
        .toList();
    final kinds = (await _kinds.execute())
        .where((k) =>
            mode == ProcedureStatisticsMode.participation || k.usesAssistant)
        .toList();
    final kindIds = kinds.map((k) => k.id).toSet();
    final counts = <String, int>{};
    for (final session in await _sessions.execute()) {
      if (dayId != null && session.dayId != dayId ||
          !kindIds.contains(session.procedureKindId)) {
        continue;
      }
      final personId = mode == ProcedureStatisticsMode.participation
          ? session.participantId
          : session.assistantId;
      if (personId != null) {
        counts.update('$personId/${session.procedureKindId}', (n) => n + 1,
            ifAbsent: () => 1);
      }
    }
    return ProcedureStatisticsTable(
        people: people, kinds: kinds, counts: counts);
  }
}
