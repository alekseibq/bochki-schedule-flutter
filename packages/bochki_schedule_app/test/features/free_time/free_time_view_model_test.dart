import 'dart:async';

import 'package:bochki_schedule_app/src/domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import 'package:bochki_schedule_app/src/domain/schedule_gaps/schedule_gap.dart';
import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/features/free_time/free_time_operations.dart';
import 'package:bochki_schedule_app/src/features/free_time/free_time_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Operations implements FreeTimeOperations {
  final pending = <Completer<List<ScheduleGap>>>[];
  final queries = <ScheduleGapsQuery>[];

  @override
  Future<List<Workday>> listWorkdays() async => const [];

  @override
  Future<List<ScheduleGap>> build(ScheduleGapsQuery query) {
    queries.add(query);
    final result = Completer<List<ScheduleGap>>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  test('newer filter results win over an older response', () async {
    final operations = _Operations();
    final viewModel = FreeTimeViewModel.fromOperations(operations);
    final first = viewModel.load();
    await Future<void>.delayed(Duration.zero);
    final second = viewModel.setMinimumDuration(60);
    await Future<void>.delayed(Duration.zero);
    expect(operations.queries.map((query) => query.minimumDurationMinutes),
        [30, 60]);
    operations.pending[1].complete([]);
    await second;
    expect(viewModel.isLoading, false);
    operations.pending[0].completeError(StateError('stale'));
    await first;
    expect(viewModel.error, isNull);
    viewModel.dispose();
  });

  test('disposing while loading does not notify after disposal', () async {
    final operations = _Operations();
    final viewModel = FreeTimeViewModel.fromOperations(operations);
    final load = viewModel.load();
    await Future<void>.delayed(Duration.zero);
    viewModel.dispose();
    operations.pending.single.complete([]);
    await load;
  });
}
