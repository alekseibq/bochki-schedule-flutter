import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/create_assistant_use_case.dart';
import '../../domain/assistants/delete_assistant_use_case.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import '../../domain/assistants/update_assistant_use_case.dart';

/// Commands used exclusively by the assistants UI.
abstract interface class AssistantsOperations {
  Future<List<Assistant>> list();
  Future<Assistant> create(String name);
  Future<Assistant> update(String id, String name);
  Future<int> countReferences(String id);
  Future<void> delete(String id);
}

final class UseCaseAssistantsOperations implements AssistantsOperations {
  const UseCaseAssistantsOperations({
    required ListAssistantsUseCase listAssistantsUseCase,
    required CreateAssistantUseCase createAssistantUseCase,
    required UpdateAssistantUseCase updateAssistantUseCase,
    required DeleteAssistantUseCase deleteAssistantUseCase,
  })  : _list = listAssistantsUseCase,
        _create = createAssistantUseCase,
        _update = updateAssistantUseCase,
        _delete = deleteAssistantUseCase;

  final ListAssistantsUseCase _list;
  final CreateAssistantUseCase _create;
  final UpdateAssistantUseCase _update;
  final DeleteAssistantUseCase _delete;

  @override
  Future<List<Assistant>> list() => _list.execute();
  @override
  Future<Assistant> create(String name) => _create.execute(name);
  @override
  Future<Assistant> update(String id, String name) =>
      _update.execute(assistantId: id, rawName: name);
  @override
  Future<int> countReferences(String id) => _delete.countReferences(id);
  @override
  Future<void> delete(String id) => _delete.execute(id);
}
