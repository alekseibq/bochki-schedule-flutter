import 'package:flutter/material.dart';

import '../../domain/named_directory/named_directory_entry.dart';

enum AssistantsRowActionPlacement {
  contextMenu,
  rowButton,
}

class AssistantsColumnSpec<T extends NamedDirectoryEntry> {
  const AssistantsColumnSpec({
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

abstract interface class AssistantsDialogController<
    T extends NamedDirectoryEntry> {
  BuildContext get context;
  T? findEntryById(String entryId);
  void beginEdit(String entryId);
  Future<void> deleteEntry(T entry);
}

typedef AssistantsRowActionHandler<T extends NamedDirectoryEntry> = Future<void>
    Function(
  AssistantsDialogController<T> controller,
  T entry,
);

class AssistantsRowActionSpec<T extends NamedDirectoryEntry> {
  const AssistantsRowActionSpec({
    required this.id,
    required this.label,
    required this.placement,
    required this.onInvoke,
    this.icon,
  });

  final String id;
  final String label;
  final AssistantsRowActionPlacement placement;
  final IconData? icon;
  final AssistantsRowActionHandler<T> onInvoke;
}

class AssistantsDialogConfig<T extends NamedDirectoryEntry> {
  const AssistantsDialogConfig({
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
  final List<AssistantsColumnSpec<T>> columns;
  final List<AssistantsRowActionSpec<T>> rowActions;
  final bool showColumnHeaders;
  final String okButtonText;
  final String retryButtonText;
}
