import 'package:bochki_schedule_app/src/data/procedure_sessions/project_document_procedure_sessions_repository.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        'participantId': 10,
        'startTime': '09:00',
        'procedureKindId': 100,
        'assistantId': 20,
        'deleted': true,
      },
      <String, Object?>{
        'id': 3,
        'dayId': 2,
        'participantId': 11,
        'startTime': '11:00',
        'procedureKindId': 101,
        'deleted': false,
      },
    ]);
    expect(changeNotifications, 4);
  });
}
