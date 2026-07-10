import '../../domain/assistants/assistant.dart';
import '../directory/named_directory_dialog.dart';
import '../directory/named_directory_dialog_config.dart';

import 'assistants_view_model.dart';

class AssistantsDialog extends NamedDirectoryDialog<Assistant> {
  const AssistantsDialog({
    required AssistantsViewModel viewModel,
    super.key,
  }) : super(
          viewModel: viewModel,
          config: _config,
        );

  static const NamedDirectoryDialogConfig<Assistant> _config =
      NamedDirectoryDialogConfig<Assistant>(
    dialogKey: 'assistants_directory_dialog',
    tableDividerKey: 'assistants_table_divider',
    entryKeyPrefix: 'assistant',
    dialogTitle: 'Список ассистентов',
    sectionTitleBuilder: _sectionTitle,
    inlineFieldHintText: 'Введите имя ассистента',
    addRowLabel: 'Добавить новую запись',
    deleteConfirmationTitle: 'Удалить ассистента?',
    deleteConfirmationMessage: _deleteConfirmationMessage,
    columns: [
      DirectoryColumnSpec<Assistant>(
        id: 'name',
        label: 'Имя',
        cellText: _cellText,
      ),
    ],
    rowActions: [
      DirectoryRowActionSpec<Assistant>(
        id: 'edit',
        label: 'Edit',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _editAction,
      ),
      DirectoryRowActionSpec<Assistant>(
        id: 'delete',
        label: 'Delete',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _deleteAction,
      ),
    ],
  );

  static String _sectionTitle(int count) => 'Ассистенты ($count)';

  static String _cellText(Assistant assistant) => assistant.name;

  static String _deleteConfirmationMessage(Assistant assistant) {
    return 'Ассистент "${assistant.name}" будет скрыт из списка.';
  }

  static Future<void> _editAction(
    NamedDirectoryDialogController<Assistant> controller,
    Assistant assistant,
  ) async {
    controller.beginEdit(assistant.id);
  }

  static Future<void> _deleteAction(
    NamedDirectoryDialogController<Assistant> controller,
    Assistant assistant,
  ) {
    return controller.deleteEntry(assistant);
  }
}
