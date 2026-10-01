import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds capacity-aware procedure and person schedule tooltips', () {
    final day = Workday(
      id: 'day',
      name: 'Суббота',
      calendarDate: DateTime(2026, 7, 11),
    );
    final kind = ProcedureKind(
      id: 'kind',
      patternId: ProcedureKindPatterns.grouped.patternId,
      name: 'Групповая процедура',
      shortName: 'Группа',
      capacity: 2,
      participantBusyTime: 30,
      assistantBusyTime: 30,
      resourceBusyTime: 60,
    );
    final humans = [
      Human(
        id: 'anna',
        name: 'Анна',
        procedureRoles: const [ProcedureRole.client, ProcedureRole.companion],
      ),
      Human(id: 'boris', name: 'Борис'),
    ];
    final assistants = [Assistant(id: 'assistant', name: 'Ася')];
    final sessions = [
      ProcedureSessionRaw(
        id: 'first',
        dayId: day.id,
        participantId: 'anna',
        startTime: '09:00',
        procedureKindId: kind.id,
        assistantId: 'assistant',
      ),
      ProcedureSessionRaw(
        id: 'second',
        dayId: day.id,
        participantId: 'anna',
        startTime: '10:00',
        procedureKindId: kind.id,
        assistantId: 'assistant',
      ),
      ProcedureSessionRaw(
        id: 'third',
        dayId: day.id,
        participantId: 'boris',
        startTime: '10:00',
        procedureKindId: kind.id,
        assistantId: 'assistant',
      ),
    ];
    const builder = ProcedureSessionTooltipBuilder();

    final availability = builder.procedureAvailability(
      dayId: day.id,
      procedureKindId: kind.id,
      editingSessionId: '',
      savedSessions: sessions,
      workdays: [day],
      procedureKinds: [kind],
      programSettings: ProgramSettings.defaults,
    );
    expect(availability.title, 'Свободные интервалы для процедуры в Суббота');
    expect(
      availability.lines.map((line) => line.text),
      ['08:00-10:00', '11:00-20:00'],
    );

    final participant = builder.personSchedule(
      humanId: 'anna',
      humanName: 'Анна',
      dayId: day.id,
      savedSessions: sessions,
      workdays: [day],
      humans: humans,
      procedureKinds: [kind],
      assistants: assistants,
      programSettings: ProgramSettings.defaults,
    );
    expect(participant.lines.first.text, '09:00-09:30 Группа — асс. Ася');
    expect(participant.lines.first.tone, ProcedureSessionTooltipTone.companion);

    final assistant = builder.personSchedule(
      humanId: 'assistant',
      humanName: 'Ася',
      dayId: day.id,
      savedSessions: sessions,
      workdays: [day],
      humans: humans,
      procedureKinds: [kind],
      assistants: assistants,
      programSettings: ProgramSettings.defaults,
    );
    expect(
      assistant.lines.map((line) => line.text),
      [
        '09:00-09:30 Группа-АССИСТЕНТ — уч. Анна',
        '10:00-10:30 Группа-АССИСТЕНТ — уч. Анна, Борис'
      ],
    );
  });

  test('builds main table person schedule tooltip with current grouped entry',
      () {
    final day = Workday(
      id: 'day',
      name: 'Суббота',
      calendarDate: DateTime(2026, 7, 11),
    );
    final single = ProcedureKind(
      id: 'single',
      patternId: ProcedureKindPatterns.single.patternId,
      name: 'Одиночная',
      capacity: 1,
      participantBusyTime: 20,
    );
    final curated = ProcedureKind(
      id: 'curated',
      patternId: ProcedureKindPatterns.curated.patternId,
      name: 'Парная',
      capacity: 1,
      participantBusyTime: 30,
      assistantBusyTime: 15,
    );
    final grouped = ProcedureKind(
      id: 'grouped',
      patternId: ProcedureKindPatterns.grouped.patternId,
      name: 'Медитация',
      capacity: 2,
      participantBusyTime: 40,
      assistantBusyTime: 25,
    );
    final humans = [
      Human(id: 'anna', name: 'Анна'),
      Human(id: 'boris', name: 'Борис'),
    ];
    final assistants = [Assistant(id: 'asya', name: 'Ася')];
    final sessions = [
      ProcedureSessionRaw(
        id: 'single',
        dayId: day.id,
        participantId: 'anna',
        startTime: '09:00',
        procedureKindId: single.id,
      ),
      ProcedureSessionRaw(
        id: 'curated',
        dayId: day.id,
        participantId: 'anna',
        startTime: '10:00',
        procedureKindId: curated.id,
        assistantId: 'asya',
      ),
      ProcedureSessionRaw(
        id: 'group-anna',
        dayId: day.id,
        participantId: 'anna',
        startTime: '11:00',
        procedureKindId: grouped.id,
        assistantId: 'asya',
      ),
      ProcedureSessionRaw(
        id: 'group-boris',
        dayId: day.id,
        participantId: 'boris',
        startTime: '11:00',
        procedureKindId: grouped.id,
        assistantId: 'asya',
      ),
    ];
    const builder = ProcedureSessionTooltipBuilder();

    final participant = builder.mainTablePersonSchedule(
      humanId: 'anna',
      humanName: 'Анна',
      dayId: day.id,
      currentSessionId: 'curated',
      savedSessions: sessions,
      workdays: [day],
      humans: humans,
      procedureKinds: [single, curated, grouped],
      assistants: assistants,
    );
    expect(participant.title, 'Расписание Анна, Суббота:');
    expect(
      participant.lines.map((line) => line.text),
      [
        '09:00–09:20 Одиночная',
        'ТЕКУЩИЙ 10:00–10:30 Парная — асс. Ася',
        '11:00–11:40 Медитация — асс. Ася',
      ],
    );
    expect(participant.lines[1].isCurrent, isTrue);

    final assistant = builder.mainTablePersonSchedule(
      humanId: 'asya',
      humanName: 'Ася',
      dayId: day.id,
      currentSessionId: 'group-boris',
      savedSessions: sessions,
      workdays: [day],
      humans: humans,
      procedureKinds: [single, curated, grouped],
      assistants: assistants,
    );
    expect(
      assistant.lines.map((line) => line.text),
      [
        '10:00–10:15 Парная — АССИСТЕНТ — уч. Анна',
        'ТЕКУЩИЙ 11:00–11:25 Медитация — АССИСТЕНТ — уч. Анна, Борис',
      ],
    );
    expect(assistant.lines.last.isCurrent, isTrue);
  });

  test('counts only other curated assignments for an assistant history', () {
    final curated = ProcedureKind(
      id: 'curated',
      patternId: ProcedureKindPatterns.curated.patternId,
      name: 'С сопровождением',
      capacity: 1,
      participantBusyTime: 30,
      assistantBusyTime: 30,
    );
    final grouped = ProcedureKind(
      id: 'grouped',
      patternId: ProcedureKindPatterns.grouped.patternId,
      name: 'Групповая',
      capacity: 2,
      participantBusyTime: 30,
      assistantBusyTime: 30,
    );
    const builder = ProcedureSessionTooltipBuilder();
    final sessions = [
      ProcedureSessionRaw(
          id: 'current',
          dayId: 'one',
          participantId: 'participant',
          startTime: '09:00',
          procedureKindId: curated.id,
          assistantId: 'assistant'),
      ProcedureSessionRaw(
          id: 'curated-other-day',
          dayId: 'two',
          participantId: 'participant',
          startTime: '09:00',
          procedureKindId: curated.id,
          assistantId: 'assistant'),
      ProcedureSessionRaw(
          id: 'grouped',
          dayId: 'one',
          participantId: 'participant',
          startTime: '10:00',
          procedureKindId: grouped.id,
          assistantId: 'assistant'),
      ProcedureSessionRaw(
          id: 'other-assistant',
          dayId: 'one',
          participantId: 'participant',
          startTime: '11:00',
          procedureKindId: curated.id,
          assistantId: 'other'),
    ];

    expect(
      builder.assistantHistoryCount(
        participantId: 'participant',
        assistantId: 'assistant',
        editingSessionId: 'current',
        savedSessions: sessions,
        procedureKinds: [curated, grouped],
      ),
      1,
    );
    expect(
      builder.assistantHistoryCount(
        participantId: null,
        assistantId: 'assistant',
        editingSessionId: '',
        savedSessions: sessions,
        procedureKinds: [curated, grouped],
      ),
      0,
    );
  });

  testWidgets('marks conflicting resource choices and info icons red',
      (tester) async {
    final workday = Workday(
      id: 'day',
      name: 'День',
      calendarDate: DateTime(2026, 7, 11),
    );
    ProcedureKind kind(String id, String name) => ProcedureKind(
          id: id,
          patternId: ProcedureKindPatterns.curated.patternId,
          name: name,
          capacity: 1,
          participantBusyTime: 60,
          assistantBusyTime: 60,
          resourceBusyTime: 60,
        );
    final conflictingKind = kind('kind-conflict', 'Конфликтная процедура');
    final freeKind = kind('kind-free', 'Свободная процедура');
    final otherKind = kind('kind-other', 'Другая процедура');
    final humans = [
      Human(id: 'participant-conflict', name: 'Конфликтный участник'),
      Human(id: 'participant-free', name: 'Свободный участник'),
      Human(id: 'other', name: 'Другой участник'),
    ];
    final assistants = [
      Assistant(id: 'assistant-conflict', name: 'Конфликтный сопровождающий'),
      Assistant(id: 'assistant-free', name: 'Свободный сопровождающий'),
      Assistant(id: 'other-assistant', name: 'Другой сопровождающий'),
    ];
    final sessions = [
      ProcedureSessionRaw(
        id: 'item-conflict',
        dayId: workday.id,
        participantId: 'other',
        startTime: '10:00',
        procedureKindId: conflictingKind.id,
        assistantId: 'other-assistant',
      ),
      ProcedureSessionRaw(
        id: 'participant-conflict',
        dayId: workday.id,
        participantId: 'participant-conflict',
        startTime: '10:00',
        procedureKindId: otherKind.id,
        assistantId: 'other-assistant',
      ),
      ProcedureSessionRaw(
        id: 'assistant-conflict',
        dayId: workday.id,
        participantId: 'other',
        startTime: '10:00',
        procedureKindId: otherKind.id,
        assistantId: 'assistant-conflict',
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: ProcedureSessionDialog(
          initialValue: ProcedureSessionRaw(
            id: 'draft',
            dayId: workday.id,
            participantId: 'participant-conflict',
            startTime: '10:00',
            procedureKindId: conflictingKind.id,
            assistantId: 'assistant-conflict',
          ),
          workdays: [workday],
          humans: humans,
          procedureKinds: [conflictingKind, freeKind, otherKind],
          assistants: assistants,
          procedureSessions: sessions,
          programSettings: ProgramSettings.defaults,
          onSubmit: (_, __) async =>
              const ProcedureSessionSubmitResult.saved(1),
        ),
      ),
    ));

    Text text(String value) => tester.widget<Text>(find.text(value).first);
    expect(text('Конфликтная процедура').style?.color, Colors.red);
    expect(text('Конфликтный участник').style?.color, Colors.red);
    expect(text('Конфликтный сопровождающий').style?.color, Colors.red);
    expect(
      tester
          .widget<Icon>(
              find.byKey(const Key('procedure_session_procedure_kind_info')))
          .color,
      Colors.red,
    );
    expect(
      tester
          .widget<Icon>(
              find.byKey(const Key('procedure_session_participant_info')))
          .color,
      Colors.red,
    );
    expect(
      tester
          .widget<Icon>(
              find.byKey(const Key('procedure_session_assistant_info')))
          .color,
      Colors.red,
    );
  });

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
        'Доступные часы начала: 10-12.',
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
    expect(find.text('Выберите сопровождающего'), findsOneWidget);
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
