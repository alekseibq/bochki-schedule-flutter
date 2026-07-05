import 'named_directory_entry.dart';
import 'named_directory_repository.dart';
import 'named_directory_validation_exception.dart';

final class CreateNamedDirectoryEntryUseCase<T extends NamedDirectoryEntry> {
  const CreateNamedDirectoryEntryUseCase(
    this._repository, {
    required this.emptyNameMessage,
    required this.duplicateNameMessage,
    required this.exceptionFactory,
  });

  final NamedDirectoryRepository<T> _repository;
  final String emptyNameMessage;
  final String duplicateNameMessage;
  final NamedDirectoryExceptionFactory exceptionFactory;

  Future<T> execute(String rawName) async {
    final normalizedName = NamedDirectoryEntry.normalizeName(rawName);
    if (normalizedName.isEmpty) {
      throw exceptionFactory(emptyNameMessage);
    }

    final entries = await _repository.list();
    final normalizedCandidate =
        NamedDirectoryEntry.sortKeyForName(normalizedName);
    final hasDuplicate = entries.any(
      (entry) =>
          NamedDirectoryEntry.sortKeyForName(entry.name) == normalizedCandidate,
    );
    if (hasDuplicate) {
      throw exceptionFactory(duplicateNameMessage);
    }

    return _repository.create(name: normalizedName);
  }
}
