import 'named_directory_entry.dart';
import 'named_directory_repository.dart';

final class ListNamedDirectoryEntriesUseCase<T extends NamedDirectoryEntry> {
  const ListNamedDirectoryEntriesUseCase(this._repository);

  final NamedDirectoryRepository<T> _repository;

  Future<List<T>> execute() async {
    final entries = await _repository.list();
    entries.sort(
      (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
          .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
    );
    return List<T>.unmodifiable(entries);
  }
}
