import '../named_directory/update_named_directory_entry_use_case.dart';

import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class UpdateAssistantUseCase {
  UpdateAssistantUseCase(AssistantsRepository repository)
      : _delegate = UpdateNamedDirectoryEntryUseCase<Assistant>(
          repository,
          entryFactory: _entryFactory,
          emptyIdMessage: 'Идентификатор ассистента не должен быть пустым.',
          emptyNameMessage: 'Введите имя ассистента.',
          duplicateNameMessage: 'Ассистент с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final UpdateNamedDirectoryEntryUseCase<Assistant> _delegate;

  Future<Assistant> execute({
    required String assistantId,
    required String rawName,
  }) {
    return _delegate.execute(
      entryId: assistantId,
      rawName: rawName,
    );
  }

  static Assistant _entryFactory({
    required String id,
    required String name,
  }) {
    return Assistant(
      id: id,
      name: name,
    );
  }

  static AssistantsValidationException _validationException(String message) {
    return AssistantsValidationException(message);
  }
}
