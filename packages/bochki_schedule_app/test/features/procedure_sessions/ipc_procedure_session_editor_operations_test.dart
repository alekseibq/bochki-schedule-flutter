import 'package:bochki_schedule_app/src/features/procedure_sessions/ipc_procedure_session_editor_operations.dart';
import 'package:bochki_schedule_app/src/domain/procedure_sessions/procedure_session_raw.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and decodes a prefilled editor snapshot', () async {
    final operations =
        IpcProcedureSessionEditorOperations((method, arguments) async {
      expect(method, 'procedureSessionSnapshot');
      return {
        'draft': {
          'id': 'draft',
          'dayId': '1',
          'participantId': '2',
          'startTime': '09:00',
          'procedureKindId': '3',
          'assistantId': null
        },
        'workdays': [
          {'id': '1', 'name': 'День', 'date': '2026-01-02'}
        ],
        'humans': [
          {
            'id': '2',
            'name': 'Анна',
            'shortName': 'А.',
            'isParticipant': true,
            'isAssistant': false
          }
        ],
        'assistants': [],
        'procedureKinds': [
          {
            'id': '3',
            'patternId': 'single',
            'name': 'Процедура',
            'shortName': 'П',
            'participantBusyTime': 30
          }
        ],
        'procedureSessions': [],
        'settings': {
          'minimumTime': {'hour': 8, 'minute': 0},
          'maximumTime': {'hour': 20, 'minute': 0}
        },
      };
    });
    final snapshot = await operations.loadSnapshot();
    expect(snapshot.draft.participantId, '2');
    expect(snapshot.draft.startTime, '09:00');
    expect(snapshot.workdays.single.calendarDate, DateTime(2026, 1, 2));
    expect(snapshot.humans.single.name, 'Анна');
    expect(snapshot.procedureKinds.single.name, 'Процедура');
  });
  test('maps submit and render commands to the child-window protocol',
      () async {
    final calls = <(String, Object?)>[];
    final operations =
        IpcProcedureSessionEditorOperations((method, arguments) async {
      calls.add((method, arguments));
      if (method == 'submitProcedureSession') {
        return {
          'didSave': true,
          'operationId': 7,
          'conflictMessages': const [],
          'errorMessage': ''
        };
      }
      return null;
    });
    final result = await operations.submit(
        ProcedureSessionRaw(
          id: 'draft',
          dayId: 'day',
          participantId: 'participant',
          startTime: '10:00',
          procedureKindId: 'kind',
          assistantId: null,
        ),
        allowConflicts: false);
    await operations.logRenderedSave(7);
    expect(result.didSave, isTrue);
    expect(calls[0].$1, 'submitProcedureSession');
    expect(calls[0].$2, {
      'session': {
        'id': 'draft',
        'dayId': 'day',
        'participantId': 'participant',
        'startTime': '10:00',
        'procedureKindId': 'kind',
        'assistantId': null
      },
      'allowConflicts': false,
    });
    expect(calls[1], ('procedureSessionRendered', 7));
  });
}
