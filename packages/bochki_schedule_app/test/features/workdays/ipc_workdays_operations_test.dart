import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/domain/workdays/workdays_validation_exception.dart';
import 'package:bochki_schedule_app/src/features/workdays/ipc_workdays_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
