import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop shell opens menu and participant dialog',
      (tester) async {
    final participantsRepository = _InMemoryParticipantsRepository();
    final assistantsRepository = _InMemoryAssistantsRepository();
    final procedureKindsRepository = _InMemoryProcedureKindsRepository();
    final workdaysRepository = _InMemoryWorkdaysRepository();
    final humansRepository = _InMemoryHumansRepository(
      participants: participantsRepository.participants,
      assistants: assistantsRepository.assistants,
    );
    final procedureSessionsRepository = _InMemoryProcedureSessionsRepository();
    final programSettingsRepository = _InMemoryProgramSettingsRepository();
    final printPresetParamsRepository = _InMemoryPrintPresetParamsRepository();
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
    final buildPrintScheduleDocumentUseCase = BuildPrintScheduleDocumentUseCase(
      listRichProcedureSessionsUseCase: listRichProcedureSessionsUseCase,
      listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
    );
    final savePrintScheduleFileUseCase = SavePrintScheduleFileUseCase(
      updatePrintPresetParamsUseCase:
          UpdatePrintPresetParamsUseCase(printPresetParamsRepository),
      buildPrintScheduleDocumentUseCase: buildPrintScheduleDocumentUseCase,
      printScheduleExporter: _FakePrintScheduleExporter(),
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
    );
    final services = AppServices(
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
      savePrintScheduleFileUseCase: savePrintScheduleFileUseCase,
      openPrintScheduleFileUseCase: OpenPrintScheduleFileUseCase(
        savePrintScheduleFileUseCase: savePrintScheduleFileUseCase,
        documentOpener: _FakeDocumentOpener(),
      ),
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
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);

    _openDirectoriesMenu(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ассистенты').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('assistants_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список ассистентов'), findsOneWidget);
    expect(find.text('Ассистенты (0)'), findsOneWidget);

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

final class _FakePrintScheduleExporter implements PrintScheduleExporter {
  @override
  Future<File> export({
    required PrintScheduleDocument document,
    required Directory outputDirectory,
  }) async {
    return File('${outputDirectory.path}/test.docx');
  }
}

final class _FakeDocumentOpener implements DocumentOpener {
  @override
  Future<void> open(File file) async {}
}

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  final List<Participant> _participants = <Participant>[];
  int _nextId = 1;

  List<Participant> get participants =>
      List<Participant>.unmodifiable(_participants);

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

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  final List<Assistant> _assistants = <Assistant>[];
  int _nextId = 1;

  List<Assistant> get assistants => List<Assistant>.unmodifiable(_assistants);

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

final class _InMemoryProgramSettingsRepository
    implements ProgramSettingsRepository {
  ProgramSettings _settings = ProgramSettings.defaults;

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
  PrintPresetParams _params = PrintPresetParams.defaults;

  @override
  Future<PrintPresetParams> get() async => _params;

  @override
  Future<PrintPresetParams> update(PrintPresetParams params) async {
    _params = params;
    return _params;
  }
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
  final List<ProcedureSessionRaw> _sessions = <ProcedureSessionRaw>[];

  @override
  Future<ProcedureSessionRaw> create(
    ProcedureSessionRaw procedureSession,
  ) async {
    _sessions.add(procedureSession);
    return procedureSession;
  }

  @override
  Future<void> delete(String procedureSessionId) async {
    _sessions.removeWhere((entry) => entry.id == procedureSessionId);
  }

  @override
  Future<List<ProcedureSessionRaw>> list() async => [..._sessions];

  @override
  Future<ProcedureSessionRaw> update(
    ProcedureSessionRaw procedureSession,
  ) async {
    final index =
        _sessions.indexWhere((entry) => entry.id == procedureSession.id);
    if (index != -1) {
      _sessions[index] = procedureSession;
    }
    return procedureSession;
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
