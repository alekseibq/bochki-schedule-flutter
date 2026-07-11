import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('procedure sessions use cases', () {
    test('create clears assistant for single procedure kind', () async {
      final repository = _InMemoryProcedureSessionsRepository();
      final workdaysRepository = _InMemoryWorkdaysRepository();
      final humansRepository = _InMemoryHumansRepository();
      final procedureKindsRepository = _InMemoryProcedureKindsRepository();
      final assistantsRepository = _InMemoryAssistantsRepository();
      final programSettingsRepository = _InMemoryProgramSettingsRepository();

      final created = await CreateProcedureSessionUseCase(
        repository,
        workdaysRepository: workdaysRepository,
        humansRepository: humansRepository,
        procedureKindsRepository: procedureKindsRepository,
        assistantsRepository: assistantsRepository,
        programSettingsRepository: programSettingsRepository,
      ).execute(
        ProcedureSessionRaw(
          id: 'draft',
          dayId: '1',
          participantId: '1',
          startTime: '09:30',
          procedureKindId: '2',
          assistantId: '2',
        ),
      );

      expect(created.assistantId, isNull);
    });

    test('curated procedure kind requires assistant', () async {
      final repository = _InMemoryProcedureSessionsRepository();
      final workdaysRepository = _InMemoryWorkdaysRepository();
      final humansRepository = _InMemoryHumansRepository();
      final procedureKindsRepository = _InMemoryProcedureKindsRepository();
      final assistantsRepository = _InMemoryAssistantsRepository();
      final programSettingsRepository = _InMemoryProgramSettingsRepository();

      expect(
        () => CreateProcedureSessionUseCase(
          repository,
          workdaysRepository: workdaysRepository,
          humansRepository: humansRepository,
          procedureKindsRepository: procedureKindsRepository,
          assistantsRepository: assistantsRepository,
          programSettingsRepository: programSettingsRepository,
        ).execute(
          ProcedureSessionRaw(
            id: 'draft',
            dayId: '1',
            participantId: '1',
            startTime: '09:30',
            procedureKindId: '1',
          ),
        ),
        throwsA(
          isA<ProcedureSessionsValidationException>().having(
            (error) => error.message,
            'message',
            'Выберите ассистента.',
          ),
        ),
      );
    });

    test('list sorts by dayId startTime procedureKindId and id', () async {
      final repository = _InMemoryProcedureSessionsRepository(
        sessions: [
          ProcedureSessionRaw(
            id: '3',
            dayId: '2',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '1',
            assistantId: '2',
          ),
          ProcedureSessionRaw(
            id: '2',
            dayId: '1',
            participantId: '1',
            startTime: '10:00',
            procedureKindId: '1',
            assistantId: '2',
          ),
          ProcedureSessionRaw(
            id: '1',
            dayId: '1',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '2',
          ),
        ],
      );

      final sorted = await ListProcedureSessionsUseCase(repository).execute();

      expect(sorted.map((entry) => entry.id), ['1', '2', '3']);
    });

    test('create rejects start time before minimum hour', () async {
      final repository = _InMemoryProcedureSessionsRepository();

      expect(
        () => CreateProcedureSessionUseCase(
          repository,
          workdaysRepository: _InMemoryWorkdaysRepository(),
          humansRepository: _InMemoryHumansRepository(),
          procedureKindsRepository: _InMemoryProcedureKindsRepository(),
          assistantsRepository: _InMemoryAssistantsRepository(),
          programSettingsRepository: _InMemoryProgramSettingsRepository(),
        ).execute(
          ProcedureSessionRaw(
            id: 'draft',
            dayId: '1',
            participantId: '1',
            startTime: '07:55',
            procedureKindId: '2',
          ),
        ),
        throwsA(
          isA<ProcedureSessionsValidationException>().having(
            (error) => error.message,
            'message',
            'Время начала должно быть в диапазоне 08:00-20:55.',
          ),
        ),
      );
    });

    test('create allows start time at maximum hour minute 55', () async {
      final repository = _InMemoryProcedureSessionsRepository();

      final created = await CreateProcedureSessionUseCase(
        repository,
        workdaysRepository: _InMemoryWorkdaysRepository(),
        humansRepository: _InMemoryHumansRepository(),
        procedureKindsRepository: _InMemoryProcedureKindsRepository(),
        assistantsRepository: _InMemoryAssistantsRepository(),
        programSettingsRepository: _InMemoryProgramSettingsRepository(),
      ).execute(
        ProcedureSessionRaw(
          id: 'draft',
          dayId: '1',
          participantId: '1',
          startTime: '20:55',
          procedureKindId: '2',
        ),
      );

      expect(created.startTime, '20:55');
    });

    test('rich model computes finish time', () {
      final rich = ProcedureSessionRich(
        raw: ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          participantId: '1',
          startTime: '09:45',
          procedureKindId: '1',
          assistantId: '2',
        ),
        day: Workday(
          id: '1',
          name: 'День 1',
          calendarDate: DateTime(2026, 7, 11),
        ),
        participant: Human(
          id: '1',
          name: 'Иван',
          isParticipant: true,
          isAssistant: false,
        ),
        procedureKind: ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
        ),
        assistant: Assistant(id: '2', name: 'Петр'),
      );

      expect(rich.finishTime, '10:15');
      expect(rich.requiresAssistant, isTrue);
    });

    test('list rich sorts by workday name then time then procedure name',
        () async {
      final repository = _InMemoryProcedureSessionsRepository(
        sessions: [
          ProcedureSessionRaw(
            id: '1',
            dayId: '2',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '2',
          ),
          ProcedureSessionRaw(
            id: '2',
            dayId: '1',
            participantId: '1',
            startTime: '11:00',
            procedureKindId: '1',
            assistantId: '2',
          ),
          ProcedureSessionRaw(
            id: '3',
            dayId: '1',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '2',
          ),
        ],
      );

      final richSessions = await ListRichProcedureSessionsUseCase(
        listProcedureSessionsUseCase: ListProcedureSessionsUseCase(repository),
        listWorkdaysUseCase: ListWorkdaysUseCase(
          _InMemoryWorkdaysRepository(
            workdays: [
              Workday(
                id: '1',
                name: 'Альфа',
                calendarDate: DateTime(2026, 7, 12),
              ),
              Workday(
                id: '2',
                name: 'Бета',
                calendarDate: DateTime(2026, 7, 11),
              ),
            ],
          ),
        ),
        listHumansUseCase: ListHumansUseCase(_InMemoryHumansRepository()),
        listProcedureKindsUseCase: ListProcedureKindsUseCase(
          _InMemoryProcedureKindsRepository(),
        ),
        listAssistantsUseCase:
            ListAssistantsUseCase(_InMemoryAssistantsRepository()),
      ).execute();

      expect(richSessions.map((entry) => entry.id), ['3', '2', '1']);
    });
  });
}

final class _InMemoryProcedureSessionsRepository
    implements ProcedureSessionsRepository {
  _InMemoryProcedureSessionsRepository({
    List<ProcedureSessionRaw>? sessions,
  }) : _sessions = [...?sessions] {
    if (_sessions.isNotEmpty) {
      final maxId = _sessions
          .map((session) => int.parse(session.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<ProcedureSessionRaw> _sessions;
  int _nextId = 1;

  @override
  Future<ProcedureSessionRaw> create(
      ProcedureSessionRaw procedureSession) async {
    final created = procedureSession.copyWith(id: (_nextId++).toString());
    _sessions.add(created);
    return created;
  }

  @override
  Future<void> delete(String procedureSessionId) async {
    _sessions.removeWhere((session) => session.id == procedureSessionId);
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

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository({
    List<Workday>? workdays,
  }) : _workdays = workdays ??
            [
              Workday(
                id: '1',
                name: 'День 1',
                calendarDate: DateTime(2026, 7, 11),
              ),
            ];

  final List<Workday> _workdays;

  @override
  Future<Workday> create(Workday workday) async => workday;

  @override
  Future<void> delete(String workdayId) async {}

  @override
  Future<List<Workday>> list() async => [..._workdays];

  @override
  Future<Workday> update(Workday workday) async => workday;
}

final class _InMemoryHumansRepository implements HumansRepository {
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
  Future<List<Human>> list() async => [
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
      ];

  @override
  Future<Human> update(Human human) async => human;
}

final class _InMemoryProcedureKindsRepository
    implements ProcedureKindsRepository {
  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) async =>
      procedureKind;

  @override
  Future<void> delete(String procedureKindId) async {}

  @override
  Future<List<ProcedureKind>> list() async => [
        ProcedureKind(
          id: '1',
          patternId: ProcedureKindPatterns.curated.patternId,
          name: 'Бочка',
          capacity: 6,
          participantBusyTime: 30,
          assistantBusyTime: 10,
        ),
        ProcedureKind(
          id: '2',
          patternId: ProcedureKindPatterns.single.patternId,
          name: 'Бег',
          capacity: 2,
          participantBusyTime: 20,
        ),
      ];

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) async =>
      procedureKind;
}

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  @override
  Future<Assistant> create({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String entryId) async {}

  @override
  Future<List<Assistant>> list() async => [
        Assistant(id: '2', name: 'Петр'),
      ];

  @override
  Future<Assistant> update(Assistant entry) async => entry;
}

final class _InMemoryProgramSettingsRepository
    implements ProgramSettingsRepository {
  @override
  Future<ProgramSettings> get() async => ProgramSettings.defaults;

  @override
  Future<ProgramSettings> update(ProgramSettings settings) async => settings;
}
