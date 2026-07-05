import '../../domain/trainers/trainer.dart';
import '../directory/named_directory_dialog.dart';
import '../directory/named_directory_dialog_config.dart';

import 'trainers_view_model.dart';

class TrainersDialog extends NamedDirectoryDialog<Trainer> {
  TrainersDialog({
    required TrainersViewModel viewModel,
    super.key,
  }) : super(
          viewModel: viewModel,
          config: _config,
        );

  static const NamedDirectoryDialogConfig<Trainer> _config =
      NamedDirectoryDialogConfig<Trainer>(
    dialogKey: 'trainers_directory_dialog',
    tableDividerKey: 'trainers_table_divider',
    entryKeyPrefix: 'trainer',
    dialogTitle: 'Список тренеров',
    sectionTitleBuilder: _sectionTitle,
    inlineFieldHintText: 'Введите имя тренера',
    addRowLabel: 'Добавить новую запись',
    deleteConfirmationTitle: 'Удалить тренера?',
    deleteConfirmationMessage: _deleteConfirmationMessage,
    columns: [
      DirectoryColumnSpec<Trainer>(
        id: 'name',
        label: 'Имя',
        cellText: _cellText,
      ),
    ],
    rowActions: [
      DirectoryRowActionSpec<Trainer>(
        id: 'edit',
        label: 'Edit',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _editAction,
      ),
      DirectoryRowActionSpec<Trainer>(
        id: 'delete',
        label: 'Delete',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _deleteAction,
      ),
    ],
  );

  static String _sectionTitle(int count) => 'Тренеры ($count)';

  static String _cellText(Trainer trainer) => trainer.name;

  static String _deleteConfirmationMessage(Trainer trainer) {
    return 'Тренер "${trainer.name}" будет скрыт из списка.';
  }

  static Future<void> _editAction(
    NamedDirectoryDialogController<Trainer> controller,
    Trainer trainer,
  ) async {
    controller.beginEdit(trainer.id);
  }

  static Future<void> _deleteAction(
    NamedDirectoryDialogController<Trainer> controller,
    Trainer trainer,
  ) {
    return controller.deleteEntry(trainer);
  }
}
