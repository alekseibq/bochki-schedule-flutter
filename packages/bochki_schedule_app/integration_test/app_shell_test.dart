import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop shell opens menu and participant dialog',
      (tester) async {
    final participantsRepository = _InMemoryParticipantsRepository();
    final trainersRepository = _InMemoryTrainersRepository();
    final procedureKindsRepository = _InMemoryProcedureKindsRepository();
    final workdaysRepository = _InMemoryWorkdaysRepository();
    final services = AppServices(
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
      listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
      createWorkdayUseCase: CreateWorkdayUseCase(workdaysRepository),
      updateWorkdayUseCase: UpdateWorkdayUseCase(workdaysRepository),
      deleteWorkdayUseCase: DeleteWorkdayUseCase(workdaysRepository),
      flushPending: _noopAsync,
      shutdown: _noopAsync,
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);

    _openDirectoriesMenu(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тренеры').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trainers_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список тренеров'), findsOneWidget);
    expect(find.text('Тренеры (0)'), findsOneWidget);

    _openDirectoriesMenu(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Участники').last);
    await tester.pumpAndSettle();

    final participantsDialog = find.byKey(
      const Key('participants_directory_dialog'),
    );

    expect(participantsDialog, findsOneWidget);
    expect(find.text('Список участников'), findsOneWidget);
    expect(find.text('Участники (0)'), findsOneWidget);
    expect(
      find.descendant(
        of: participantsDialog,
        matching: find.text('Добавить новую запись'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _noopAsync() async {}

void _openDirectoriesMenu(WidgetTester tester) {
  final state = tester.state<PopupMenuButtonState<DirectorySection>>(
    find.byKey(const Key('directories_menu_button')),
  );
  state.showButtonMenu();
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
  final List<Participant> _participants = <Participant>[];
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
  final List<Trainer> _trainers = <Trainer>[];
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
  final List<ProcedureKind> _procedureKinds = <ProcedureKind>[];
  int _nextId = 1;

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
  final List<Workday> _workdays = <Workday>[];
  int _nextId = 1;

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
