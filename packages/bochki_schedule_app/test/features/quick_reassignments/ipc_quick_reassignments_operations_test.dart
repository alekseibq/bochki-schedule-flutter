import 'package:bochki_schedule_app/src/features/quick_reassignments/ipc_quick_reassignments_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads snapshot widths and sends updated widths', () async {
    final calls = <String>[];
    final operations =
        IpcQuickReassignmentsOperations((method, arguments) async {
      calls.add(method);
      if (method == 'quickReassignmentsSnapshot') {
        return {
          'workdays': [],
          'humans': [],
          'assistants': [],
          'procedureKinds': [],
          'procedureSessions': [],
          'settings': {
            'minimumTime': {'hour': 8, 'minute': 0},
            'maximumTime': {'hour': 20, 'minute': 0}
          },
          'quickReassignmentsColumnWidths': [100, 200, 300, 400],
        };
      }
      expect(arguments, [110.0, 190.0, 300.0, 400.0]);
      return null;
    });
    await operations.load();
    expect(await operations.loadColumnWidths(), [100, 200, 300, 400]);
    await operations.saveColumnWidths([110, 190, 300, 400]);
    expect(await operations.loadColumnWidths(), [110, 190, 300, 400]);
    expect(calls,
        ['quickReassignmentsSnapshot', 'updateQuickReassignmentsColumnWidths']);
  });
}
