import '../../domain/participants/participant.dart';
import '../directory/named_directory_dialog.dart';
import '../directory/named_directory_dialog_config.dart';

import 'participants_view_model.dart';

class ParticipantsDialog extends NamedDirectoryDialog<Participant> {
  ParticipantsDialog({
    required ParticipantsViewModel viewModel,
    super.key,
  }) : super(
          viewModel: viewModel,
          config: _config,
        );

  static const NamedDirectoryDialogConfig<Participant> _config =
      NamedDirectoryDialogConfig<Participant>(
    dialogKey: 'participants_directory_dialog',
    tableDividerKey: 'participants_table_divider',
    entryKeyPrefix: 'participant',
    dialogTitle: 'Список участников',
    sectionTitleBuilder: _sectionTitle,
    inlineFieldHintText: 'Введите имя участника',
    addRowLabel: 'Добавить новую запись',
    deleteConfirmationTitle: 'Удалить участника?',
    deleteConfirmationMessage: _deleteConfirmationMessage,
    columns: [
      DirectoryColumnSpec<Participant>(
        id: 'name',
        label: 'Имя',
        cellText: _cellText,
      ),
    ],
    rowActions: [
      DirectoryRowActionSpec<Participant>(
        id: 'edit',
        label: 'Edit',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _editAction,
      ),
      DirectoryRowActionSpec<Participant>(
        id: 'delete',
        label: 'Delete',
        placement: DirectoryRowActionPlacement.contextMenu,
        onInvoke: _deleteAction,
      ),
    ],
  );

  static String _sectionTitle(int count) => 'Участники ($count)';

  static String _cellText(Participant participant) => participant.name;

  static String _deleteConfirmationMessage(Participant participant) {
    return 'Участник "${participant.name}" будет скрыт из списка.';
  }

  static Future<void> _editAction(
    NamedDirectoryDialogController<Participant> controller,
    Participant participant,
  ) async {
    controller.beginEdit(participant.id);
  }

  static Future<void> _deleteAction(
    NamedDirectoryDialogController<Participant> controller,
    Participant participant,
  ) {
    return controller.deleteEntry(participant);
  }
}
