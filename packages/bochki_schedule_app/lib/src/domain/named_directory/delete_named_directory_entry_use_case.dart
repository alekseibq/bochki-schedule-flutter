import 'named_directory_entry.dart';
import 'named_directory_repository.dart';
import 'named_directory_validation_exception.dart';

final class DeleteNamedDirectoryEntryUseCase<T extends NamedDirectoryEntry> {
  const DeleteNamedDirectoryEntryUseCase(
    this._repository, {
    required this.emptyIdMessage,
    required this.exceptionFactory,
  });

  final NamedDirectoryRepository<T> _repository;
  final String emptyIdMessage;
  final NamedDirectoryExceptionFactory exceptionFactory;

  Future<void> execute(String entryId) async {
    final normalizedId = NamedDirectoryEntry.normalizeId(entryId);
    if (normalizedId.isEmpty) {
      throw exceptionFactory(emptyIdMessage);
    }

    await _repository.delete(normalizedId);
  }
}
