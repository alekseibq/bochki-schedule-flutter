import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/named_directory/named_directory_entry.dart';
import '../../domain/named_directory/named_directory_repository.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'named_directory_entry_dto.dart';

typedef ProjectDocumentCollectionWriter = ProjectDocument Function(
  ProjectDocument document,
  List<Map<String, Object?>> entries,
);

class ProjectDocumentNamedDirectoryRepository<T extends NamedDirectoryEntry>
    with DirtyTrackingProjectDocumentSyncPart
    implements NamedDirectoryRepository<T>, ProjectDocumentSyncPart {
  ProjectDocumentNamedDirectoryRepository({
    required List<Map<String, Object?>> initialEntries,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
    required NamedDirectoryEntryFactory<T> entryFactory,
    required ProjectDocumentCollectionWriter collectionWriter,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _entryFactory = entryFactory,
        _collectionWriter = collectionWriter,
        _entries = initialEntries
            .map(NamedDirectoryEntryDto.fromJson)
            .toList(growable: true);

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final NamedDirectoryEntryFactory<T> _entryFactory;
  final ProjectDocumentCollectionWriter _collectionWriter;
  final List<NamedDirectoryEntryDto> _entries;

  @override
  Future<List<T>> list() async {
    return _entries
        .where((entry) => !entry.deleted)
        .map((entry) => entry.toDomain(_entryFactory))
        .toList(growable: false);
  }

  @override
  Future<T> create({
    required String name,
  }) async {
    final createdEntry = _entryFactory(
      id: _idAllocator.nextId().toString(),
      name: name,
    );
    _entries.add(
      NamedDirectoryEntryDto.fromDomain(createdEntry, deleted: false),
    );
    _markRepositoryChanged();
    return createdEntry;
  }

  @override
  Future<T> update(T entry) async {
    final entryId = int.parse(entry.id);
    final index = _entries.indexWhere((candidate) => candidate.id == entryId);
    if (index != -1) {
      final current = _entries[index];
      if (current.name != entry.name || current.deleted) {
        _entries[index] = current.copyWith(
          name: entry.name,
          deleted: false,
        );
        _markRepositoryChanged();
      }
    }

    return entry;
  }

  @override
  Future<void> delete(String entryId) async {
    final parsedId = int.parse(entryId);
    final index = _entries.indexWhere((candidate) => candidate.id == parsedId);
    if (index == -1 || _entries[index].deleted) {
      return;
    }

    _entries[index] = _entries[index].copyWith(deleted: true);
    _markRepositoryChanged();
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return _collectionWriter(
      document,
      _sortedEntryJson(_entries),
    );
  }

  List<Map<String, Object?>> _sortedEntryJson(
    List<NamedDirectoryEntryDto> entries,
  ) {
    final sortedEntries = [...entries]..sort(
        (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
            .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
      );
    return sortedEntries
        .map((entry) => entry.toJson())
        .toList(growable: false);
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }
}
