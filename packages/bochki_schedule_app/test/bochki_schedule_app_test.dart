import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('package exports compile', () {
    expect(BochkiScheduleApp, isNotNull);
  });

  testWidgets('shell shows top menu and procedure sessions workspace', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);
    expect(find.text('Распечатки'), findsOneWidget);
    expect(find.text('Добавить запись...'), findsOneWidget);
    expect(find.text('Список назначенных процедур пуст.'), findsOneWidget);
  });

  testWidgets('shell opens print preset params dialog from toolbar', (
    tester,
  ) async {
    final context = _buildTestContext(
      workdays: [
        Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
      ],
      printPresetParams: const PrintPresetParams(
        workdayId: '1',
        textBefore: 'Начало',
        textAfter: 'Конец',
      ),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('print_preset_params_button')),
    );
    await tester.tap(find.byKey(const Key('print_preset_params_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('print_preset_params_dialog')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('print_preset_params_dialog')),
        matching: find.text('Распечатки'),
      ),
      findsOneWidget,
    );
    expect(find.text('По фамилиям'), findsOneWidget);
    expect(find.text('Начало'), findsOneWidget);
    expect(find.text('Конец'), findsOneWidget);
  });

  testWidgets('print preset params cancel discards edits', (tester) async {
    final context = _buildTestContext(
      workdays: [
        Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('print_preset_params_button')),
    );
    await tester.tap(find.byKey(const Key('print_preset_params_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('print_preset_text_before_field')),
      'Черновик',
    );
    await tester
        .tap(find.byKey(const Key('print_preset_params_cancel_button')));
    await tester.pumpAndSettle();

    expect(
      context.printPresetParamsRepository.params,
      PrintPresetParams.defaults,
    );
  });

  testWidgets('print preset params save persists edits and closes dialog', (
    tester,
  ) async {
    final context = _buildTestContext(
      workdays: [
        Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
        Workday(
          id: '2',
          name: 'Суббота',
          calendarDate: DateTime(2026, 7, 18),
        ),
      ],
      printPresetParams: const PrintPresetParams(
        workdayId: '1',
        textBefore: '',
        textAfter: '',
      ),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('print_preset_params_button')),
    );
    await tester.tap(find.byKey(const Key('print_preset_params_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('print_preset_workday_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Суббота (18.07.2026)').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('print_preset_text_before_field')),
      'Начало дня',
    );
    await tester.enterText(
      find.byKey(const Key('print_preset_text_after_field')),
      'Конец дня',
    );

    await tester.tap(find.byKey(const Key('print_preset_params_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('print_preset_params_dialog')), findsNothing);
    expect(
      context.printPresetParamsRepository.params.toJson(),
      const PrintPresetParams(
        workdayId: '2',
        textBefore: 'Начало дня',
        textAfter: 'Конец дня',
      ).toJson(),
    );
  });

  testWidgets('print preset params actions are disabled without workdays', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('print_preset_params_button')),
    );
    await tester.tap(find.byKey(const Key('print_preset_params_button')));
    await tester.pumpAndSettle();

    final openButton = tester.widget<FilledButton>(
      find.byKey(const Key('print_preset_params_open_button')),
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('print_preset_params_save_button')),
    );

    expect(openButton.onPressed, isNull);
    expect(saveButton.onPressed, isNull);
    expect(find.text('Нет доступных дней'), findsOneWidget);
  });

  testWidgets('shell opens participants dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    expect(
      find.byKey(const Key('participants_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список участников'), findsOneWidget);
    expect(find.text('Участники (0)'), findsOneWidget);
    expect(find.text('Добавить новую запись'), findsOneWidget);
    expect(find.byKey(const Key('participants_table_divider')), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
  });

  testWidgets('shell opens assistants dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openAssistantsDialog(tester);

    expect(
      find.byKey(const Key('assistants_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список ассистентов'), findsOneWidget);
    expect(find.text('Ассистенты (0)'), findsOneWidget);
    expect(find.byKey(const Key('assistants_table_divider')), findsOneWidget);
  });

  testWidgets('shell opens procedure kinds dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProcedureKindsDialog(tester);

    expect(find.byKey(const Key('procedure_kinds_dialog')), findsOneWidget);
    expect(find.text('Список процедур'), findsOneWidget);
    expect(
      find.byKey(const Key('procedure_kind_add_button')),
      findsOneWidget,
    );
  });

  testWidgets('shell opens workdays dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openWorkdaysDialog(tester);

    expect(find.byKey(const Key('workdays_dialog')), findsOneWidget);
    expect(find.text('Список дней'), findsOneWidget);
    expect(find.byKey(const Key('workday_add_button')), findsOneWidget);
  });

  testWidgets('shell opens program settings dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProgramSettingsDialog(tester);

    expect(find.byKey(const Key('program_settings_dialog')), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
  });

  testWidgets('program settings dialog validates and saves singleton object',
      (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProgramSettingsDialog(tester);

    await tester.tap(
      find.byKey(const Key('program_settings_lunch_end_hour_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('13').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('program_settings_save_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Конец обеда должен быть позже начала обеда.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('program_settings_lunch_end_hour_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Конец обеда должен быть позже начала обеда.'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('program_settings_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('program_settings_dialog')), findsNothing);
    expect(
      context.programSettingsRepository.settings.toJson(),
      ProgramSettings.defaults.toJson(),
    );
  });

  testWidgets('procedure sessions screen supports create', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Иван'),
      ],
      assistants: [
        Assistant(id: '2', name: 'Петр'),
      ],
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
      workdays: [
        Workday(
          id: '1',
          name: 'День А',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('add_procedure_session_button')),
    );
    await tester.tap(find.byKey(const Key('add_procedure_session_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('procedure_session_create_dialog')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('procedure_session_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Иван'), findsOneWidget);
    expect(find.text('Бочка'), findsOneWidget);
    expect(context.procedureSessionsRepository.sessions, hasLength(1));
  });

  testWidgets('procedure sessions filters by part of day', (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Иван'),
      ],
      assistants: [
        Assistant(id: '2', name: 'Петр'),
      ],
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
      workdays: [
        Workday(
          id: '1',
          name: 'День А',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
      procedureSessions: [
        ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          participantId: '1',
          startTime: '12:55',
          procedureKindId: '1',
          assistantId: '2',
        ),
        ProcedureSessionRaw(
          id: '2',
          dayId: '1',
          participantId: '1',
          startTime: '13:00',
          procedureKindId: '1',
          assistantId: '2',
        ),
      ],
      programSettings: const ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 13, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 14, minute: 0),
        minimumHour: 8,
        maximumHour: 20,
      ),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('procedure_session_row_1')), findsOneWidget);
    expect(find.byKey(const Key('procedure_session_row_2')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('procedure_sessions_part_of_day_filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('До обеда').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('procedure_session_row_1')), findsOneWidget);
    expect(find.byKey(const Key('procedure_session_row_2')), findsNothing);
  });

  testWidgets(
      'procedure sessions uses custom lunch start for part of day filter',
      (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Иван'),
      ],
      assistants: [
        Assistant(id: '2', name: 'Петр'),
      ],
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
      workdays: [
        Workday(
          id: '1',
          name: 'День А',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
      procedureSessions: [
        ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          participantId: '1',
          startTime: '13:55',
          procedureKindId: '1',
          assistantId: '2',
        ),
        ProcedureSessionRaw(
          id: '2',
          dayId: '1',
          participantId: '1',
          startTime: '14:00',
          procedureKindId: '1',
          assistantId: '2',
        ),
      ],
      programSettings: const ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
        minimumHour: 8,
        maximumHour: 20,
      ),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('procedure_sessions_part_of_day_filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('До обеда').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('procedure_session_row_1')), findsOneWidget);
    expect(find.byKey(const Key('procedure_session_row_2')), findsNothing);
  });

  testWidgets('procedure sessions screen supports edit existing record', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Иван'),
      ],
      assistants: [
        Assistant(id: '2', name: 'Петр'),
      ],
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
      workdays: [
        Workday(
          id: '1',
          name: 'День А',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
      procedureSessions: [
        ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          participantId: '1',
          startTime: '09:00',
          procedureKindId: '1',
          assistantId: '2',
        ),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('procedure_session_row_1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('procedure_session_edit_dialog')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('procedure_session_hour_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('procedure_session_minute_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('procedure_session_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(
      context.procedureSessionsRepository.sessions.single.startTime,
      '10:30',
    );
  });

  testWidgets(
      'procedure sessions blocks saving existing record outside configured start range',
      (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Иван'),
      ],
      assistants: [
        Assistant(id: '2', name: 'Петр'),
      ],
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
      workdays: [
        Workday(
          id: '1',
          name: 'День А',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
      procedureSessions: [
        ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          participantId: '1',
          startTime: '09:00',
          procedureKindId: '1',
          assistantId: '2',
        ),
      ],
      programSettings: const ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
        minimumHour: 10,
        maximumHour: 18,
      ),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('procedure_session_row_1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('procedure_session_schedule_hint')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Допустимое время начала: 10:00-18:55. Обед: с 14:00 до 15:00.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('procedure_session_save_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Время начала должно быть в диапазоне 10:00-18:55.'),
      findsOneWidget,
    );
    expect(
        context.procedureSessionsRepository.sessions.single.startTime, '09:00');
  });

  testWidgets(
    'procedure sessions row becomes selected on mouse down before tap completes',
    (tester) async {
      final context = _buildTestContext(
        participants: [
          Participant(id: '1', name: 'Иван'),
        ],
        assistants: [
          Assistant(id: '2', name: 'Петр'),
        ],
        procedureKinds: [
          ProcedureKind(
            id: '1',
            patternId: ProcedureKindPatterns.curated.patternId,
            name: 'Бочка',
            capacity: 6,
            participantBusyTime: 30,
            assistantBusyTime: 10,
            resourceBusyTime: 5,
          ),
        ],
        workdays: [
          Workday(
            id: '1',
            name: 'День А',
            calendarDate: DateTime(2026, 7, 11),
          ),
        ],
        procedureSessions: [
          ProcedureSessionRaw(
            id: '1',
            dayId: '1',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '1',
            assistantId: '2',
          ),
        ],
      );

      await tester.pumpWidget(BochkiScheduleApp(services: context.services));
      await tester.pumpAndSettle();

      final row = find.byKey(const Key('procedure_session_row_1'));
      final rowContent =
          find.byKey(const Key('procedure_session_row_content_1'));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      final center = tester.getCenter(row);

      await gesture.addPointer(location: center);
      await gesture.moveTo(center);
      await tester.pump();
      await gesture.down(center);
      await tester.pump();

      final container = tester.widget<Container>(rowContent);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE7F1FB));
      expect(
        find.byKey(const Key('procedure_session_edit_dialog')),
        findsNothing,
      );

      await gesture.up();
      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets('procedure kinds dialog shows updated table headers', (
    tester,
  ) async {
    final context = _buildTestContext(
      procedureKinds: [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Парение',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProcedureKindsDialog(tester);

    final headerTexts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('procedure_kinds_table_header')),
            matching: find.byType(Text),
          ),
        )
        .map((widget) => widget.data)
        .toList();

    expect(headerTexts, [
      '',
      'Тип',
      'Название',
      'емкость',
      't участн.',
      't ассист.',
      't ресуср.',
      '',
      '',
    ]);
  });

  testWidgets('participants dialog supports create edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      '  Иван   Иванов  ',
    );
    await tester.tap(find.text('Участники (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Иван Иванов'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Иван Иванов');

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Борис',
    );
    await tester.tap(find.text('Участники (1)'));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('participant_row_1'));
    await _doubleMouseClick(tester, firstRow);
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Иван Петров',
    );
    await _mouseClick(tester, find.byKey(const Key('participant_row_2')));
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(context.repository.participants.first.name, 'Иван Петров');

    final secondRow = find.byKey(const Key('participant_row_2'));
    await _mouseClick(tester, secondRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
      context.repository.participants.map((participant) => participant.name),
      ['Иван Петров'],
    );
    expect(find.text('Участники (1)'), findsOneWidget);
  });

  testWidgets('assistants dialog supports create edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openAssistantsDialog(tester);

    await tester.tap(find.byKey(const Key('assistant_add_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assistant_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('assistant_name_field')),
      '  Иван   Ассистент  ',
    );
    await tester.tap(find.text('Ассистенты (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Иван Ассистент'), findsOneWidget);
    expect(
        context.assistantsRepository.assistants.single.name, 'Иван Ассистент');

    await tester.tap(find.byKey(const Key('assistant_add_row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('assistant_name_field')),
      'Борис',
    );
    await tester.tap(find.text('Ассистенты (1)'));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('assistant_row_1'));
    await _doubleMouseClick(tester, firstRow);
    await tester.enterText(
      find.byKey(const Key('assistant_name_field')),
      'Иван Петров',
    );
    await _mouseClick(tester, find.byKey(const Key('assistant_row_2')));
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(context.assistantsRepository.assistants.first.name, 'Иван Петров');

    final secondRow = find.byKey(const Key('assistant_row_2'));
    await _mouseClick(tester, secondRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
      context.assistantsRepository.assistants
          .map((assistant) => assistant.name),
      ['Иван Петров'],
    );
    expect(find.text('Ассистенты (1)'), findsOneWidget);
  });

  testWidgets('procedure kinds dialog supports create edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProcedureKindsDialog(tester);

    await tester.tap(find.byKey(const Key('procedure_kind_add_button')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('procedure_kind_create_dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('procedure_kind_name_field')),
      '  Баня   1  ',
    );
    await tester.enterText(
      find.byKey(const Key('procedure_kind_capacity_field')),
      '6',
    );
    await tester.enterText(
      find.byKey(const Key('procedure_kind_participant_busy_time_field')),
      '30',
    );
    await tester.enterText(
      find.byKey(const Key('procedure_kind_assistant_busy_time_field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('procedure_kind_resource_busy_time_field')),
      '5',
    );
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(find.text('Баня 1'), findsOneWidget);
    expect(
        context.procedureKindsRepository.procedureKinds.single.name, 'Баня 1');

    await tester.tap(find.byKey(const Key('procedure_kind_edit_1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('procedure_kind_name_field')),
      'Медитация',
    );
    await tester.tap(find.byKey(const Key('procedure_kind_pattern_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Групповая (медитация)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Медитация'), findsOneWidget);
    expect(context.procedureKindsRepository.procedureKinds.single.patternId,
        ProcedureKindPatterns.grouped.patternId);
    expect(
        context
            .procedureKindsRepository.procedureKinds.single.assistantBusyTime,
        isNull);

    await tester.tap(find.byKey(const Key('procedure_kind_delete_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(context.procedureKindsRepository.procedureKinds, isEmpty);
  });

  testWidgets('procedure kind form uses compact two-column layout', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProcedureKindsDialog(tester);

    await tester.tap(find.byKey(const Key('procedure_kind_add_button')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('procedure_kind_create_dialog'));

    expect(
      find.descendant(of: dialog, matching: find.text('Тип процедуры')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Название')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Емкость')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Время участн.(мин)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Время ассит.(мин)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Время ресурс.(мин)')),
      findsOneWidget,
    );

    final patternFieldWidth = tester
        .getSize(find.byKey(const Key('procedure_kind_pattern_field')))
        .width;
    final nameFieldWidth = tester
        .getSize(find.byKey(const Key('procedure_kind_name_field')))
        .width;
    final capacityFieldWidth = tester
        .getSize(find.byKey(const Key('procedure_kind_capacity_field')))
        .width;
    final participantTimeFieldWidth = tester
        .getSize(
          find.byKey(const Key('procedure_kind_participant_busy_time_field')),
        )
        .width;

    expect(nameFieldWidth, greaterThan(capacityFieldWidth));
    expect(patternFieldWidth, greaterThan(capacityFieldWidth));
    expect(capacityFieldWidth, equals(participantTimeFieldWidth));
  });

  testWidgets('procedure kind create form defaults capacity to 1', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openProcedureKindsDialog(tester);

    await tester.tap(find.byKey(const Key('procedure_kind_add_button')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('procedure_kind_capacity_field')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('workdays dialog supports create edit delete and reorder stub', (
    tester,
  ) async {
    final context = _buildTestContext(
      workdays: [
        Workday(
          id: '1',
          name: 'День 1',
          calendarDate: DateTime(2026, 7, 11),
        ),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openWorkdaysDialog(tester);

    await tester.tap(find.byKey(const Key('workday_add_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workday_create_dialog')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('workday_name_field')),
        matching: find.text('День 2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('workday_date_field')),
        matching: find.text('12.07.2026'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('workday_name_field')),
      '  День   22 ',
    );
    await tester.enterText(
      find.byKey(const Key('workday_date_field')),
      '15.07.2026',
    );
    await tester.tap(find.text('Создать').last);
    await tester.pumpAndSettle();

    expect(find.text('День 22'), findsOneWidget);
    expect(find.text('15.07.2026'), findsOneWidget);
    expect(context.workdaysRepository.workdays.last.name, 'День 22');

    await tester.tap(find.byKey(const Key('workday_edit_2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workday_name_field')),
      'День 3',
    );
    await tester.enterText(
      find.byKey(const Key('workday_date_field')),
      '16.07.2026',
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('День 3'), findsOneWidget);
    expect(find.text('16.07.2026'), findsOneWidget);
    expect(context.workdaysRepository.workdays.last.name, 'День 3');

    await tester.tap(find.byKey(const Key('workday_reorder_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workday_reorder_dialog')), findsOneWidget);
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    final row = find.byKey(const Key('workday_row_2'));
    await _doubleMouseClick(tester, row);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workday_edit_dialog')), findsNothing);
    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);

    await _mouseClick(tester, row, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workday_reorder_dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('workday_delete_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
      context.workdaysRepository.workdays.map((workday) => workday.name),
      ['День 1'],
    );
  });

  testWidgets('single click selects row without opening inline edit', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _mouseClick(tester, row);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
  });

  testWidgets('row becomes selected on mouse down before tap completes', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    final center = tester.getCenter(row);

    await gesture.addPointer(location: center);
    await gesture.moveTo(center);
    await tester.pump();
    await gesture.down(center);
    await tester.pump();

    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
    expect(find.byKey(const Key('participant_name_field')), findsNothing);

    await gesture.up();
    await gesture.removePointer();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('enter commits edited row after inline edit starts',
      (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _doubleMouseClick(tester, row);

    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Анна Петрова',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(find.text('Анна Петрова'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Анна Петрова');
    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
  });

  testWidgets('empty add row is cancelled on click outside', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);

    await tester.tap(find.text('Участники (0)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(context.repository.participants, isEmpty);
    expect(find.text('Введите имя участника.'), findsNothing);
  });

  testWidgets('double click opens inline edit for row', (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('participant_row_1')),
    );

    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);
  });

  testWidgets('escape rolls back dirty existing row', (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('participant_row_1')),
    );
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Анна Петрова',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(find.text('Анна'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Анна');
  });

  testWidgets('arrow navigation selects edge rows from no selection', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
        Participant(id: '2', name: 'Борис'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('participant_row_1'));
    expect(find.descendant(of: firstRow, matching: find.text('▶')),
        findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    final secondRow = find.byKey(const Key('participant_row_2'));
    expect(find.descendant(of: secondRow, matching: find.text('▶')),
        findsOneWidget);
  });

  testWidgets('context menu closes on escape without animation wait', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _mouseClick(tester, row, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
  });
}

Future<void> _mouseClick(
  WidgetTester tester,
  Finder finder, {
  int buttons = kPrimaryMouseButton,
}) async {
  final gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: buttons,
  );
  final center = tester.getCenter(finder);
  await gesture.addPointer(location: center);
  await gesture.moveTo(center);
  await tester.pump();
  await gesture.down(center);
  await gesture.up();
  await gesture.removePointer();
}

Future<void> _doubleMouseClick(
  WidgetTester tester,
  Finder finder,
) async {
  await _mouseClick(tester, finder);
  await tester.pump(const Duration(milliseconds: 50));
  await _mouseClick(tester, finder);
  await tester.pumpAndSettle();
}

Future<void> _openParticipantsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Участники').last);
  await tester.pumpAndSettle();
}

Future<void> _openAssistantsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ассистенты').last);
  await tester.pumpAndSettle();
}

Future<void> _openProcedureKindsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Процедуры').last);
  await tester.pumpAndSettle();
}

Future<void> _openWorkdaysDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Дни').last);
  await tester.pumpAndSettle();
}

Future<void> _openProgramSettingsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Настройки').last);
  await tester.pumpAndSettle();
}

_TestContext _buildTestContext({
  List<Participant>? participants,
  List<Assistant>? assistants,
  List<ProcedureKind>? procedureKinds,
  List<Workday>? workdays,
  List<ProcedureSessionRaw>? procedureSessions,
  ProgramSettings? programSettings,
  PrintPresetParams? printPresetParams,
}) {
  final participantsRepository = _InMemoryParticipantsRepository(
    participants: participants,
  );
  final assistantsRepository = _InMemoryAssistantsRepository(
    assistants: assistants,
  );
  final procedureKindsRepository = _InMemoryProcedureKindsRepository(
    procedureKinds: procedureKinds,
  );
  final workdaysRepository = _InMemoryWorkdaysRepository(
    workdays: workdays,
  );
  final humansRepository = _InMemoryHumansRepository(
    participants: participantsRepository.participants,
    assistants: assistantsRepository.assistants,
  );
  final procedureSessionsRepository = _InMemoryProcedureSessionsRepository(
    sessions: procedureSessions,
  );
  final programSettingsRepository = _InMemoryProgramSettingsRepository(
    settings: programSettings ?? ProgramSettings.defaults,
  );
  final printPresetParamsRepository = _InMemoryPrintPresetParamsRepository(
    params: printPresetParams ?? PrintPresetParams.defaults,
  );
  final listProcedureSessionsUseCase = ListProcedureSessionsUseCase(
    procedureSessionsRepository,
  );
  final listRichProcedureSessionsUseCase = ListRichProcedureSessionsUseCase(
    listProcedureSessionsUseCase: listProcedureSessionsUseCase,
    listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
    listHumansUseCase: ListHumansUseCase(humansRepository),
    listProcedureKindsUseCase:
        ListProcedureKindsUseCase(procedureKindsRepository),
    listAssistantsUseCase: ListAssistantsUseCase(assistantsRepository),
  );

  return _TestContext(
    services: AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      listHumansUseCase: ListHumansUseCase(humansRepository),
      listParticipantsUseCase: ListParticipantsUseCase(participantsRepository),
      createParticipantUseCase:
          CreateParticipantUseCase(participantsRepository),
      updateParticipantUseCase:
          UpdateParticipantUseCase(participantsRepository),
      deleteParticipantUseCase:
          DeleteParticipantUseCase(participantsRepository),
      listAssistantsUseCase: ListAssistantsUseCase(assistantsRepository),
      createAssistantUseCase: CreateAssistantUseCase(assistantsRepository),
      updateAssistantUseCase: UpdateAssistantUseCase(assistantsRepository),
      deleteAssistantUseCase: DeleteAssistantUseCase(assistantsRepository),
      listProcedureKindsUseCase:
          ListProcedureKindsUseCase(procedureKindsRepository),
      createProcedureKindUseCase:
          CreateProcedureKindUseCase(procedureKindsRepository),
      updateProcedureKindUseCase:
          UpdateProcedureKindUseCase(procedureKindsRepository),
      deleteProcedureKindUseCase:
          DeleteProcedureKindUseCase(procedureKindsRepository),
      listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
      createWorkdayUseCase: CreateWorkdayUseCase(workdaysRepository),
      updateWorkdayUseCase: UpdateWorkdayUseCase(workdaysRepository),
      deleteWorkdayUseCase: DeleteWorkdayUseCase(workdaysRepository),
      getPrintPresetParamsUseCase:
          GetPrintPresetParamsUseCase(printPresetParamsRepository),
      updatePrintPresetParamsUseCase:
          UpdatePrintPresetParamsUseCase(printPresetParamsRepository),
      getProgramSettingsUseCase:
          GetProgramSettingsUseCase(programSettingsRepository),
      updateProgramSettingsUseCase:
          UpdateProgramSettingsUseCase(programSettingsRepository),
      listProcedureSessionsUseCase: listProcedureSessionsUseCase,
      listRichProcedureSessionsUseCase: listRichProcedureSessionsUseCase,
      listProcedureSessionsWithConflictsUseCase:
          ListProcedureSessionsWithConflictsUseCase(
        listRichProcedureSessionsUseCase: listRichProcedureSessionsUseCase,
      ),
      createProcedureSessionUseCase: CreateProcedureSessionUseCase(
        procedureSessionsRepository,
        workdaysRepository: workdaysRepository,
        humansRepository: humansRepository,
        procedureKindsRepository: procedureKindsRepository,
        assistantsRepository: assistantsRepository,
        programSettingsRepository: programSettingsRepository,
      ),
      updateProcedureSessionUseCase: UpdateProcedureSessionUseCase(
        procedureSessionsRepository,
        workdaysRepository: workdaysRepository,
        humansRepository: humansRepository,
        procedureKindsRepository: procedureKindsRepository,
        assistantsRepository: assistantsRepository,
        programSettingsRepository: programSettingsRepository,
      ),
      deleteProcedureSessionUseCase:
          DeleteProcedureSessionUseCase(procedureSessionsRepository),
      flushPending: _noopAsync,
      shutdown: _noopAsync,
    ),
    repository: participantsRepository,
    assistantsRepository: assistantsRepository,
    procedureKindsRepository: procedureKindsRepository,
    workdaysRepository: workdaysRepository,
    programSettingsRepository: programSettingsRepository,
    printPresetParamsRepository: printPresetParamsRepository,
    procedureSessionsRepository: procedureSessionsRepository,
  );
}

Future<void> _noopAsync() async {}

final class _TestContext {
  const _TestContext({
    required this.services,
    required this.repository,
    required this.assistantsRepository,
    required this.procedureKindsRepository,
    required this.workdaysRepository,
    required this.programSettingsRepository,
    required this.printPresetParamsRepository,
    required this.procedureSessionsRepository,
  });

  final AppServices services;
  final _InMemoryParticipantsRepository repository;
  final _InMemoryAssistantsRepository assistantsRepository;
  final _InMemoryProcedureKindsRepository procedureKindsRepository;
  final _InMemoryWorkdaysRepository workdaysRepository;
  final _InMemoryProgramSettingsRepository programSettingsRepository;
  final _InMemoryPrintPresetParamsRepository printPresetParamsRepository;
  final _InMemoryProcedureSessionsRepository procedureSessionsRepository;
}

final class _InMemoryProgramSettingsRepository
    implements ProgramSettingsRepository {
  _InMemoryProgramSettingsRepository({
    required ProgramSettings settings,
  }) : _settings = settings;

  ProgramSettings _settings;

  ProgramSettings get settings => _settings;

  @override
  Future<ProgramSettings> get() async => _settings;

  @override
  Future<ProgramSettings> update(ProgramSettings settings) async {
    _settings = settings;
    return _settings;
  }
}

final class _InMemoryPrintPresetParamsRepository
    implements PrintPresetParamsRepository {
  _InMemoryPrintPresetParamsRepository({
    required PrintPresetParams params,
  }) : _params = params;

  PrintPresetParams _params;

  PrintPresetParams get params => _params;

  @override
  Future<PrintPresetParams> get() async => _params;

  @override
  Future<PrintPresetParams> update(PrintPresetParams params) async {
    _params = params;
    return _params;
  }
}

final class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {}

  @override
  Future<void> info(String message) async {}
}

final class _InMemoryHumansRepository implements HumansRepository {
  _InMemoryHumansRepository({
    required List<Participant> participants,
    required List<Assistant> assistants,
  }) : _humans = [
          for (final participant in participants)
            Human(
              id: participant.id,
              name: participant.name,
              isParticipant: true,
              isAssistant: assistants.any(
                (assistant) => assistant.id == participant.id,
              ),
            ),
          for (final assistant in assistants)
            if (!participants
                .any((participant) => participant.id == assistant.id))
              Human(
                id: assistant.id,
                name: assistant.name,
                isParticipant: false,
                isAssistant: true,
              ),
        ];

  final List<Human> _humans;

  @override
  Future<Human> create({
    required String name,
    required bool isParticipant,
    required bool isAssistant,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String humanId) async {}

  @override
  Future<List<Human>> list() async => [..._humans];

  @override
  Future<Human> update(Human human) async => human;
}

final class _InMemoryProcedureSessionsRepository
    implements ProcedureSessionsRepository {
  _InMemoryProcedureSessionsRepository({
    List<ProcedureSessionRaw>? sessions,
  }) : _sessions = [...?sessions] {
    if (_sessions.isNotEmpty) {
      final maxId = _sessions
          .map((entry) => int.parse(entry.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<ProcedureSessionRaw> _sessions;
  int _nextId = 1;

  List<ProcedureSessionRaw> get sessions => List.unmodifiable(_sessions);

  @override
  Future<ProcedureSessionRaw> create(
      ProcedureSessionRaw procedureSession) async {
    final created = procedureSession.copyWith(id: (_nextId++).toString());
    _sessions.add(created);
    return created;
  }

  @override
  Future<void> delete(String procedureSessionId) async {
    _sessions.removeWhere((entry) => entry.id == procedureSessionId);
  }

  @override
  Future<List<ProcedureSessionRaw>> list() async => [..._sessions];

  @override
  Future<ProcedureSessionRaw> update(
      ProcedureSessionRaw procedureSession) async {
    final index =
        _sessions.indexWhere((entry) => entry.id == procedureSession.id);
    if (index != -1) {
      _sessions[index] = procedureSession;
    }
    return procedureSession;
  }
}

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  _InMemoryParticipantsRepository({
    List<Participant>? participants,
  }) : _participants = [...?participants] {
    if (_participants.isNotEmpty) {
      final maxId = _participants
          .map((participant) => int.parse(participant.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Participant> _participants;
  int _nextId = 1;

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final participant = Participant(
      id: (_nextId++).toString(),
      name: name,
    );
    _participants.add(participant);
    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    _participants.removeWhere((participant) => participant.id == participantId);
  }

  List<Participant> get participants =>
      List<Participant>.unmodifiable(_participants);

  @override
  Future<List<Participant>> list() async {
    return [..._participants];
  }

  @override
  Future<Participant> update(Participant participant) async {
    final index = _participants.indexWhere(
      (candidate) => candidate.id == participant.id,
    );
    if (index != -1) {
      _participants[index] = participant;
    }
    return participant;
  }
}

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  _InMemoryAssistantsRepository({
    List<Assistant>? assistants,
  }) : _assistants = [...?assistants] {
    if (_assistants.isNotEmpty) {
      final maxId = _assistants
          .map((assistant) => int.parse(assistant.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Assistant> _assistants;
  int _nextId = 1;

  @override
  Future<Assistant> create({
    required String name,
  }) async {
    final assistant = Assistant(
      id: (_nextId++).toString(),
      name: name,
    );
    _assistants.add(assistant);
    return assistant;
  }

  @override
  Future<void> delete(String assistantId) async {
    _assistants.removeWhere((assistant) => assistant.id == assistantId);
  }

  @override
  Future<List<Assistant>> list() async {
    return [..._assistants];
  }

  List<Assistant> get assistants => List<Assistant>.unmodifiable(_assistants);

  @override
  Future<Assistant> update(Assistant assistant) async {
    final index = _assistants.indexWhere(
      (candidate) => candidate.id == assistant.id,
    );
    if (index != -1) {
      _assistants[index] = assistant;
    }
    return assistant;
  }
}

final class _InMemoryProcedureKindsRepository
    implements ProcedureKindsRepository {
  _InMemoryProcedureKindsRepository({
    List<ProcedureKind>? procedureKinds,
  }) : _procedureKinds = [...?procedureKinds] {
    if (_procedureKinds.isNotEmpty) {
      final maxId = _procedureKinds
          .map((procedureKind) => int.parse(procedureKind.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<ProcedureKind> _procedureKinds;
  int _nextId = 1;

  List<ProcedureKind> get procedureKinds =>
      List<ProcedureKind>.unmodifiable(_procedureKinds);

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) async {
    final createdProcedureKind = procedureKind
        .copyWith(
          id: (_nextId++).toString(),
        )
        .sanitizedForPersistence();
    _procedureKinds.add(createdProcedureKind);
    return createdProcedureKind;
  }

  @override
  Future<void> delete(String procedureKindId) async {
    _procedureKinds.removeWhere(
      (procedureKind) => procedureKind.id == procedureKindId,
    );
  }

  @override
  Future<List<ProcedureKind>> list() async {
    return [..._procedureKinds];
  }

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) async {
    final index = _procedureKinds.indexWhere(
      (candidate) => candidate.id == procedureKind.id,
    );
    if (index != -1) {
      _procedureKinds[index] = procedureKind.sanitizedForPersistence();
    }
    return procedureKind.sanitizedForPersistence();
  }
}

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository({
    List<Workday>? workdays,
  }) : _workdays = [...?workdays] {
    if (_workdays.isNotEmpty) {
      final maxId = _workdays
          .map((workday) => int.parse(workday.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Workday> _workdays;
  int _nextId = 1;

  List<Workday> get workdays => List<Workday>.unmodifiable(_workdays);

  @override
  Future<Workday> create(Workday workday) async {
    final createdWorkday = workday.copyWith(
      id: (_nextId++).toString(),
    );
    _workdays.add(createdWorkday);
    return createdWorkday;
  }

  @override
  Future<void> delete(String workdayId) async {
    _workdays.removeWhere((workday) => workday.id == workdayId);
  }

  @override
  Future<List<Workday>> list() async {
    return [..._workdays];
  }

  @override
  Future<Workday> update(Workday workday) async {
    final index = _workdays.indexWhere(
      (candidate) => candidate.id == workday.id,
    );
    if (index != -1) {
      _workdays[index] = workday;
    }
    return workday;
  }
}
