import 'package:bochki_schedule_app/src/application/participants_directory_use_case.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active participants are sorted and deleted entries are hidden',
      () async {
    final repository = _MemoryProjectDocumentRepository(
      const ProjectDocument(
        nextId: 4,
        participants: <Map<String, Object?>>[
          <String, Object?>{'id': 3, 'name': 'Вася', 'deleted': false},
          <String, Object?>{'id': 1, 'name': 'Анна', 'deleted': true},
          <String, Object?>{'id': 2, 'name': 'Борис', 'deleted': false},
        ],
      ),
    );
    final useCase = ParticipantsDirectoryUseCase(repository: repository);

    final active = useCase.activeParticipants(await useCase.loadDocument());

    expect(active.map((participant) => participant['name']), [
      'Борис',
      'Вася',
    ]);
  });

  test('add participant normalizes name and increments nextId', () async {
    final repository =
        _MemoryProjectDocumentRepository(ProjectDocument.initial());
    final useCase = ParticipantsDirectoryUseCase(repository: repository);

    final result = await useCase.addParticipant(
      await useCase.loadDocument(),
      '  Иван   Иванов  ',
    );

    expect(result.isSuccess, isTrue);
    expect(result.document!.nextId, 2);
    expect(result.document!.participants.single['name'], 'Иван Иванов');
    expect(repository.document.participants.single['name'], 'Иван Иванов');
  });

  test('duplicate participant name is rejected', () async {
    final repository = _MemoryProjectDocumentRepository(
      const ProjectDocument(
        nextId: 3,
        participants: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Иван Иванов', 'deleted': false},
          <String, Object?>{'id': 2, 'name': 'Петр Петров', 'deleted': false},
        ],
      ),
    );
    final useCase = ParticipantsDirectoryUseCase(repository: repository);

    final result = await useCase.addParticipant(
      await useCase.loadDocument(),
      'Иван Иванов',
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, 'Участник с таким именем уже есть.');
    expect(repository.document.participants.length, 2);
  });

  test('edit participant can keep the same name', () async {
    final repository = _MemoryProjectDocumentRepository(
      const ProjectDocument(
        nextId: 3,
        participants: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Иван Иванов', 'deleted': false},
          <String, Object?>{'id': 2, 'name': 'Петр Петров', 'deleted': false},
        ],
      ),
    );
    final useCase = ParticipantsDirectoryUseCase(repository: repository);

    final result = await useCase.editParticipant(
      await useCase.loadDocument(),
      1,
      'Иван Иванов',
    );

    expect(result.isSuccess, isTrue);
    expect(
      result.document!.participants.firstWhere(
        (participant) => participant['id'] == 1,
      )['name'],
      'Иван Иванов',
    );
    expect(repository.document.participants.length, 2);
  });

  test('delete participant soft deletes entry', () async {
    final repository = _MemoryProjectDocumentRepository(
      const ProjectDocument(
        nextId: 2,
        participants: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Иван Иванов', 'deleted': false},
        ],
      ),
    );
    final useCase = ParticipantsDirectoryUseCase(repository: repository);

    final result = await useCase.deleteParticipant(
      await useCase.loadDocument(),
      1,
    );

    expect(result.isSuccess, isTrue);
    expect(result.document!.participants.single['deleted'], isTrue);
    expect(repository.document.participants.single['deleted'], isTrue);
  });
}

final class _MemoryProjectDocumentRepository
    implements ProjectDocumentRepository {
  _MemoryProjectDocumentRepository(this.document);

  ProjectDocument document;

  @override
  Future<ProjectDocument> load() async => document;

  @override
  Future<void> save(ProjectDocument updatedDocument) async {
    document = updatedDocument;
  }
}
