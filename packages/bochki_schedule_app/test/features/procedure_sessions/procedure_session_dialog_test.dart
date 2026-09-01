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
            humans: [
              Human(
                id: '1',
                name: 'Иван',
                isParticipant: true,
                isAssistant: false,
              ),
              Human(
                id: '2',
                name: 'Петр',
                isParticipant: false,
                isAssistant: true,
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
              minimumTime: ProgramSettingsTime(hour: 10, minute: 0),
              maximumTime: ProgramSettingsTime(hour: 12, minute: 0),
            ),
            onSubmit: (_, __) async =>
                const ProcedureSessionSubmitResult.saved(1),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Доступные часы начала: 10-12. Обед: с 13:30 до 14:30.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('procedure_session_hour_field')));
    await tester.pumpAndSettle();

    expect(find.text('10').last, findsOneWidget);
    expect(find.text('11').last, findsOneWidget);
    expect(find.text('12').last, findsOneWidget);
    expect(find.text('09'), findsNothing);

    await tester
        .tap(find.byKey(const Key('procedure_session_participant_field')));
    await tester.pumpAndSettle();

    expect(find.text('Петр').last, findsOneWidget);
  });

  testWidgets('grouped procedure requires an enabled assistant field', (
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
            ),
            workdays: [
              Workday(
                id: '1',
                name: 'День 1',
                calendarDate: DateTime(2026, 7, 11),
              ),
            ],
            humans: [
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
                patternId: ProcedureKindPatterns.grouped.patternId,
                name: 'Медитация',
                capacity: 6,
                participantBusyTime: 30,
              ).sanitizedForPersistence(),
            ],
            assistants: [
              Assistant(id: '2', name: 'Петр'),
            ],
            programSettings: ProgramSettings.defaults,
            onSubmit: (_, __) async =>
                const ProcedureSessionSubmitResult.saved(1),
          ),
        ),
      ),
    );

    final field = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('procedure_session_assistant_field')),
    );

    expect(field.onChanged, isNotNull);
    expect(find.text('Выберите ассистента'), findsOneWidget);
  });

  testWidgets('cancel delegates closing to the dialog owner', (tester) async {
    var closeRequests = 0;
    var submitRequests = 0;

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
            ),
            workdays: [
              Workday(
                id: '1',
                name: 'День 1',
                calendarDate: DateTime(2026, 7, 11),
              ),
            ],
            humans: [
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
              ),
            ],
            assistants: const [],
            programSettings: ProgramSettings.defaults,
            onSubmit: (_, __) async {
              submitRequests += 1;
              return const ProcedureSessionSubmitResult.saved(1);
            },
            onClose: () {
              closeRequests += 1;
            },
          ),
        ),
      ),
    );

    final cancel = tester.widget<TextButton>(find.widgetWithText(
      TextButton,
      'Отмена',
    ));
    cancel.onPressed!();
    await tester.pump();

    expect(closeRequests, 1);
    expect(submitRequests, 0);
  });

  testWidgets('a fresh key resets the form from a refreshed snapshot',
      (tester) async {
    Widget buildDialog(ProcedureSessionRaw initialValue) => MaterialApp(
          home: Material(
            child: ProcedureSessionDialog(
              key: ValueKey(initialValue.id),
              initialValue: initialValue,
              workdays: [
                Workday(
                  id: '1',
                  name: 'День 1',
                  calendarDate: DateTime(2026, 7, 11),
                ),
                Workday(
                  id: '2',
                  name: 'День 2',
                  calendarDate: DateTime(2026, 7, 12),
                ),
              ],
              humans: const [],
              procedureKinds: [
                ProcedureKind(
                  id: '1',
                  patternId: ProcedureKindPatterns.curated.patternId,
                  name: 'Бочка',
                  capacity: 6,
                  participantBusyTime: 30,
                ),
              ],
              assistants: const [],
              programSettings: ProgramSettings.defaults,
              onSubmit: (_, __) async =>
                  const ProcedureSessionSubmitResult.saved(1),
            ),
          ),
        );

    await tester.pumpWidget(buildDialog(ProcedureSessionRaw(
      id: 'first',
      dayId: '1',
      startTime: '10:00',
      procedureKindId: '1',
    )));
    expect(
      tester
          .widget<DropdownButton<String>>(
            find.descendant(
              of: find.byKey(const Key('procedure_session_day_field')),
              matching: find.byType(DropdownButton<String>),
            ),
          )
          .value,
      '1',
    );

    await tester.pumpWidget(buildDialog(ProcedureSessionRaw(
      id: 'second',
      dayId: '2',
      startTime: '11:00',
      procedureKindId: '1',
    )));
    expect(
      tester
          .widget<DropdownButton<String>>(
            find.descendant(
              of: find.byKey(const Key('procedure_session_day_field')),
              matching: find.byType(DropdownButton<String>),
            ),
          )
          .value,
      '2',
    );
  });
}
