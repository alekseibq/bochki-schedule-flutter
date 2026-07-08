import 'package:bochki_schedule_app/src/data/procedure_kinds/project_document_procedure_kinds_repository.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository preserves hidden curated-only fields semantics', () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentProcedureKindsRepository(
      initialDocument: const ProjectDocument(
        nextId: 3,
        procedureKinds: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'patternId': 'curated',
            'name': 'Бочка',
            'capacity': 6,
            'participantBusyTime': 30,
            'assistantBusyTime': 10,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
            'patternId': 'single',
            'name': 'Бег',
            'capacity': 2,
            'participantBusyTime': 20,
            'assistantBusyTime': 15,
            'deleted': true,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(
        nextId: 3,
        onChanged: () {
          changeNotifications += 1;
        },
      ),
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final procedureKinds = await repository.list();
    final exportedDocument =
        repository.applyToDocument(ProjectDocument.initial());

    expect(procedureKinds, hasLength(1));
    expect(procedureKinds.single.assistantBusyTime, 10);
    expect(exportedDocument.procedureKinds, [
      <String, Object?>{
        'id': 2,
        'patternId': 'single',
        'name': 'Бег',
        'capacity': 2,
        'participantBusyTime': 20,
        'deleted': true,
      },
      <String, Object?>{
        'id': 1,
        'patternId': 'curated',
        'name': 'Бочка',
        'capacity': 6,
        'participantBusyTime': 30,
        'assistantBusyTime': 10,
        'deleted': false,
      },
    ]);
    expect(changeNotifications, 0);
  });

  test('create update and delete persist procedure kinds', () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 2,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final repository = ProjectDocumentProcedureKindsRepository(
      initialDocument: const ProjectDocument(
        nextId: 2,
        procedureKinds: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'patternId': 'curated',
            'name': 'Бочка',
            'capacity': 6,
            'participantBusyTime': 30,
            'assistantBusyTime': 10,
            'deleted': false,
          },
        ],
      ),
      idAllocator: idAllocator,
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final createdProcedureKind = await repository.create(
      ProcedureKind(
        id: 'draft',
        patternId: ProcedureKindPatterns.single.patternId,
        name: 'Бег',
        capacity: 2,
        participantBusyTime: 20,
        assistantBusyTime: 5,
      ),
    );
    await repository.update(
      createdProcedureKind.copyWith(name: 'Бег дорожка'),
    );
    await repository.delete('1');

    final procedureKinds = await repository.list();
    final exportedDocument =
        repository.applyToDocument(const ProjectDocument(nextId: 3));

    expect(createdProcedureKind.assistantBusyTime, isNull);
    expect(
      procedureKinds.map((procedureKind) => procedureKind.name),
      ['Бег дорожка'],
    );
    expect(exportedDocument.procedureKinds, [
      <String, Object?>{
        'id': 2,
        'patternId': 'single',
        'name': 'Бег дорожка',
        'capacity': 2,
        'participantBusyTime': 20,
        'deleted': false,
      },
      <String, Object?>{
        'id': 1,
        'patternId': 'curated',
        'name': 'Бочка',
        'capacity': 6,
        'participantBusyTime': 30,
        'assistantBusyTime': 10,
        'deleted': true,
      },
    ]);
    expect(changeNotifications, 4);
  });
}
