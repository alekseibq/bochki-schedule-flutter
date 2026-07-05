import 'package:flutter/material.dart';

import '../../domain/named_directory/named_directory_entry.dart';

enum DirectoryRowActionPlacement {
  contextMenu,
  rowButton,
}

class DirectoryColumnSpec<T extends NamedDirectoryEntry> {
  const DirectoryColumnSpec({
    required this.id,
    required this.label,
    required this.cellText,
    this.flex = 1,
  });

  final String id;
  final String label;
  final String Function(T entry) cellText;
  final int flex;
}

abstract interface class NamedDirectoryDialogController<
    T extends NamedDirectoryEntry> {
  BuildContext get context;
  T? findEntryById(String entryId);
  void beginEdit(String entryId);
  Future<void> deleteEntry(T entry);
}

typedef DirectoryRowActionHandler<T extends NamedDirectoryEntry> = Future<void>
    Function(
  NamedDirectoryDialogController<T> controller,
  T entry,
);

class DirectoryRowActionSpec<T extends NamedDirectoryEntry> {
  const DirectoryRowActionSpec({
    required this.id,
    required this.label,
    required this.placement,
    required this.onInvoke,
    this.icon,
  });

  final String id;
  final String label;
  final DirectoryRowActionPlacement placement;
  final IconData? icon;
  final DirectoryRowActionHandler<T> onInvoke;
}

class NamedDirectoryDialogConfig<T extends NamedDirectoryEntry> {
  const NamedDirectoryDialogConfig({
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
  final List<DirectoryColumnSpec<T>> columns;
  final List<DirectoryRowActionSpec<T>> rowActions;
  final bool showColumnHeaders;
  final String okButtonText;
  final String retryButtonText;
}
