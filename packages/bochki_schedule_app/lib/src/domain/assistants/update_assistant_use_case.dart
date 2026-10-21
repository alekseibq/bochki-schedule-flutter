import '../named_directory/named_directory_entry.dart';

import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class UpdateAssistantUseCase {
  UpdateAssistantUseCase(this._repository);

  final AssistantsRepository _repository;

  Future<Assistant> execute({
    required String assistantId,
    required String rawName,
  }) async {
    final normalizedId = Assistant.normalizeId(assistantId);
    if (normalizedId.isEmpty) {
      throw const AssistantsValidationException(
        'Идентификатор сопровождающего не должен быть пустым.',
      );
    }

    final assistants = await _repository.list();
    final current =
        assistants.where((entry) => entry.id == normalizedId).firstOrNull;
    if (current == null) {
      throw const AssistantsValidationException('Сопровождающий не найден.');
    }

    final name = Assistant.normalizeName(rawName);
    if (name.isEmpty) {
      throw const AssistantsValidationException('Введите имя сопровождающего.');
    }
    final sortKey = NamedDirectoryEntry.sortKeyForName(name);
    if (assistants.any((entry) =>
        entry.id != normalizedId &&
        NamedDirectoryEntry.sortKeyForName(entry.name) == sortKey)) {
      throw const AssistantsValidationException(
          'Сопровождающий с таким именем уже есть.');
    }

    return _repository.update(Assistant(
      id: normalizedId,
      name: name,
      shortName: name,
    ));
  }
}
