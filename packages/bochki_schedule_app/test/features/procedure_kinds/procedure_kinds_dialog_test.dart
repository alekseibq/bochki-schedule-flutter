import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats assigned procedure count with Russian declension', () {
    expect(
        ProcedureKindsDialog.assignedProcedureWord(1), 'назначенная процедура');
    expect(
        ProcedureKindsDialog.assignedProcedureWord(2), 'назначенные процедуры');
    expect(
        ProcedureKindsDialog.assignedProcedureWord(5), 'назначенных процедур');
    expect(
        ProcedureKindsDialog.assignedProcedureWord(11), 'назначенных процедур');
    expect(ProcedureKindsDialog.assignedProcedureWord(21),
        'назначенная процедура');
  });
}
