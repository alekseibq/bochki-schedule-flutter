import '../../domain/assistants/create_assistant_use_case.dart';
import '../../domain/assistants/delete_assistant_use_case.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/update_assistant_use_case.dart';
import '../directory/named_directory_view_model.dart';

final class AssistantsViewModel extends NamedDirectoryViewModel<Assistant> {
  AssistantsViewModel({
    required ListAssistantsUseCase listAssistantsUseCase,
    required CreateAssistantUseCase createAssistantUseCase,
    required UpdateAssistantUseCase updateAssistantUseCase,
    required DeleteAssistantUseCase deleteAssistantUseCase,
  }) : super(
          loadEntries: listAssistantsUseCase.execute,
          createEntry: createAssistantUseCase.execute,
          updateEntry: ({
            required String entryId,
            required String rawName,
          }) {
            return updateAssistantUseCase.execute(
              assistantId: entryId,
              rawName: rawName,
            );
          },
          deleteEntry: deleteAssistantUseCase.execute,
          loadErrorMessageText: 'Не удалось загрузить ассистентов.',
          saveErrorMessageText: 'Не удалось сохранить изменения.',
          deleteErrorMessageText: 'Не удалось удалить ассистента.',
        );

  List<Assistant> get assistants => entries;

  Future<void> loadAssistants() {
    return loadEntries();
  }

  Future<bool> createAssistant(String rawName) {
    return createEntry(rawName);
  }

  Future<bool> updateAssistant({
    required String assistantId,
    required String rawName,
  }) {
    return updateEntry(
      entryId: assistantId,
      rawName: rawName,
    );
  }

  Future<bool> deleteAssistant(String assistantId) {
    return deleteEntry(assistantId);
  }
}
