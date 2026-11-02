import 'dart:async';

import 'package:bochki_schedule_app/src/domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import 'package:bochki_schedule_app/src/domain/schedule_gaps/schedule_gap.dart';
import 'package:bochki_schedule_app/src/domain/humans/human.dart';
import 'package:bochki_schedule_app/src/domain/workdays/workday.dart';
import 'package:bochki_schedule_app/src/features/free_time/free_time_dialog.dart';
import 'package:bochki_schedule_app/src/features/free_time/free_time_operations.dart';
import 'package:bochki_schedule_app/src/features/free_time/free_time_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

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

class _ImmediateOperations implements FreeTimeOperations {
  _ImmediateOperations(this.gaps);

  final List<ScheduleGap> gaps;

  @override
  Future<List<ScheduleGap>> build(ScheduleGapsQuery query) async => gaps;

  @override
  Future<List<Workday>> listWorkdays() async =>
      gaps.map((gap) => gap.workday).toSet().toList();
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

  testWidgets('shared free-time content scrolls vertically with a scrollbar',
      (tester) async {
    final day = Workday(
      id: 'day',
      name: 'День',
      calendarDate: DateTime(2026, 8, 25),
    );
    final gaps = List.generate(
      20,
      (index) => ScheduleGap(
        workday: day,
        human: Human(id: 'human-$index', name: 'Человек $index'),
        startMinutes: 8 * 60,
        endMinutes: 9 * 60,
      ),
    );
    final viewModel = FreeTimeViewModel.fromOperations(
      _ImmediateOperations(gaps),
    );
    await viewModel.load();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 180,
          child: FreeTimeContent(
            viewModel: viewModel,
            onOccupy: (_) async {},
          ),
        ),
      ),
    ));

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    final verticalScrollView = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .firstWhere((view) => view.scrollDirection == Axis.vertical);

    expect(scrollbar.thumbVisibility, isTrue);
    expect(verticalScrollView.controller!.position.maxScrollExtent,
        greaterThan(0));
    verticalScrollView.controller!.jumpTo(50);
    await tester.pump();
    expect(verticalScrollView.controller!.offset, 50);

    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });
}
