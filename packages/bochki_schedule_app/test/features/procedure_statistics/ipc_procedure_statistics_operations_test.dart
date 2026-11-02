import 'package:bochki_schedule_app/src/domain/procedure_statistics/procedure_statistics_table.dart';
import 'package:bochki_schedule_app/src/features/procedure_statistics/ipc_procedure_statistics_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards filters and decodes the statistics snapshot', () async {
    final operations =
        IpcProcedureStatisticsOperations((method, arguments) async {
      expect(method, 'statistics');
      expect(arguments,
          {'dayId': '1', 'peopleFilter': 'assistants', 'mode': 'assisting'});
      return {
        'workdays': [
          {'id': '1', 'name': 'День', 'date': '2026-01-02'}
        ],
        'people': [
          {
            'id': '2',
            'name': 'Анна',
            'shortName': 'А.',
            'isParticipant': false,
            'isAssistant': true
          }
        ],
        'kinds': [
          {
            'id': '3',
            'patternId': 'single',
            'name': 'Процедура',
            'shortName': 'П',
            'participantBusyTime': 30
          }
        ],
        'counts': {'2/3': 4},
      };
    });
    final result = await operations.load(
        dayId: '1',
        peopleFilter: ProcedureStatisticsPeopleFilter.assistants,
        mode: ProcedureStatisticsMode.assisting);
    expect(result.workdays.single.calendarDate, DateTime(2026, 1, 2));
    expect(
        result.table
            .count(result.table.people.single, result.table.kinds.single),
        4);
  });
}
