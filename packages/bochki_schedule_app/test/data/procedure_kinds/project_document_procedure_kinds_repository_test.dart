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
        'shortName': 'Бег',
        'capacity': 2,
        'clientBusyTime': 20,
        'deleted': true,
        'resourceBusyTime': 20,
      },
      <String, Object?>{
        'id': 1,
        'patternId': 'curated',
        'name': 'Бочка',
        'shortName': 'Бочка',
        'capacity': 6,
        'clientBusyTime': 30,
        'companionBusyTime': 10,
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
    expect(createdProcedureKind.resourceBusyTime, 20);
    expect(
      procedureKinds.map((procedureKind) => procedureKind.name),
      ['Бег дорожка'],
    );
    expect(exportedDocument.procedureKinds, [
      <String, Object?>{
        'id': 2,
        'patternId': 'single',
        'name': 'Бег дорожка',
        'shortName': 'Бег',
        'capacity': 2,
        'clientBusyTime': 20,
        'deleted': false,
        'resourceBusyTime': 20,
      },
      <String, Object?>{
        'id': 1,
        'patternId': 'curated',
        'name': 'Бочка',
        'shortName': 'Бочка',
        'capacity': 6,
        'clientBusyTime': 30,
        'companionBusyTime': 10,
        'deleted': true,
      },
    ]);
    expect(changeNotifications, 4);
  });

  test('normalizes short names for legacy active and deleted entries',
      () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentProcedureKindsRepository(
      initialDocument: const ProjectDocument(
        procedureKinds: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'patternId': 'curated',
            'name': ' Бочка ',
            'capacity': 6,
            'participantBusyTime': 30,
            'deleted': false,
          },
          <String, Object?>{
            'id': 2,
            'patternId': 'single',
            'name': 'Бег',
            'shortName': '   ',
            'capacity': 2,
            'participantBusyTime': 20,
            'deleted': true,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(nextId: 3, onChanged: () {}),
      onChanged: () => changeNotifications += 1,
    );

    expect(await repository.normalizeLegacyProcedureKinds(), isTrue);
    final document = repository.applyToDocument(ProjectDocument.initial());

    expect(changeNotifications, 1);
    expect(
        document.procedureKinds,
        containsAll([
          containsPair('shortName', 'Бочка'),
          containsPair('shortName', 'Бег'),
        ]));
    expect(
      document.procedureKinds
          .singleWhere((entry) => entry['id'] == 2)['deleted'],
      isTrue,
    );
  });

  test('reads a legacy grouped kind with derived leader busy time', () async {
    var changeNotifications = 0;
    final repository = ProjectDocumentProcedureKindsRepository(
      initialDocument: const ProjectDocument(
        procedureKinds: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'patternId': 'grouped',
            'name': 'Медитация',
            'shortName': 'Медитация',
            'capacity': 10,
            'clientBusyTime': 40,
            'resourceBusyTime': 40,
            'deleted': false,
          },
        ],
      ),
      idAllocator: ProjectDocumentIdAllocator(nextId: 2, onChanged: () {}),
      onChanged: () => changeNotifications += 1,
    );

    final procedureKind = (await repository.list()).single;

    expect(procedureKind.assistantBusyTime, 40);
    expect(await repository.normalizeLegacyProcedureKinds(), isFalse);
    expect(changeNotifications, 0);
  });
}
