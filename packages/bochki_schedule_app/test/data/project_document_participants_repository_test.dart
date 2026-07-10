import 'package:bochki_schedule_app/src/data/humans/project_document_humans_repository.dart';
import 'package:bochki_schedule_app/src/data/participants/project_document_participants_repository.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads active participants from memory and preserves deleted rows',
      () async {
    var changeNotifications = 0;
    final humansRepository = ProjectDocumentHumansRepository(
      initialDocument: const ProjectDocument(
        nextId: 5,
        humans: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'name': 'Анна',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
            'name': 'Борис',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': true,
          },
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
    final repository = ProjectDocumentParticipantsRepository(
      humansRepository: humansRepository,
    );

    final participants = await repository.list();
    final exportedDocument =
        humansRepository.applyToDocument(ProjectDocument.initial());

    expect(participants.map((participant) => participant.name), ['Анна']);
    expect(exportedDocument.humans, [
      <String, Object?>{
        'id': 1,
        'name': 'Анна',
        'isParticipant': true,
        'isAssistant': false,
        'deleted': false,
      },
      <String, Object?>{
        'id': 2,
        'name': 'Борис',
        'isParticipant': true,
        'isAssistant': false,
        'deleted': true,
      },
    ]);
    expect(humansRepository.isDirty, isFalse);
    expect(changeNotifications, 0);
  });

  test('participant delete clears only participant role when assistant remains',
      () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 3,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final humansRepository = ProjectDocumentHumansRepository(
      initialDocument: const ProjectDocument(
        nextId: 3,
        humans: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'name': 'Борис',
            'isParticipant': true,
            'isAssistant': true,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
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
    final repository = ProjectDocumentParticipantsRepository(
      humansRepository: humansRepository,
    );

    final created = await repository.create(name: 'Василий');
    await repository.update(created.copyWith(name: 'Василиса'));
    await repository.delete('1');

    final participants = await repository.list();
    final exportedDocument =
        humansRepository.applyToDocument(const ProjectDocument(nextId: 4));

    expect(created.id, '3');
    expect(
      participants.map((participant) => participant.name),
      ['Анна', 'Василиса'],
    );
    expect(exportedDocument.humans, [
      <String, Object?>{
        'id': 2,
        'name': 'Анна',
        'isParticipant': true,
        'isAssistant': false,
        'deleted': false,
      },
      <String, Object?>{
        'id': 1,
        'name': 'Борис',
        'isParticipant': false,
        'isAssistant': true,
        'deleted': false,
      },
      <String, Object?>{
        'id': 3,
        'name': 'Василиса',
        'isParticipant': true,
        'isAssistant': false,
        'deleted': false,
      },
    ]);
    expect(humansRepository.isDirty, isTrue);
    expect(changeNotifications, 4);
  });
}
