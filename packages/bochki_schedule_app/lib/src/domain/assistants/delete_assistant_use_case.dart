import '../named_directory/delete_named_directory_entry_use_case.dart';

import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class DeleteAssistantUseCase {
  DeleteAssistantUseCase(AssistantsRepository repository)
      : _delegate = DeleteNamedDirectoryEntryUseCase<Assistant>(
          repository,
          emptyIdMessage: 'Идентификатор ассистента не должен быть пустым.',
          exceptionFactory: _validationException,
        );

  final DeleteNamedDirectoryEntryUseCase<Assistant> _delegate;

  Future<void> execute(String assistantId) {
    return _delegate.execute(assistantId);
  }

  static AssistantsValidationException _validationException(String message) {
    return AssistantsValidationException(message);
  }
}
