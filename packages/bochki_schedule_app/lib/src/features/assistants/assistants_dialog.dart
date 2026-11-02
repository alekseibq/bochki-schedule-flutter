import '../../domain/assistants/assistant.dart';
import 'assistants_dialog_config.dart';

import 'assistants_content.dart';
import 'assistants_view_model.dart';

class AssistantsDialog extends AssistantsContent {
  const AssistantsDialog({
    required AssistantsViewModel viewModel,
    super.key,
  }) : super(
          viewModel: viewModel,
          config: assistantConfig,
        );

  static const AssistantsDialogConfig<Assistant> assistantConfig =
      AssistantsDialogConfig<Assistant>(
    dialogKey: 'assistants_directory_dialog',
    tableDividerKey: 'assistants_table_divider',
    entryKeyPrefix: 'assistant',
    dialogTitle: 'Список сопровождающих',
    sectionTitleBuilder: _sectionTitle,
    inlineFieldHintText: 'Введите имя сопровождающего',
    addRowLabel: 'Добавить новую запись',
    deleteConfirmationTitle: 'Удалить сопровождающего?',
    deleteConfirmationMessage: _deleteConfirmationMessage,
    columns: [
      AssistantsColumnSpec<Assistant>(
        id: 'name',
        label: 'Имя',
        cellText: _nameCellText,
      ),
    ],
    showColumnHeaders: true,
    rowActions: [
      AssistantsRowActionSpec<Assistant>(
        id: 'edit',
        label: 'Edit',
        placement: AssistantsRowActionPlacement.contextMenu,
        onInvoke: _editAction,
      ),
      AssistantsRowActionSpec<Assistant>(
        id: 'delete',
        label: 'Delete',
        placement: AssistantsRowActionPlacement.contextMenu,
        onInvoke: _deleteAction,
      ),
    ],
  );

  static String _sectionTitle(int count) => 'Сопровождающие ($count)';

  static String _nameCellText(Assistant assistant) => assistant.name;

  static String _deleteConfirmationMessage(Assistant assistant) {
    return 'Сопровождающий "${assistant.name}" будет скрыт из списка.';
  }

  static Future<void> _editAction(
    AssistantsDialogController<Assistant> controller,
    Assistant assistant,
  ) async {
    controller.beginEdit(assistant.id);
  }

  static Future<void> _deleteAction(
    AssistantsDialogController<Assistant> controller,
    Assistant assistant,
  ) {
    return controller.deleteEntry(assistant);
  }
}
