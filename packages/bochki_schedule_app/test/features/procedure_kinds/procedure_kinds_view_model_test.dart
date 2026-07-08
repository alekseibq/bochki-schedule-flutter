import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcedureKindsViewModel', () {
    late _InMemoryProcedureKindsRepository repository;
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
      viewModel = ProcedureKindsViewModel(
        listProcedureKindsUseCase: ListProcedureKindsUseCase(repository),
        createProcedureKindUseCase: CreateProcedureKindUseCase(repository),
        updateProcedureKindUseCase: UpdateProcedureKindUseCase(repository),
        deleteProcedureKindUseCase: DeleteProcedureKindUseCase(repository),
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
      expect(createdProcedureKind.resourceBusyTime, isNull);
    });
  });
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
