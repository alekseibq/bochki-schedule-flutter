import '../named_directory/create_named_directory_entry_use_case.dart';

import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class CreateAssistantUseCase {
  CreateAssistantUseCase(AssistantsRepository repository)
      : _repository = repository,
        _delegate = CreateNamedDirectoryEntryUseCase<Assistant>(
          repository,
          emptyNameMessage: 'Введите имя ассистента.',
          duplicateNameMessage: 'Ассистент с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final AssistantsRepository _repository;
  final CreateNamedDirectoryEntryUseCase<Assistant> _delegate;

  Future<Assistant> execute(
    String rawName, {
    String? rawShortName,
  }) async {
    final assistant = await _delegate.execute(rawName);
    if (rawShortName == null) {
      return assistant;
    }

    return _repository.update(
      assistant.copyWith(shortName: rawShortName),
    );
  }

  static AssistantsValidationException _validationException(String message) {
    return AssistantsValidationException(message);
  }
}
