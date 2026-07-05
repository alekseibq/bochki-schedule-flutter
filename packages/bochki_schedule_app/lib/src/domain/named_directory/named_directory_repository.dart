import 'named_directory_entry.dart';

abstract interface class NamedDirectoryRepository<
    T extends NamedDirectoryEntry> {
  Future<List<T>> list();

  Future<T> create({
    required String name,
  });

  Future<T> update(T entry);

  Future<void> delete(String entryId);
}
