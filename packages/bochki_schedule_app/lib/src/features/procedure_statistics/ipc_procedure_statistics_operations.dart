import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/workday.dart';
import 'procedure_statistics_operations.dart';

final class IpcProcedureStatisticsOperations
    implements ProcedureStatisticsOperations {
  const IpcProcedureStatisticsOperations(this._invoke);
  final Future<Object?> Function(String method, Object? arguments) _invoke;

  @override
  Future<ProcedureStatisticsSnapshot> load(
      {required String? dayId,
      required ProcedureStatisticsPeopleFilter peopleFilter,
      required ProcedureStatisticsMode mode}) async {
    final result = Map<String, dynamic>.from(await _invoke('statistics', {
      'dayId': dayId,
      'peopleFilter': peopleFilter.name,
      'mode': mode.name,
    }) as Map);
    List<Map<String, dynamic>> maps(String key) => (result[key] as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    return ProcedureStatisticsSnapshot(
      workdays: maps('workdays')
          .map((m) => Workday(
              id: m['id'] as String,
              name: m['name'] as String,
              calendarDate: DateTime.parse(m['date'] as String)))
          .toList(),
      table: ProcedureStatisticsTable(
        people: maps('people')
            .map((m) => Human(
                id: m['id'] as String,
                name: m['name'] as String,
                shortName: m['shortName'] as String,
                isParticipant: m['isParticipant'] as bool,
                isAssistant: m['isAssistant'] as bool))
            .toList(),
        kinds: maps('kinds')
            .map((m) => ProcedureKind(
                id: m['id'] as String,
                patternId: m['patternId'] as String,
                name: m['name'] as String,
                shortName: m['shortName'] as String,
                capacity: m['capacity'] as int?,
                useCapacityRestriction:
                    m['useCapacityRestriction'] as bool? ?? true,
                participantBusyTime: m['participantBusyTime'] as int,
                assistantBusyTime: m['assistantBusyTime'] as int?,
                resourceBusyTime: m['resourceBusyTime'] as int?))
            .toList(),
        counts: Map<String, int>.from(result['counts'] as Map? ?? const {}),
      ),
    );
  }
}
