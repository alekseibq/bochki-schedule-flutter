import 'package:bochki_schedule_app/src/data/project_document/project_document_id_allocator.dart';
import 'package:bochki_schedule_app/src/data/workdays/project_document_workdays_repository.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create update and delete persist workdays', () async {
    var changeNotifications = 0;
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: 2,
      onChanged: () {
        changeNotifications += 1;
      },
    );
    final repository = ProjectDocumentWorkdaysRepository(
      initialDocument: const ProjectDocument(
        nextId: 2,
        workdays: <Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'name': 'День 1',
            'calendarDate': '2026-07-11',
            'deleted': false,
          },
        ],
      ),
      idAllocator: idAllocator,
      onChanged: () {
        changeNotifications += 1;
      },
    );

    final createdWorkday = await repository.create(
      Workday(
        id: 'draft',
        name: 'День 2',
        calendarDate: DateTime(2026, 7, 12),
      ),
    );
    await repository.update(
      createdWorkday.copyWith(
        name: 'День 22',
        calendarDate: DateTime(2026, 7, 15),
      ),
    );
    await repository.delete('1');

    final workdays = await repository.list();
    final exportedDocument =
        repository.applyToDocument(const ProjectDocument(nextId: 3));

    expect(
      workdays.map((workday) => workday.name),
      ['День 22'],
    );
    expect(exportedDocument.workdays, [
      <String, Object?>{
        'id': 1,
        'name': 'День 1',
        'calendarDate': '2026-07-11',
        'deleted': true,
      },
      <String, Object?>{
        'id': 2,
        'name': 'День 22',
        'calendarDate': '2026-07-15',
        'deleted': false,
      },
    ]);
    expect(changeNotifications, 4);
  });
}
