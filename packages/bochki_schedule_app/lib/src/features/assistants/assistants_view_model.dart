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
            required String fieldId,
          }) {
            return updateAssistantUseCase.execute(
              assistantId: entryId,
              rawName: fieldId == 'name' ? rawName : null,
              rawShortName: fieldId == 'shortName' ? rawName : null,
            );
          },
          deleteEntry: deleteAssistantUseCase.execute,
          countReferences: deleteAssistantUseCase.countReferences,
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
    String fieldId = 'name',
  }) {
    return updateEntry(
      entryId: assistantId,
      rawName: rawName,
      fieldId: fieldId,
    );
  }

  Future<bool> deleteAssistant(String assistantId) {
    return deleteEntry(assistantId);
  }
}
