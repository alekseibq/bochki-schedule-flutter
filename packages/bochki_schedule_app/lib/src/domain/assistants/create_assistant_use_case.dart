import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class CreateAssistantUseCase {
  CreateAssistantUseCase(this._repository);
  final AssistantsRepository _repository;

  Future<Assistant> execute(String rawName) async {
    final name = Assistant.normalizeName(rawName);
    if (name.isEmpty) {
      throw const AssistantsValidationException('Введите имя сопровождающего.');
    }
    final assistants = await _repository.list();
    final key = Assistant.sortKeyForName(name);
    if (assistants
        .any((entry) => Assistant.sortKeyForName(entry.name) == key)) {
      throw const AssistantsValidationException(
          'Сопровождающий с таким именем уже есть.');
    }
    return _repository.create(name: name);
  }
}
