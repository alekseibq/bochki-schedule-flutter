import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_sessions_repository.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'procedure_session_dto.dart';

final class ProjectDocumentProcedureSessionsRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements ProcedureSessionsRepository, ProjectDocumentSyncPart {
  ProjectDocumentProcedureSessionsRepository({
    required ProjectDocument initialDocument,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _entries = initialDocument.procedureSessions
            .map(ProcedureSessionDto.fromJson)
            .toList(growable: true);

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final List<ProcedureSessionDto> _entries;

  @override
  Future<List<ProcedureSessionRaw>> list() async {
    return _entries
        .where((entry) => !entry.deleted)
        .map((entry) => entry.toDomain())
        .toList(growable: false);
  }

  @override
  Future<ProcedureSessionRaw> create(
      ProcedureSessionRaw procedureSession) async {
    final createdProcedureSession = procedureSession.copyWith(
      id: _idAllocator.nextId().toString(),
    );
    _entries.add(
      ProcedureSessionDto.fromDomain(
        createdProcedureSession,
        deleted: false,
      ),
    );
    _markRepositoryChanged();
    return createdProcedureSession;
  }

  @override
  Future<ProcedureSessionRaw> update(
      ProcedureSessionRaw procedureSession) async {
    final entryId = int.parse(procedureSession.id);
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) {
      return procedureSession;
    }

    final current = _entries[index];
    final next =
        ProcedureSessionDto.fromDomain(procedureSession, deleted: false);
    if (current.toJson().toString() != next.toJson().toString() ||
        current.deleted) {
      _entries[index] = next;
      _markRepositoryChanged();
    }

    return procedureSession;
  }

  @override
  Future<void> delete(String procedureSessionId) async {
    final entryId = int.parse(procedureSessionId);
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
        ProcedureSessionDto.fromDomain(
          entry.toDomain(),
          deleted: entry.deleted,
        ),
    ]..sort((left, right) {
        final byDay = left.dayId.compareTo(right.dayId);
        if (byDay != 0) {
          return byDay;
        }

        final byStartTime = left.startTime.compareTo(right.startTime);
        if (byStartTime != 0) {
          return byStartTime;
        }

        final byProcedureKind =
            left.procedureKindId.compareTo(right.procedureKindId);
        if (byProcedureKind != 0) {
          return byProcedureKind;
        }

        return left.id.compareTo(right.id);
      });

    return document.copyWith(
      procedureSessions:
          sortedEntries.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }
}
