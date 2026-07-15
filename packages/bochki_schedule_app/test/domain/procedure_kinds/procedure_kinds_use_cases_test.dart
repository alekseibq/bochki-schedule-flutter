import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('procedure kinds use cases', () {
    test('list loads sorted procedure kinds', () async {
      final repository = _InMemoryProcedureKindsRepository(
        procedureKinds: [
          ProcedureKind(
            id: '2',
            patternId: ProcedureKindPatterns.single.patternId,
            name: 'Бег',
            capacity: 3,
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

      final procedureKinds =
          await ListProcedureKindsUseCase(repository).execute();

      expect(
        procedureKinds.map((procedureKind) => procedureKind.name),
        ['Аромапарение', 'Бег'],
      );
    });

    test('create clears curated-only fields for single pattern', () async {
      final repository = _InMemoryProcedureKindsRepository();

      final createdProcedureKind =
          await CreateProcedureKindUseCase(repository).execute(
        ProcedureKind(
          id: 'draft',
          patternId: ProcedureKindPatterns.single.patternId,
          name: 'Бег',
          capacity: 3,
          participantBusyTime: 20,
          assistantBusyTime: 10,
          resourceBusyTime: 5,
        ),
      );

      expect(createdProcedureKind.assistantBusyTime, isNull);
      expect(createdProcedureKind.resourceBusyTime, 20);
    });

    test('duplicate name does not pass validation', () async {
      final repository = _InMemoryProcedureKindsRepository(
        procedureKinds: [
          ProcedureKind(
            id: '1',
            patternId: ProcedureKindPatterns.curated.patternId,
            name: 'Бочка',
            capacity: 6,
            participantBusyTime: 30,
          ),
        ],
      );

      expect(
        () => CreateProcedureKindUseCase(repository).execute(
          ProcedureKind(
            id: 'draft',
            patternId: ProcedureKindPatterns.single.patternId,
            name: '  Бочка ',
            capacity: 2,
            participantBusyTime: 20,
          ),
        ),
        throwsA(
          isA<ProcedureKindsValidationException>().having(
            (error) => error.message,
            'message',
            'Вид процедуры с таким названием уже есть.',
          ),
        ),
      );
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
