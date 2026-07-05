import 'named_directory_entry.dart';
import 'named_directory_repository.dart';
import 'named_directory_validation_exception.dart';

typedef NamedDirectoryEntryFactory<T extends NamedDirectoryEntry> = T Function({
  required String id,
  required String name,
});

final class UpdateNamedDirectoryEntryUseCase<T extends NamedDirectoryEntry> {
  const UpdateNamedDirectoryEntryUseCase(
    this._repository, {
    required this.entryFactory,
    required this.emptyIdMessage,
    required this.emptyNameMessage,
    required this.duplicateNameMessage,
    required this.exceptionFactory,
  });

  final NamedDirectoryRepository<T> _repository;
  final NamedDirectoryEntryFactory<T> entryFactory;
  final String emptyIdMessage;
  final String emptyNameMessage;
  final String duplicateNameMessage;
  final NamedDirectoryExceptionFactory exceptionFactory;

  Future<T> execute({
    required String entryId,
    required String rawName,
  }) async {
    final normalizedId = NamedDirectoryEntry.normalizeId(entryId);
    if (normalizedId.isEmpty) {
      throw exceptionFactory(emptyIdMessage);
    }

    final normalizedName = NamedDirectoryEntry.normalizeName(rawName);
    if (normalizedName.isEmpty) {
      throw exceptionFactory(emptyNameMessage);
    }

    final entries = await _repository.list();
    final normalizedCandidate =
        NamedDirectoryEntry.sortKeyForName(normalizedName);
    final hasDuplicate = entries.any(
      (entry) =>
          entry.id != normalizedId &&
          NamedDirectoryEntry.sortKeyForName(entry.name) == normalizedCandidate,
    );
    if (hasDuplicate) {
      throw exceptionFactory(duplicateNameMessage);
    }

    return _repository.update(
      entryFactory(
        id: normalizedId,
        name: normalizedName,
      ),
    );
  }
}
