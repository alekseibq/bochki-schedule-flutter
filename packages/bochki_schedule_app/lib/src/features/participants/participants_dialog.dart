import '../../domain/participants/participant.dart';
import 'participants_dialog_config.dart';

import 'participants_content.dart';
import 'participants_view_model.dart';

class ParticipantsDialog extends ParticipantsContent {
  const ParticipantsDialog({
    required ParticipantsViewModel viewModel,
    super.key,
  }) : super(
          viewModel: viewModel,
          config: participantConfig,
        );

  static const ParticipantsDialogConfig<Participant> participantConfig =
      ParticipantsDialogConfig<Participant>(
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
      ParticipantsColumnSpec<Participant>(
        id: 'name',
        label: 'Имя',
        cellText: _cellText,
      ),
    ],
    rowActions: [
      ParticipantsRowActionSpec<Participant>(
        id: 'edit',
        label: 'Edit',
        placement: ParticipantsRowActionPlacement.contextMenu,
        onInvoke: _editAction,
      ),
      ParticipantsRowActionSpec<Participant>(
        id: 'delete',
        label: 'Delete',
        placement: ParticipantsRowActionPlacement.contextMenu,
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
    ParticipantsDialogController<Participant> controller,
    Participant participant,
  ) async {
    controller.beginEdit(participant.id);
  }

  static Future<void> _deleteAction(
    ParticipantsDialogController<Participant> controller,
    Participant participant,
  ) {
    return controller.deleteEntry(participant);
  }
}
