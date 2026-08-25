import 'package:bochki_schedule_app/src/data/procedure_sessions/project_document_procedure_sessions_repository.dart';
import 'package:bochki_schedule_app/src/data/humans/project_document_humans_repository.dart';
import 'package:bochki_schedule_app/src/data/participants/project_document_participants_repository.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository clears active procedure sessions in one change', () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentProcedureSessionsRepository(
      initialDocument: const ProjectDocument(
        nextId: 4,
        procedureSessions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'dayId': 1,
            'participantId': 10,
            'startTime': '09:00',
            'procedureKindId': 100,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
            'dayId': 1,
            'participantId': 11,
            'startTime': '10:00',
            'procedureKindId': 101,
            'deleted': true,
          },
          <String, Object?>{
            'id': 3,
            'dayId': 2,
            'participantId': 12,
            'startTime': '11:00',
            'procedureKindId': 102,
            'deleted': false,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(nextId: 4, onChanged: () {}),
      onChanged: () => changeNotifications += 1,
    );

    expect(await repository.clearAll(), 2);
    expect(await repository.list(), isEmpty);
    expect(changeNotifications, 1);
    expect(
      repository
          .applyToDocument(const ProjectDocument(nextId: 4))
          .procedureSessions
          .every((entry) => entry['deleted'] == true),
      isTrue,
    );
  });

  test('repository create update and delete persist procedure sessions',
      () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 3,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final repository = ProjectDocumentProcedureSessionsRepository(
      initialDocument: const ProjectDocument(
        nextId: 3,
        procedureSessions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'dayId': 1,
            'participantId': 10,
            'startTime': '09:00',
            'procedureKindId': 100,
            'assistantId': 20,
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
      ProcedureSessionRaw(
        id: 'draft',
        dayId: '2',
        participantId: '11',
        startTime: '10:30',
        procedureKindId: '101',
      ),
    );
    await repository.update(
      created.copyWith(startTime: '11:00'),
    );
    await repository.delete('1');

    final sessions = await repository.list();
    final exportedDocument =
        repository.applyToDocument(const ProjectDocument(nextId: 4));

    expect(sessions, hasLength(1));
    expect(sessions.single.startTime, '11:00');
    expect(exportedDocument.procedureSessions, [
      <String, Object?>{
        'id': 1,
        'dayId': 1,
        'clientId': 10,
        'startTime': '09:00',
        'procedureKindId': 100,
        'companionId': 20,
        'deleted': true,
      },
      <String, Object?>{
        'id': 3,
        'dayId': 2,
        'clientId': 11,
        'startTime': '11:00',
        'procedureKindId': 101,
        'companionId': null,
        'deleted': false,
      },
    ]);
    expect(changeNotifications, 4);
  });

  test('repository persists explicitly cleared participant and assistant ids',
      () async {
    final repository = ProjectDocumentProcedureSessionsRepository(
      initialDocument: const ProjectDocument(
        nextId: 2,
        procedureSessions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'dayId': 1,
            'participantId': 10,
            'assistantId': 20,
            'startTime': '09:00',
            'procedureKindId': 100,
            'deleted': false,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(nextId: 2, onChanged: () {}),
      onChanged: () {},
    );

    final session = (await repository.list()).single;
    await repository.update(session.copyWith(
      clearParticipantId: true,
      clearAssistantId: true,
    ));

    final stored = repository
        .applyToDocument(const ProjectDocument(nextId: 2))
        .procedureSessions
        .single;
    expect(stored['participantId'], isNull);
    expect(stored['assistantId'], isNull);
    expect((await repository.list()).single.participantId, isNull);
  });

  test('deleting a person clears every active procedure reference', () async {
    const document = ProjectDocument(
      nextId: 30,
      humans: <Map<String, Object?>>[
        <String, Object?>{
          'id': 10,
          'name': 'Анна',
          'shortName': 'Анна',
          'seminarRole': 'participant',
          'procedureRoles': ['client', 'companion'],
          'deleted': false,
        },
      ],
      procedureSessions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'dayId': 1,
          'participantId': 10,
          'assistantId': 10,
          'startTime': '09:00',
          'procedureKindId': 100,
          'deleted': false,
        },
        <String, Object?>{
          'id': 2,
          'dayId': 1,
          'participantId': 10,
          'startTime': '10:00',
          'procedureKindId': 100,
          'deleted': true,
        },
      ],
    );
    final allocator = ProjectDocumentIdAllocator(nextId: 30, onChanged: () {});
    final humans = ProjectDocumentHumansRepository(
      initialDocument: document,
      idAllocator: allocator,
      onChanged: () {},
    );
    final sessions = ProjectDocumentProcedureSessionsRepository(
      initialDocument: document,
      idAllocator: allocator,
      onChanged: () {},
    );
    final useCase = DeleteParticipantUseCase(
      ProjectDocumentParticipantsRepository(humansRepository: humans),
      humansRepository: humans,
      procedureSessionsRepository: sessions,
    );

    expect(await useCase.countReferences('10'), 1);
    await useCase.execute('10');

    expect(await humans.list(), isEmpty);
    final active = (await sessions.list()).single;
    expect(active.participantId, isNull);
    expect(active.assistantId, isNull);
    final persisted = sessions.applyToDocument(document).procedureSessions;
    expect(persisted.last['clientId'], 10);
  });
}
