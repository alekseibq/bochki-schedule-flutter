import 'package:flutter/material.dart';

import '../../domain/named_directory/named_directory_entry.dart';

enum ParticipantsRowActionPlacement {
  contextMenu,
  rowButton,
}

class ParticipantsColumnSpec<T extends NamedDirectoryEntry> {
  const ParticipantsColumnSpec({
    required this.id,
    required this.label,
    required this.cellText,
    this.editValue,
    this.flex = 1,
  });

  final String id;
  final String label;
  final String Function(T entry) cellText;
  final String Function(T entry)? editValue;
  final int flex;
}

abstract interface class ParticipantsDialogController<
    T extends NamedDirectoryEntry> {
  BuildContext get context;
  T? findEntryById(String entryId);
  void beginEdit(String entryId);
  Future<void> deleteEntry(T entry);
}

typedef ParticipantsRowActionHandler<T extends NamedDirectoryEntry>
    = Future<void> Function(
  ParticipantsDialogController<T> controller,
  T entry,
);

class ParticipantsRowActionSpec<T extends NamedDirectoryEntry> {
  const ParticipantsRowActionSpec({
    required this.id,
    required this.label,
    required this.placement,
    required this.onInvoke,
    this.icon,
  });

  final String id;
  final String label;
  final ParticipantsRowActionPlacement placement;
  final IconData? icon;
  final ParticipantsRowActionHandler<T> onInvoke;
}

class ParticipantsDialogConfig<T extends NamedDirectoryEntry> {
  const ParticipantsDialogConfig({
    required this.dialogKey,
    required this.tableDividerKey,
    required this.entryKeyPrefix,
    required this.dialogTitle,
    required this.sectionTitleBuilder,
    required this.inlineFieldHintText,
    required this.addRowLabel,
    required this.deleteConfirmationTitle,
    required this.deleteConfirmationMessage,
    required this.columns,
    required this.rowActions,
    this.showColumnHeaders = false,
    this.okButtonText = 'Ok',
    this.retryButtonText = 'Повторить',
  });

  final String dialogKey;
  final String tableDividerKey;
  final String entryKeyPrefix;
  final String dialogTitle;
  final String Function(int count) sectionTitleBuilder;
  final String inlineFieldHintText;
  final String addRowLabel;
  final String deleteConfirmationTitle;
  final String Function(T entry) deleteConfirmationMessage;
  final List<ParticipantsColumnSpec<T>> columns;
  final List<ParticipantsRowActionSpec<T>> rowActions;
  final bool showColumnHeaders;
  final String okButtonText;
  final String retryButtonText;
}
