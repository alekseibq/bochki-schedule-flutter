import 'package:bochki_schedule_app/src/domain/humans/human.dart';
import 'package:bochki_schedule_app/src/domain/procedure_kinds/procedure_kind.dart';
import 'package:bochki_schedule_app/src/domain/procedure_kinds/procedure_kind_pattern.dart';
import 'package:bochki_schedule_app/src/domain/procedure_statistics/procedure_statistics_table.dart';
import 'package:bochki_schedule_app/src/features/procedure_statistics/procedure_statistics_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows full names and abbreviated procedure headers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final person = Human(id: 'anna', name: 'Анна Полностью');
    final kind = ProcedureKind(
      id: 'bath',
      patternId: ProcedureKindPatterns.single.patternId,
      name: 'Длинная процедура',
      capacity: 1,
      participantBusyTime: 30,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProcedureStatisticsContent(
          workdays: const [],
          people: [person],
          kinds: [kind],
          countFor: (_, __) => 2,
          isLoading: false,
          error: null,
          dayId: null,
          peopleFilter: ProcedureStatisticsPeopleFilter.all,
          mode: ProcedureStatisticsMode.participation,
          onDayChanged: (_) {},
          onPeopleChanged: (_) {},
          onModeChanged: (_) {},
        ),
      ),
    ));

    expect(find.text('Анна Полностью'), findsOneWidget);
    expect(find.text('Длин...'), findsOneWidget);
    expect(find.text('Длинная процедура'), findsNothing);
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });
}
