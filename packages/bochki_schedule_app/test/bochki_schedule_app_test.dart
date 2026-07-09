import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('package exports compile', () {
    expect(BochkiScheduleApp, isNotNull);
  });

  testWidgets('shell shows top menu and default placeholder', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);
    expect(find.text('В разработке'), findsOneWidget);
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

  testWidgets('shell opens trainers dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openTrainersDialog(tester);

    expect(
      find.byKey(const Key('trainers_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список тренеров'), findsOneWidget);
    expect(find.text('Тренеры (0)'), findsOneWidget);
    expect(find.byKey(const Key('trainers_table_divider')), findsOneWidget);
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

  testWidgets('trainers dialog supports create edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openTrainersDialog(tester);

    await tester.tap(find.byKey(const Key('trainer_add_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trainer_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('trainer_name_field')),
      '  Иван   Тренер  ',
    );
    await tester.tap(find.text('Тренеры (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Иван Тренер'), findsOneWidget);
    expect(context.trainersRepository.trainers.single.name, 'Иван Тренер');

    await tester.tap(find.byKey(const Key('trainer_add_row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer_name_field')),
      'Борис',
    );
    await tester.tap(find.text('Тренеры (1)'));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('trainer_row_1'));
    await _doubleMouseClick(tester, firstRow);
    await tester.enterText(
      find.byKey(const Key('trainer_name_field')),
      'Иван Петров',
    );
    await _mouseClick(tester, find.byKey(const Key('trainer_row_2')));
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(context.trainersRepository.trainers.first.name, 'Иван Петров');

    final secondRow = find.byKey(const Key('trainer_row_2'));
    await _mouseClick(tester, secondRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
      context.trainersRepository.trainers.map((trainer) => trainer.name),
      ['Иван Петров'],
    );
    expect(find.text('Тренеры (1)'), findsOneWidget);
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

Future<void> _openTrainersDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Тренеры').last);
  await tester.pumpAndSettle();
}

Future<void> _openProcedureKindsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Процедуры').last);
  await tester.pumpAndSettle();
}

_TestContext _buildTestContext({
  List<Participant>? participants,
  List<Trainer>? trainers,
  List<ProcedureKind>? procedureKinds,
}) {
  final participantsRepository = _InMemoryParticipantsRepository(
    participants: participants,
  );
  final trainersRepository = _InMemoryTrainersRepository(
    trainers: trainers,
  );
  final procedureKindsRepository = _InMemoryProcedureKindsRepository(
    procedureKinds: procedureKinds,
  );

  return _TestContext(
    services: AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      listParticipantsUseCase: ListParticipantsUseCase(participantsRepository),
      createParticipantUseCase:
          CreateParticipantUseCase(participantsRepository),
      updateParticipantUseCase:
          UpdateParticipantUseCase(participantsRepository),
      deleteParticipantUseCase:
          DeleteParticipantUseCase(participantsRepository),
      listTrainersUseCase: ListTrainersUseCase(trainersRepository),
      createTrainerUseCase: CreateTrainerUseCase(trainersRepository),
      updateTrainerUseCase: UpdateTrainerUseCase(trainersRepository),
      deleteTrainerUseCase: DeleteTrainerUseCase(trainersRepository),
      listProcedureKindsUseCase:
          ListProcedureKindsUseCase(procedureKindsRepository),
      createProcedureKindUseCase:
          CreateProcedureKindUseCase(procedureKindsRepository),
      updateProcedureKindUseCase:
          UpdateProcedureKindUseCase(procedureKindsRepository),
      deleteProcedureKindUseCase:
          DeleteProcedureKindUseCase(procedureKindsRepository),
      flushPending: _noopAsync,
      shutdown: _noopAsync,
    ),
    repository: participantsRepository,
    trainersRepository: trainersRepository,
    procedureKindsRepository: procedureKindsRepository,
  );
}

Future<void> _noopAsync() async {}

final class _TestContext {
  const _TestContext({
    required this.services,
    required this.repository,
    required this.trainersRepository,
    required this.procedureKindsRepository,
  });

  final AppServices services;
  final _InMemoryParticipantsRepository repository;
  final _InMemoryTrainersRepository trainersRepository;
  final _InMemoryProcedureKindsRepository procedureKindsRepository;
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

final class _InMemoryTrainersRepository implements TrainersRepository {
  _InMemoryTrainersRepository({
    List<Trainer>? trainers,
  }) : _trainers = [...?trainers] {
    if (_trainers.isNotEmpty) {
      final maxId = _trainers
          .map((trainer) => int.parse(trainer.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Trainer> _trainers;
  int _nextId = 1;

  @override
  Future<Trainer> create({
    required String name,
  }) async {
    final trainer = Trainer(
      id: (_nextId++).toString(),
      name: name,
    );
    _trainers.add(trainer);
    return trainer;
  }

  @override
  Future<void> delete(String trainerId) async {
    _trainers.removeWhere((trainer) => trainer.id == trainerId);
  }

  @override
  Future<List<Trainer>> list() async {
    return [..._trainers];
  }

  List<Trainer> get trainers => List<Trainer>.unmodifiable(_trainers);

  @override
  Future<Trainer> update(Trainer trainer) async {
    final index = _trainers.indexWhere(
      (candidate) => candidate.id == trainer.id,
    );
    if (index != -1) {
      _trainers[index] = trainer;
    }
    return trainer;
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
