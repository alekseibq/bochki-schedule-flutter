import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dialog shows settings-driven hint and hour options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ProcedureSessionDialog(
            initialValue: ProcedureSessionRaw(
              id: 'draft',
              dayId: '1',
              participantId: '1',
              startTime: '10:00',
              procedureKindId: '1',
              assistantId: '2',
            ),
            workdays: [
              Workday(
                id: '1',
                name: 'День 1',
                calendarDate: DateTime(2026, 7, 11),
              ),
            ],
            participants: [
              Human(
                id: '1',
                name: 'Иван',
                isParticipant: true,
                isAssistant: false,
              ),
            ],
            procedureKinds: [
              ProcedureKind(
                id: '1',
                patternId: ProcedureKindPatterns.curated.patternId,
                name: 'Бочка',
                capacity: 6,
                participantBusyTime: 30,
                assistantBusyTime: 10,
              ),
            ],
            assistants: [
              Assistant(id: '2', name: 'Петр'),
            ],
            programSettings: const ProgramSettings(
              lunchStart: ProgramSettingsTime(hour: 13, minute: 30),
              lunchEnd: ProgramSettingsTime(hour: 14, minute: 30),
              minimumHour: 10,
              maximumHour: 12,
            ),
            onSubmit: (_, __) async =>
                const ProcedureSessionSubmitResult.saved(),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Допустимое время начала: 10:00-12:55. Обед: с 13:30 до 14:30.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('procedure_session_hour_field')));
    await tester.pumpAndSettle();

    expect(find.text('10').last, findsOneWidget);
    expect(find.text('11').last, findsOneWidget);
    expect(find.text('12').last, findsOneWidget);
    expect(find.text('09'), findsNothing);
  });
}
