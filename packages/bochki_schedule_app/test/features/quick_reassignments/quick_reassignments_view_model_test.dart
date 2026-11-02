import 'package:bochki_schedule_app/src/features/quick_reassignments/quick_reassignments_operations.dart';
import 'package:bochki_schedule_app/src/features/quick_reassignments/quick_reassignments_view_model.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and saves column widths through the operations boundary',
      () async {
    List<double>? saved;
    final viewModel = QuickReassignmentsViewModel(
      operations: QuickReassignmentsOperationsAdapter(
        load: () async => QuickReassignmentsSnapshot(
          workdays: const [],
          humans: const [],
          assistants: const [],
          procedureKinds: const [],
          programSettings: ProgramSettings.defaults,
          entries: const [],
        ),
        mutate: (_) async {},
        loadColumnWidths: () async => [100, 200, 300, 400],
        saveColumnWidths: (widths) async => saved = widths,
      ),
    );
    await viewModel.load();
    expect(viewModel.columnWidths, [100, 200, 300, 400]);
    await viewModel.saveColumnWidths([110, 190, 300, 400]);
    expect(saved, [110, 190, 300, 400]);
    viewModel.dispose();
  });
}
