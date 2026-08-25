import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcedureKindsViewModel', () {
    late _InMemoryProcedureKindsRepository repository;
    late _InMemoryProcedureSessionsRepository sessionsRepository;
    late ProcedureKindsViewModel viewModel;

    setUp(() {
      repository = _InMemoryProcedureKindsRepository(
        procedureKinds: [
          ProcedureKind(
            id: '2',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бег',
            capacity: 2,
            participantBusyTime: 20,
          ),
          ProcedureKind(
            id: '1',
            patternId: ProcedureKindPatterns.curated.patternId,
            name: 'Аромапарение',
            capacity: 6,
            participantBusyTime: 30,
            assistantBusyTime: 10,
          ),
        ],
      );
      sessionsRepository = _InMemoryProcedureSessionsRepository();
      viewModel = ProcedureKindsViewModel(
        listProcedureKindsUseCase: ListProcedureKindsUseCase(repository),
        createProcedureKindUseCase: CreateProcedureKindUseCase(repository),
        updateProcedureKindUseCase: UpdateProcedureKindUseCase(repository),
        deleteProcedureKindUseCase: DeleteProcedureKindUseCase(
          repository,
          procedureSessionsRepository: sessionsRepository,
        ),
      );
    });

    test('loads procedure kinds sorted by name', () async {
      await viewModel.loadProcedureKinds();

      expect(
          viewModel.procedureKinds.map((procedureKind) => procedureKind.name), [
        'Аромапарение',
        'Бег',
      ]);
    });

    test('create validates numeric fields on submit', () async {
      await viewModel.loadProcedureKinds();

      final createdProcedureKind = await viewModel.createProcedureKind(
        patternId: ProcedureKindPatterns.curated.patternId,
        rawName: 'Бочка',
        rawCapacity: '',
        rawParticipantBusyTime: '30',
        rawAssistantBusyTime: '10',
        rawResourceBusyTime: '5',
      );

      expect(createdProcedureKind, isNull);
      expect(viewModel.formErrorMessage, 'Укажите емкость.');
    });

    test('create clears hidden curated-only fields for grouped pattern',
        () async {
      await viewModel.loadProcedureKinds();

      final createdProcedureKind = await viewModel.createProcedureKind(
        patternId: ProcedureKindPatterns.grouped.patternId,
        rawName: 'Медитация',
        rawCapacity: '10',
        rawParticipantBusyTime: '40',
        rawAssistantBusyTime: '12',
        rawResourceBusyTime: '18',
      );

      expect(createdProcedureKind, isNotNull);
      expect(createdProcedureKind!.assistantBusyTime, isNull);
      expect(createdProcedureKind.resourceBusyTime, 40);
    });

    test('empty short name follows a renamed full name on update', () async {
      await viewModel.loadProcedureKinds();

      final updatedProcedureKind = await viewModel.updateProcedureKind(
        procedureKindId: '2',
        patternId: ProcedureKindPatterns.single.patternId,
        rawName: 'Бег с препятствиями',
        rawShortName: '   ',
        rawCapacity: '2',
        rawParticipantBusyTime: '20',
      );

      expect(updatedProcedureKind!.shortName, 'Бег с препятствиями');
    });

    test('preserves an explicit short name', () async {
      await viewModel.loadProcedureKinds();

      final createdProcedureKind = await viewModel.createProcedureKind(
        patternId: ProcedureKindPatterns.single.patternId,
        rawName: 'Бег с препятствиями',
        rawShortName: 'Бег',
        rawCapacity: '2',
        rawParticipantBusyTime: '20',
      );

      expect(createdProcedureKind!.shortName, 'Бег');
    });

    test('keeps the procedure kind when deletion is blocked by assignments',
        () async {
      sessionsRepository.sessions.add(
        ProcedureSessionRaw(
          id: '1',
          dayId: '1',
          startTime: '10:00',
          procedureKindId: '1',
        ),
      );
      await viewModel.loadProcedureKinds();

      final result = await viewModel.deleteProcedureKind('1');

      expect(result, isA<ProcedureKindDeletionBlocked>());
      expect(
        (result as ProcedureKindDeletionBlocked).referencesCount,
        1,
      );
      expect(viewModel.procedureKinds.map((entry) => entry.id), contains('1'));
    });
  });
}

final class _InMemoryProcedureSessionsRepository
    implements ProcedureSessionsRepository {
  final List<ProcedureSessionRaw> sessions = [];

  @override
  Future<ProcedureSessionRaw> create(ProcedureSessionRaw procedureSession) {
    sessions.add(procedureSession);
    return Future.value(procedureSession);
  }

  @override
  Future<void> delete(String procedureSessionId) async {
    sessions.removeWhere((session) => session.id == procedureSessionId);
  }

  @override
  Future<int> clearAll() async {
    final count = sessions.length;
    sessions.clear();
    return count;
  }

  @override
  Future<List<ProcedureSessionRaw>> list() async => [...sessions];

  @override
  Future<ProcedureSessionRaw> update(ProcedureSessionRaw procedureSession) =>
      Future.value(procedureSession);

  @override
  Future<void> updateMany(List<ProcedureSessionRaw> procedureSessions) async {
    for (final procedureSession in procedureSessions) {
      await update(procedureSession);
    }
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
