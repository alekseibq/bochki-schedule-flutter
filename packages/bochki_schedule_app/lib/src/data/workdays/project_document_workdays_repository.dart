import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/workdays/workday.dart';
import '../../domain/workdays/workdays_repository.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'workday_dto.dart';

final class ProjectDocumentWorkdaysRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements WorkdaysRepository, ProjectDocumentSyncPart {
  ProjectDocumentWorkdaysRepository({
    required ProjectDocument initialDocument,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _entries = initialDocument.workdays
            .map(WorkdayDto.fromJson)
            .toList(growable: true);

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final List<WorkdayDto> _entries;

  @override
  Future<List<Workday>> list() async {
    return _entries
        .where((entry) => !entry.deleted)
        .map((entry) => entry.toDomain())
        .toList(growable: false);
  }

  @override
  Future<Workday> create(Workday workday) async {
    final createdWorkday = workday.copyWith(
      id: _idAllocator.nextId().toString(),
    );
    _entries.add(
      WorkdayDto.fromDomain(
        createdWorkday,
        deleted: false,
      ),
    );
    _markRepositoryChanged();
    return createdWorkday;
  }

  @override
  Future<Workday> update(Workday workday) async {
    final entryId = int.parse(workday.id);
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) {
      return workday;
    }

    final current = _entries[index];
    final next = WorkdayDto.fromDomain(workday, deleted: false);
    if (current.toJson().toString() != next.toJson().toString() ||
        current.deleted) {
      _entries[index] = next;
      _markRepositoryChanged();
    }

    return workday;
  }

  @override
  Future<void> delete(String workdayId) async {
    final entryId = int.parse(workdayId);
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1 || _entries[index].deleted) {
      return;
    }

    _entries[index] = _entries[index].copyWith(deleted: true);
    _markRepositoryChanged();
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    final sortedEntries = [
      for (final entry in _entries)
        WorkdayDto.fromDomain(
          entry.toDomain(),
          deleted: entry.deleted,
        ),
    ]..sort((left, right) {
        final leftDate = left.toDomain().calendarDate;
        final rightDate = right.toDomain().calendarDate;
        final dateComparison = leftDate.compareTo(rightDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return Workday.sortKeyForName(left.name)
            .compareTo(Workday.sortKeyForName(right.name));
      });

    return document.copyWith(
      workdays:
          sortedEntries.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }
}
