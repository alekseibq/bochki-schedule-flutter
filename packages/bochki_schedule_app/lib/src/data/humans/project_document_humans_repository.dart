import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/humans/human.dart';
import '../../domain/humans/humans_repository.dart';
import '../../domain/named_directory/named_directory_entry.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'human_dto.dart';

final class ProjectDocumentHumansRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements HumansRepository, ProjectDocumentSyncPart {
  ProjectDocumentHumansRepository({
    required ProjectDocument initialDocument,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _entries = initialDocument.humans
            .map(HumanDto.fromJson)
            .toList(growable: true),
        _needsShortNameMigration = initialDocument.humans.any(
          (human) => !human.containsKey('shortName'),
        ),
        _needsRoleMigration = initialDocument.humans.any(
          (human) => !human.containsKey('seminarRole') ||
              !human.containsKey('procedureRoles'),
        );

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final List<HumanDto> _entries;
  final bool _needsShortNameMigration;
  final bool _needsRoleMigration;

  Future<bool> normalizeLegacyHumans() async {
    if (!_needsShortNameMigration && !_needsRoleMigration) {
      return false;
    }
    _markRepositoryChanged();
    return true;
  }

  @Deprecated('Use normalizeLegacyHumans.')
  Future<bool> normalizeLegacyShortNames() => normalizeLegacyHumans();

  @override
  Future<List<Human>> list() async {
    return _entries
        .where((entry) => !entry.deleted)
        .map((entry) => entry.toDomain())
        .toList(growable: false);
  }

  @override
  Future<Human> create({
    required String name,
    required bool isParticipant,
    required bool isAssistant,
  }) async {
    _ensureNameIsUnique(name);
    final human = Human(
      id: _idAllocator.nextId().toString(),
      name: name,
      seminarRole: isAssistant ? SeminarRole.assistant : SeminarRole.participant,
      procedureRoles: isAssistant
          ? const [ProcedureRole.client, ProcedureRole.companion]
          : const [ProcedureRole.client],
    );
    _entries.add(HumanDto.fromDomain(human, deleted: false));
    _markRepositoryChanged();
    return human;
  }

  @override
  Future<Human> update(Human human) async {
    final humanId = int.parse(human.id);
    final index = _entries.indexWhere((candidate) => candidate.id == humanId);
    if (index != -1) {
      final current = _entries[index];
      _ensureNameIsUnique(human.name, exceptId: current.id);
      final shortName = human.name != current.name &&
              human.shortName == current.shortName &&
              current.shortName == current.name
          ? human.name
          : human.shortName;
      if (current.name != human.name ||
          current.shortName != shortName ||
          current.seminarRole != human.seminarRole ||
          current.procedureRoles.toString() != human.procedureRoles.toString() ||
          current.deleted) {
        _entries[index] = current.copyWith(
          name: human.name,
          shortName: shortName,
          seminarRole: human.seminarRole,
          procedureRoles: human.procedureRoles,
          deleted: false,
        );
        _markRepositoryChanged();
      }
    }

    return human;
  }

  @override
  Future<void> delete(String humanId) async {
    final parsedId = int.parse(humanId);
    final index = _entries.indexWhere((candidate) => candidate.id == parsedId);
    if (index == -1 || _entries[index].deleted) {
      return;
    }

    _entries[index] = _entries[index].copyWith(
      deleted: true,
    );
    _markRepositoryChanged();
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    final sortedEntries = [..._entries]..sort(
        (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
            .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
      );
    return document.copyWith(
      humans:
          sortedEntries.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }

  void _ensureNameIsUnique(String name, {int? exceptId}) {
    final key = NamedDirectoryEntry.sortKeyForName(name);
    final exists = _entries.any(
      (entry) =>
          !entry.deleted &&
          entry.id != exceptId &&
          NamedDirectoryEntry.sortKeyForName(entry.name) == key,
    );
    if (exists) {
      throw StateError('Человек с таким именем уже есть.');
    }
  }
}
