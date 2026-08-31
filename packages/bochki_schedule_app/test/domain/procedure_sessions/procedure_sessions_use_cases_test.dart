import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('procedure sessions use cases', () {
    test('clear removes all procedure sessions and returns their count',
        () async {
      final repository = _InMemoryProcedureSessionsRepository(
        sessions: [
          ProcedureSessionRaw(
            id: '1',
            dayId: '1',
            participantId: '1',
            startTime: '09:00',
            procedureKindId: '1',
          ),
          ProcedureSessionRaw(
            id: '2',
            dayId: '2',
            participantId: '2',
            startTime: '10:00',
            procedureKindId: '2',
          ),
        ],
      );

      final cleared = await ClearProcedureSessionsUseCase(repository).execute();

      expect(cleared, 2);
      expect(await repository.list(), isEmpty);
    });

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

    test('create allows an assistant human as the procedure participant',
        () async {
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
          participantId: '2',
          startTime: '09:30',
          procedureKindId: '2',
        ),
      );

      expect(created.participantId, '2');
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

    test('grouped procedure kind requires assistant', () async {
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
            startTime: '09:30',
            procedureKindId: '3',
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

    test('create allows start time before minimum hour', () async {
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
          startTime: '07:55',
          procedureKindId: '2',
        ),
      );

      expect(created.startTime, '07:55');
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
      expect(rich.assistantFinishTime, '09:55');
      expect(rich.resourceFinishTime, isNull);
      expect(rich.requiresAssistant, isTrue);
    });

    test('conflict calculator detects participant and equipment conflicts', () {
      const calculator = ProcedureSessionConflictCalculator();
      final conflicts = calculator.calculate([
        _buildRichSession(
          id: '1',
          participantId: '10',
          startTime: '10:00',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 1,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ),
        _buildRichSession(
          id: '2',
          participantId: '10',
          startTime: '10:10',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 1,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ),
      ], programSettings: ProgramSettings.defaults);

      expect(conflicts, hasLength(4));
      expect(
        conflicts.where(
            (conflict) => conflict.resourceType == ConflictResourceType.human),
        hasLength(2),
      );
      expect(
        conflicts.where(
            (conflict) => conflict.resourceType == ConflictResourceType.item),
        hasLength(2),
      );
      expect(conflicts.first.timeStart, '10:10');
      expect(conflicts.first.timeFinish, '10:30');
    });

    test('conflict calculator ignores boundary touch and respects capacity',
        () {
      const calculator = ProcedureSessionConflictCalculator();
      final noConflicts = calculator.calculate([
        _buildRichSession(
          id: '1',
          participantId: '10',
          startTime: '10:00',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 2,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ),
        _buildRichSession(
          id: '2',
          participantId: '11',
          startTime: '10:30',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 2,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ),
        _buildRichSession(
          id: '3',
          participantId: '12',
          startTime: '10:00',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бочка',
            capacity: 2,
            participantBusyTime: 30,
            resourceBusyTime: 30,
          ),
        ),
      ], programSettings: ProgramSettings.defaults);

      expect(noConflicts, isEmpty);
    });

    test('grouped sessions sharing a leader and start time do not conflict',
        () {
      const calculator = ProcedureSessionConflictCalculator();
      final groupedKind = ProcedureKind(
        id: '100',
        patternId: ProcedureKindPatterns.grouped.patternId,
        name: 'Медитация',
        capacity: 2,
        participantBusyTime: 30,
      ).sanitizedForPersistence();

      final conflicts = calculator.calculate([
        _buildRichSession(
          id: '1',
          participantId: '10',
          startTime: '10:00',
          procedureKind: groupedKind,
          assistantId: '20',
        ),
        _buildRichSession(
          id: '2',
          participantId: '11',
          startTime: '10:00',
          procedureKind: groupedKind,
          assistantId: '20',
        ),
      ], programSettings: ProgramSettings.defaults);

      expect(conflicts, isEmpty);
    });

    test('grouped sessions with a shared leader at different times conflict',
        () {
      const calculator = ProcedureSessionConflictCalculator();
      final groupedKind = ProcedureKind(
        id: '100',
        patternId: ProcedureKindPatterns.grouped.patternId,
        name: 'Медитация',
        capacity: 2,
        participantBusyTime: 30,
      ).sanitizedForPersistence();

      final conflicts = calculator.calculate([
        _buildRichSession(
          id: '1',
          participantId: '10',
          startTime: '10:00',
          procedureKind: groupedKind,
          assistantId: '20',
        ),
        _buildRichSession(
          id: '2',
          participantId: '11',
          startTime: '10:15',
          procedureKind: groupedKind,
          assistantId: '20',
        ),
      ], programSettings: ProgramSettings.defaults);

      expect(
        conflicts.where((conflict) => conflict.humanId == '20'),
        hasLength(2),
      );
    });

    test('conflict calculator reports missing required assignments', () {
      const calculator = ProcedureSessionConflictCalculator();
      final kind = ProcedureKind(
        id: '100',
        patternId: ProcedureKindPatterns.curated.patternId,
        name: 'Бочка',
        capacity: 1,
        participantBusyTime: 30,
        assistantBusyTime: 30,
      );
      final session = ProcedureSessionRich(
        raw: ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          startTime: '10:00',
          procedureKindId: kind.id,
        ),
        day: Workday(
          id: '1',
          name: 'День 1',
          calendarDate: DateTime(2026, 7, 11),
        ),
        participant: null,
        procedureKind: kind,
        assistant: null,
      );

      final conflicts = calculator.calculate(
        [session],
        programSettings: ProgramSettings.defaults,
      );

      expect(
        conflicts
            .where(
              (conflict) =>
                  conflict.type == ScheduleConflictType.missingAssignment,
            )
            .map((conflict) => conflict.message),
        containsAll(['Не назначен участник.', 'Не назначен ассистент.']),
      );
    });

    test('conflict calculator reports exact time-boundary violations', () {
      const calculator = ProcedureSessionConflictCalculator();
      const settings = ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 12, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 13, minute: 0),
        minimumTime: ProgramSettingsTime(hour: 8, minute: 15),
        maximumTime: ProgramSettingsTime(hour: 19, minute: 40),
      );

      final conflicts = calculator.calculate([
        _buildRichSession(
          id: '1',
          participantId: '10',
          startTime: '08:10',
          assistantId: '20',
          procedureKind: ProcedureKind(
            id: '100',
            patternId: ProcedureKindPatterns.curated.patternId,
            name: 'Бочка',
            capacity: 1,
            participantBusyTime: 100,
            assistantBusyTime: 700,
            resourceBusyTime: 1000,
          ),
        ),
      ], programSettings: settings);

      expect(
          conflicts
              .where((item) => item.type == ScheduleConflictType.timeBoundary),
          hasLength(2));
      expect(
        conflicts.map((item) => item.message),
        contains(contains('раньше минимального времени 08:15')),
      );
      expect(
        conflicts.map((item) => item.message),
        contains(allOf(
          contains('ассистент до 19:50'),
          contains('ресурс до 00:50 следующего дня'),
        )),
      );
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

ProcedureSessionRich _buildRichSession({
  required String id,
  required String participantId,
  required String startTime,
  required ProcedureKind procedureKind,
  String dayId = '1',
  String? assistantId,
}) {
  return ProcedureSessionRich(
    raw: ProcedureSessionRaw(
      id: id,
      dayId: dayId,
      participantId: participantId,
      startTime: startTime,
      procedureKindId: procedureKind.id,
      assistantId: assistantId,
    ),
    day: Workday(
      id: dayId,
      name: 'День 1',
      calendarDate: DateTime(2026, 7, 11),
    ),
    participant: Human(
      id: participantId,
      name: 'Участник $participantId',
      isParticipant: true,
      isAssistant: false,
    ),
    procedureKind: procedureKind,
    assistant: assistantId == null
        ? null
        : Assistant(id: assistantId, name: 'Ассистент $assistantId'),
  );
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

  @override
  Future<int> clearAll() async {
    final sessions = await list();
    for (final session in sessions) {
      await delete(session.id);
    }
    return sessions.length;
  }

  @override
  Future<void> updateMany(List<ProcedureSessionRaw> sessions) async {}
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
        ProcedureKind(
          id: '3',
          patternId: ProcedureKindPatterns.grouped.patternId,
          name: 'Медитация',
          capacity: 6,
          participantBusyTime: 30,
        ).sanitizedForPersistence(),
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
