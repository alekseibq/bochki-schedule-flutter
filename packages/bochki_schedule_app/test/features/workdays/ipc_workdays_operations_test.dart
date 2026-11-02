import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/domain/workdays/workdays_validation_exception.dart';
import 'package:bochki_schedule_app/src/features/workdays/ipc_workdays_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads and writes column widths over IPC', () async {
    final calls = <String>[];
    final operations = IpcWorkdaysOperations((method, arguments) async {
      calls.add(method);
      if (method == 'directorySnapshot') {
        expect(arguments, 'workdays');
        return {
          'workdaysColumnWidths': [260, 160, 116, 100, 90]
        };
      }
      expect(method, 'updateWorkdaysColumnWidths');
      expect(arguments, [290.0, 130.0, 116.0, 100.0, 90.0]);
      return null;
    });
    expect(await operations.loadColumnWidths(), [260, 160, 116, 100, 90]);
    await operations.saveColumnWidths([290, 130, 116, 100, 90]);
    expect(calls, ['directorySnapshot', 'updateWorkdaysColumnWidths']);
  });
  test('create returns the persisted workday identity and values', () async {
    final operations = IpcWorkdaysOperations((_, __) async => {
          'ok': true,
          'entry': {'id': '42', 'name': 'День 1', 'date': '2026-01-02'},
        });
    final result = await operations.create(
      Workday(id: 'new', name: ' День 1 ', calendarDate: DateTime(2026, 1, 2)),
    );
    expect(result.id, '42');
    expect(result.name, 'День 1');
    expect(result.calendarDate, DateTime(2026, 1, 2));
  });
  test('validation failures retain the workday message', () async {
    final operations = IpcWorkdaysOperations((_, __) async =>
        {'ok': false, 'validation': true, 'error': 'Дата занята'});
    await expectLater(
      operations.create(
          Workday(id: 'new', name: 'День', calendarDate: DateTime(2026))),
      throwsA(isA<WorkdaysValidationException>()
          .having((error) => error.message, 'message', 'Дата занята')),
    );
  });
}
