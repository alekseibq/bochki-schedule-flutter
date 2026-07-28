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
        cellText: _nameCellText,
      ),
      DirectoryColumnSpec<Assistant>(
        id: 'shortName',
        label: 'Краткое имя',
        cellText: _shortNameCellText,
        editValue: _shortNameCellText,
      ),
    ],
    showColumnHeaders: true,
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

  static String _nameCellText(Assistant assistant) => assistant.name;

  static String _shortNameCellText(Assistant assistant) {
    return assistant.shortName.trim() == assistant.name
        ? ''
        : assistant.shortName;
  }

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
