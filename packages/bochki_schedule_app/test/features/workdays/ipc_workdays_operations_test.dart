import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/domain/workdays/workdays_validation_exception.dart';
import 'package:bochki_schedule_app/src/features/workdays/ipc_workdays_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
