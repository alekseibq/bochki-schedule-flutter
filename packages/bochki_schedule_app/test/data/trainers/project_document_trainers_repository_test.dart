import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_app/src/data/trainers/project_document_trainers_repository.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads active trainers from memory and preserves deleted rows', () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentTrainersRepository(
      initialDocument: const ProjectDocument(
        nextId: 5,
        trainers: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Анна', 'deleted': false},
          <String, Object?>{'id': 2, 'name': 'Борис', 'deleted': true},
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(
        nextId: 5,
        onChanged: () {
          changeNotifications += 1;
        },
      ),
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final trainers = await repository.list();
    final exportedDocument = repository.applyToDocument(ProjectDocument.initial());

    expect(trainers.map((trainer) => trainer.name), ['Анна']);
    expect(exportedDocument.trainers, [
      <String, Object?>{'id': 1, 'name': 'Анна', 'deleted': false},
      <String, Object?>{'id': 2, 'name': 'Борис', 'deleted': true},
    ]);
    expect(repository.isDirty, isFalse);
    expect(changeNotifications, 0);
  });

  test('create update and delete stay in memory and mark repository dirty',
      () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 3,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final repository = ProjectDocumentTrainersRepository(
      initialDocument: const ProjectDocument(
        nextId: 3,
        trainers: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Борис', 'deleted': false},
          <String, Object?>{'id': 2, 'name': 'Анна', 'deleted': false},
        ],
      ),
      idAllocator: idAllocator,
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final created = await repository.create(name: 'Василий');
    await repository.update(created.copyWith(name: 'Василиса'));
    await repository.delete('1');

    final trainers = await repository.list();
    final exportedDocument = repository.applyToDocument(
      const ProjectDocument(nextId: 4),
    );

    expect(created.id, '3');
    expect(
      trainers.map((trainer) => trainer.name),
      ['Анна', 'Василиса'],
    );
    expect(exportedDocument.trainers, [
      <String, Object?>{'id': 2, 'name': 'Анна', 'deleted': false},
      <String, Object?>{'id': 1, 'name': 'Борис', 'deleted': true},
      <String, Object?>{'id': 3, 'name': 'Василиса', 'deleted': false},
    ]);
    expect(repository.isDirty, isTrue);
    expect(changeNotifications, 4);
  });
}
