import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('build print schedule document use case', () {
    test('builds rows sorted by participant name', () async {
      final useCase = _buildUseCase(
        participants: [
          Participant(id: '1', name: 'Петров Петр'),
          Participant(id: '2', name: 'Иванов Иван'),
        ],
        procedureKinds: [
          ProcedureKind(
            id: '1',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 1,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ],
        workdays: [
          Workday(
            id: '1',
            name: 'Пятница',
            calendarDate: DateTime(2026, 7, 17),
          ),
        ],
        sessions: [
          ProcedureSessionRaw(
            id: '10',
            dayId: '1',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '1',
          ),
          ProcedureSessionRaw(
            id: '11',
            dayId: '1',
            participantId: '2',
            startTime: '10:00',
            procedureKindId: '1',
          ),
        ],
      );

      final document = await useCase.execute(
        params: const PrintPresetParams(
          workdayId: '1',
          textBefore: 'Начало',
          textAfter: 'Конец',
        ),
        groupBy: PrintScheduleGroupBy.byNames,
      );

      expect(document.title, 'Дата расписания 17.07.2026');
      expect(
        document.rows.map((row) => row.participantName).toList(),
        ['Иванов Иван', 'Петров Петр'],
      );
    });

    test('builds rows sorted by time and fills missing values', () async {
      final useCase = _buildUseCase(
        workdays: [
          Workday(
            id: '1',
            name: 'Пятница',
            calendarDate: DateTime(2026, 7, 17),
          ),
        ],
        sessions: [
          ProcedureSessionRaw(
            id: '2',
            dayId: '1',
            participantId: 'missing',
            startTime: '09:00',
            procedureKindId: 'missing',
          ),
          ProcedureSessionRaw(
            id: '1',
            dayId: '1',
            participantId: 'missing',
            startTime: '08:00',
            procedureKindId: 'missing',
          ),
        ],
      );

      final document = await useCase.execute(
        params: const PrintPresetParams(
          workdayId: '1',
          textBefore: '',
          textAfter: '',
        ),
        groupBy: PrintScheduleGroupBy.byTime,
      );

      expect(
        document.rows.map((row) => row.startTime).toList(),
        ['08:00', '09:00'],
      );
      expect(document.rows.first.participantName, 'Не найден');
      expect(document.rows.first.procedureName, 'Не найдено');
      expect(document.rows.first.assistantName, isEmpty);
    });
  });

  group('print schedule file use cases', () {
    test('save updates params and exports document', () async {
      final repository = _InMemoryPrintPresetParamsRepository(
        const PrintPresetParams(
          workdayId: '1',
          textBefore: '',
          textAfter: '',
        ),
      );
      final exporter = _SpyPrintScheduleExporter();
      final saveUseCase = SavePrintScheduleFileUseCase(
        updatePrintPresetParamsUseCase: UpdatePrintPresetParamsUseCase(
          repository,
        ),
        buildPrintScheduleDocumentUseCase: _buildUseCase(
          participants: [
            Participant(id: '1', name: 'Иванов Иван'),
          ],
          procedureKinds: [
            ProcedureKind(
              id: '1',
              patternId: ProcedureKindPatterns.single.patternId,
              name: 'Бочка',
              capacity: 1,
              participantBusyTime: 30,
              resourceBusyTime: 30,
            ),
          ],
          workdays: [
            Workday(
              id: '1',
              name: 'Пятница',
              calendarDate: DateTime(2026, 7, 17),
            ),
          ],
          sessions: [
            ProcedureSessionRaw(
              id: '1',
              dayId: '1',
              participantId: '1',
              startTime: '09:00',
              procedureKindId: '1',
            ),
          ],
        ),
        printScheduleExporter: exporter,
        appDataDirectory: Directory('/tmp/bochki_schedule_save_use_case_test'),
      );

      await saveUseCase.execute(
        workdayId: '1',
        textBefore: 'A',
        textAfter: 'B',
        groupBy: PrintScheduleGroupBy.byTime,
      );

      expect(repository.params.textBefore, 'A');
      expect(exporter.callCount, 1);
      expect(exporter.lastOutputDirectory?.path, contains('/exports'));
    });

    test('open exports file and opens it', () async {
      final repository = _InMemoryPrintPresetParamsRepository(
        const PrintPresetParams(
          workdayId: '1',
          textBefore: '',
          textAfter: '',
        ),
      );
      final exporter = _SpyPrintScheduleExporter();
      final opener = _SpyDocumentOpener();
      final saveUseCase = SavePrintScheduleFileUseCase(
        updatePrintPresetParamsUseCase: UpdatePrintPresetParamsUseCase(
          repository,
        ),
        buildPrintScheduleDocumentUseCase: _buildUseCase(
          workdays: [
            Workday(
              id: '1',
              name: 'Пятница',
              calendarDate: DateTime(2026, 7, 17),
            ),
          ],
        ),
        printScheduleExporter: exporter,
        appDataDirectory: Directory('/tmp/bochki_schedule_open_use_case_test'),
      );
      final openUseCase = OpenPrintScheduleFileUseCase(
        savePrintScheduleFileUseCase: saveUseCase,
        documentOpener: opener,
      );

      await openUseCase.execute(
        workdayId: '1',
        textBefore: '',
        textAfter: '',
        groupBy: PrintScheduleGroupBy.byNames,
      );

      expect(exporter.callCount, 1);
      expect(opener.callCount, 1);
    });
  });
}

BuildPrintScheduleDocumentUseCase _buildUseCase({
  List<Participant> participants = const [],
  List<Assistant> assistants = const [],
  List<ProcedureKind> procedureKinds = const [],
  required List<Workday> workdays,
  List<ProcedureSessionRaw> sessions = const [],
}) {
  return BuildPrintScheduleDocumentUseCase(
    listRichProcedureSessionsUseCase: ListRichProcedureSessionsUseCase(
      listProcedureSessionsUseCase: ListProcedureSessionsUseCase(
        _InMemoryProcedureSessionsRepository(sessions),
      ),
      listWorkdaysUseCase: ListWorkdaysUseCase(
        _InMemoryWorkdaysRepository(workdays),
      ),
      listHumansUseCase: ListHumansUseCase(
        _InMemoryHumansRepository(
          participants: participants,
          assistants: assistants,
        ),
      ),
      listProcedureKindsUseCase: ListProcedureKindsUseCase(
        _InMemoryProcedureKindsRepository(procedureKinds),
      ),
      listAssistantsUseCase: ListAssistantsUseCase(
        _InMemoryAssistantsRepository(assistants),
      ),
    ),
    listWorkdaysUseCase: ListWorkdaysUseCase(
      _InMemoryWorkdaysRepository(workdays),
    ),
  );
}

final class _InMemoryPrintPresetParamsRepository
    implements PrintPresetParamsRepository {
  _InMemoryPrintPresetParamsRepository(this.params);

  PrintPresetParams params;

  @override
  Future<PrintPresetParams> get() async => params;

  @override
  Future<PrintPresetParams> update(PrintPresetParams nextParams) async {
    params = nextParams;
    return params;
  }
}

final class _SpyPrintScheduleExporter implements PrintScheduleExporter {
  int callCount = 0;
  Directory? lastOutputDirectory;

  @override
  Future<File> export({
    required PrintScheduleDocument document,
    required Directory outputDirectory,
  }) async {
    callCount += 1;
    lastOutputDirectory = outputDirectory;
    return File('${outputDirectory.path}/result.docx');
  }
}

final class _SpyDocumentOpener implements DocumentOpener {
  int callCount = 0;

  @override
  Future<void> open(File file) async {
    callCount += 1;
  }
}

final class _InMemoryProcedureSessionsRepository
    implements ProcedureSessionsRepository {
  _InMemoryProcedureSessionsRepository(this._sessions);

  final List<ProcedureSessionRaw> _sessions;

  @override
  Future<ProcedureSessionRaw> create(ProcedureSessionRaw procedureSession) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String procedureSessionId) async {}

  @override
  Future<List<ProcedureSessionRaw>> list() async => [..._sessions];

  @override
  Future<ProcedureSessionRaw> update(ProcedureSessionRaw procedureSession) {
    throw UnimplementedError();
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
              isAssistant: false,
            ),
          for (final assistant in assistants)
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
  Future<Human> update(Human human) {
    throw UnimplementedError();
  }
}

final class _InMemoryProcedureKindsRepository
    implements ProcedureKindsRepository {
  _InMemoryProcedureKindsRepository(this._procedureKinds);

  final List<ProcedureKind> _procedureKinds;

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String procedureKindId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProcedureKind>> list() async => [..._procedureKinds];

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) {
    throw UnimplementedError();
  }
}

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  _InMemoryAssistantsRepository(this._assistants);

  final List<Assistant> _assistants;

  @override
  Future<Assistant> create({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String assistantId) async {}

  @override
  Future<List<Assistant>> list() async => [..._assistants];

  @override
  Future<Assistant> update(Assistant assistant) {
    throw UnimplementedError();
  }
}

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository(this._workdays);

  final List<Workday> _workdays;

  @override
  Future<Workday> create(Workday workday) {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String workdayId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Workday>> list() async => [..._workdays];

  @override
  Future<Workday> update(Workday workday) {
    throw UnimplementedError();
  }
}
