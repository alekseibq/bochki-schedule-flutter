import 'package:bochki_schedule_app/src/features/procedure_sessions/ipc_procedure_session_editor_operations.dart';
import 'package:bochki_schedule_app/src/domain/procedure_sessions/procedure_session_raw.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
