import 'package:bochki_schedule_app/src/data/humans/project_document_humans_repository.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads humans and persists role flags', () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentHumansRepository(
      initialDocument: const ProjectDocument(
        nextId: 4,
        humans: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'name': 'Анна',
            'isParticipant': true,
            'isAssistant': true,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
            'name': 'Борис',
            'isParticipant': false,
            'isAssistant': true,
            'deleted': true,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(
        nextId: 4,
        onChanged: () {
          changeNotifications += 1;
        },
      ),
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final humans = await repository.list();
    final exportedDocument =
        repository.applyToDocument(ProjectDocument.initial());

    expect(humans, hasLength(1));
    expect(humans.single.isParticipant, isTrue);
    expect(humans.single.isAssistant, isTrue);
    expect(exportedDocument.humans.first['isAssistant'], isTrue);
    expect(repository.isDirty, isFalse);
    expect(changeNotifications, 0);
  });

  test('update changes roles and delete soft deletes human', () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 2,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final repository = ProjectDocumentHumansRepository(
      initialDocument: const ProjectDocument(
        nextId: 2,
        humans: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'name': 'Анна',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': false,
          },
        ],
      ),
      idAllocator: idAllocator,
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final created = await repository.create(
      name: 'Борис',
      isParticipant: false,
      isAssistant: true,
    );
    await repository.update(
      created.copyWith(
        name: 'Борис Общий',
        isParticipant: true,
      ),
    );
    await repository.delete('1');

    final humans = await repository.list();
    final exportedDocument = repository.applyToDocument(
      const ProjectDocument(nextId: 3),
    );

    expect(created.id, '2');
    expect(humans.single.name, 'Борис Общий');
    expect(humans.single.isParticipant, isTrue);
    expect(humans.single.isAssistant, isTrue);
    expect(exportedDocument.humans, [
      <String, Object?>{
        'id': 1,
        'name': 'Анна',
        'isParticipant': false,
        'isAssistant': false,
        'deleted': true,
      },
      <String, Object?>{
        'id': 2,
        'name': 'Борис Общий',
        'isParticipant': true,
        'isAssistant': true,
        'deleted': false,
      },
    ]);
    expect(repository.isDirty, isTrue);
    expect(changeNotifications, 4);
  });
}
