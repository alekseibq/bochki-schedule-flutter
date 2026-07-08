import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_kinds/procedure_kinds_repository.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'procedure_kind_dto.dart';

final class ProjectDocumentProcedureKindsRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements ProcedureKindsRepository, ProjectDocumentSyncPart {
  ProjectDocumentProcedureKindsRepository({
    required ProjectDocument initialDocument,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _entries = initialDocument.procedureKinds
            .map(ProcedureKindDto.fromJson)
            .toList(growable: true);

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final List<ProcedureKindDto> _entries;

  @override
  Future<List<ProcedureKind>> list() async {
    return _entries
        .where((entry) => !entry.deleted)
        .map((entry) => entry.toDomain())
        .toList(growable: false);
  }

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) async {
    final createdProcedureKind = procedureKind
        .copyWith(
          id: _idAllocator.nextId().toString(),
        )
        .sanitizedForPersistence();
    _entries.add(
      ProcedureKindDto.fromDomain(
        createdProcedureKind,
        deleted: false,
      ),
    );
    _markRepositoryChanged();
    return createdProcedureKind;
  }

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) async {
    final entryId = int.parse(procedureKind.id);
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) {
      return procedureKind.sanitizedForPersistence();
    }

    final updatedProcedureKind = procedureKind.sanitizedForPersistence();
    final current = _entries[index];
    final next =
        ProcedureKindDto.fromDomain(updatedProcedureKind, deleted: false);
    if (current.toJson().toString() != next.toJson().toString() ||
        current.deleted) {
      _entries[index] = next;
      _markRepositoryChanged();
    }

    return updatedProcedureKind;
  }

  @override
  Future<void> delete(String procedureKindId) async {
    final entryId = int.parse(procedureKindId);
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
        ProcedureKindDto.fromDomain(
          entry.toDomain(),
          deleted: entry.deleted,
        ),
    ]..sort(
        (left, right) => ProcedureKind.sortKeyForName(left.name)
            .compareTo(ProcedureKind.sortKeyForName(right.name)),
      );
    return document.copyWith(
      procedureKinds: sortedEntries.map((entry) => entry.toJson()).toList(
            growable: false,
          ),
    );
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }
}
