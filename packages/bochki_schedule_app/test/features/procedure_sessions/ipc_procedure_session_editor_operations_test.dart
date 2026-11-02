import 'package:bochki_schedule_app/src/features/procedure_sessions/ipc_procedure_session_editor_operations.dart';
import 'package:bochki_schedule_app/src/features/procedure_sessions/procedure_session_editor_view_model.dart';
import 'package:bochki_schedule_app/src/domain/procedure_sessions/procedure_session_raw.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and decodes a prefilled editor snapshot', () async {
    final operations = IpcProcedureSessionEditorOperations(
      (method, arguments) async {
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
      },
      onOpenStatistics: () async {},
      onClose: () async {},
    );
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
    final opened = <String>[];
    final operations = IpcProcedureSessionEditorOperations(
      (method, arguments) async {
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
      },
      onOpenStatistics: () async => opened.add('statistics'),
      onClose: () async => opened.add('close'),
    );
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
    await operations.openStatistics();
    await operations.close();
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
    expect(opened, ['statistics', 'close']);
  });

  test('refreshes an IPC snapshot without replacing the editor ViewModel',
      () async {
    final operations = IpcProcedureSessionEditorOperations(
      (method, arguments) async => {
        'draft': {
          'id': 'draft',
          'dayId': '1',
          'participantId': '2',
          'startTime': '09:00',
          'procedureKindId': '3',
          'assistantId': null,
        },
        'workdays': [
          {'id': '1', 'name': 'День', 'date': '2026-01-02'},
        ],
        'humans': [
          {
            'id': '2',
            'name': 'Анна',
            'shortName': 'А.',
            'isParticipant': true,
            'isAssistant': false,
          },
        ],
        'assistants': [],
        'procedureKinds': [
          {
            'id': '3',
            'patternId': 'single',
            'name': 'Процедура',
            'shortName': 'П',
            'participantBusyTime': 30,
          },
        ],
        'procedureSessions': [],
        'settings': {
          'minimumTime': {'hour': 8, 'minute': 0},
          'maximumTime': {'hour': 20, 'minute': 0},
        },
      },
      onOpenStatistics: () async {},
      onClose: () async {},
    );
    final initial = await operations.loadSnapshot();
    final viewModel = ProcedureSessionEditorViewModel.fromSnapshot(
      snapshot: initial,
      operations: operations,
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.replaceSnapshot(ProcedureSessionEditorSnapshot(
      draft: initial.draft,
      workdays: const [],
      humans: initial.humans,
      procedureKinds: initial.procedureKinds,
      assistants: initial.assistants,
      procedureSessions: initial.procedureSessions,
      programSettings: initial.programSettings,
    ));

    expect(viewModel.createDraft(), same(initial.draft));
    expect(viewModel.workdays, isEmpty);
    expect(notifications, 1);
    viewModel.dispose();
  });
}
