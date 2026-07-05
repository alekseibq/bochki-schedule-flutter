import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/named_directory/named_directory_entry.dart';
import 'directory_table_state.dart';
import 'named_directory_dialog_config.dart';
import 'named_directory_view_model.dart';

const double _indicatorColumnWidth = 40;
const Color _tableDividerColor = Color(0xFFD7DFE8);
const Color _rowBorderColor = Color(0xFFD8E1EA);
const double _contextMenuWidth = 144;
const double _contextMenuItemHeight = 44;

class NamedDirectoryDialog<T extends NamedDirectoryEntry>
    extends StatefulWidget {
  const NamedDirectoryDialog({
    required this.viewModel,
    required this.config,
    super.key,
  });

  final NamedDirectoryViewModel<T> viewModel;
  final NamedDirectoryDialogConfig<T> config;

  @override
  State<NamedDirectoryDialog<T>> createState() => _NamedDirectoryDialogState<T>();
}

class _NamedDirectoryDialogState<T extends NamedDirectoryEntry>
    extends State<NamedDirectoryDialog<T>>
    implements NamedDirectoryDialogController<T> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _tableFocusNode = FocusNode();
  final GlobalKey _tableAreaKey = GlobalKey();
  final DirectoryTableReducer _reducer = const DirectoryTableReducer();

  DirectoryTableState _tableState = const DirectoryTableNoSelection();
  Future<bool>? _pendingSubmit;

  NamedDirectoryDialogConfig<T> get _config => widget.config;
  List<DirectoryRowActionSpec<T>> get _contextMenuActions => _config.rowActions
      .where((action) => action.placement == DirectoryRowActionPlacement.contextMenu)
      .toList(growable: false);
  List<DirectoryRowActionSpec<T>> get _rowButtonActions => _config.rowActions
      .where((action) => action.placement == DirectoryRowActionPlacement.rowButton)
      .toList(growable: false);

  List<DirectoryTableRowData> get _rows => [
        for (final entry in widget.viewModel.entries)
          DirectoryTableRowData(
            id: entry.id,
            editValue: entry.name,
          ),
      ];

  bool _isEnterKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  @override
  BuildContext get context => super.context;

  @override
  void dispose() {
    _nameController.dispose();
    _editorFocusNode.dispose();
    _tableFocusNode.dispose();
    super.dispose();
  }

  bool _isEditingEntry(T entry) {
    final tableState = _tableState;
    return tableState is DirectoryTableEditRow && tableState.entryId == entry.id;
  }

  bool _isSelectedEntry(T entry) {
    return _tableState.selectedEntryId == entry.id;
  }

  void _requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editorFocusNode.requestFocus();
      }
    });
  }

  void _requestTableFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tableFocusNode.requestFocus();
      }
    });
  }

  void _syncControllerFromState(DirectoryTableState state) {
    final nextText = switch (state) {
      DirectoryTableEditRow(:final currentValue) => currentValue,
      DirectoryTableEditNewRow(:final currentValue) => currentValue,
      _ => '',
    };

    if (_nameController.text == nextText) {
      return;
    }

    _nameController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  void _setTableState(
    DirectoryTableState nextState, {
    bool clearFormError = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _tableState = nextState;
      _syncControllerFromState(nextState);
    });

    if (clearFormError) {
      widget.viewModel.clearFormError();
    }

    if (nextState.isEditing) {
      _requestEditorFocus();
    } else {
      _editorFocusNode.unfocus();
      _requestTableFocus();
    }
  }

  @override
  T? findEntryById(String entryId) {
    for (final entry in widget.viewModel.entries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  String? _findEntryIdByName(String name) {
    final normalizedName = NamedDirectoryEntry.sortKeyForName(name);
    for (final entry in widget.viewModel.entries) {
      if (NamedDirectoryEntry.sortKeyForName(entry.name) == normalizedName) {
        return entry.id;
      }
    }
    return null;
  }

  void _showActionErrorIfNeeded() {
    final message = widget.viewModel.actionErrorMessage;
    if (!mounted || message == null) {
      return;
    }

    widget.viewModel.clearActionError();
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _submit(DirectoryTableSubmitRequest request) {
    if (_pendingSubmit != null) {
      return _pendingSubmit!;
    }

    final viewModel = widget.viewModel;
    final submitFuture = () async {
      final isSuccess = switch (request.mode) {
        DirectoryTableSubmitMode.create =>
          await viewModel.createEntry(request.rawValue),
        DirectoryTableSubmitMode.update => await viewModel.updateEntry(
            entryId: request.entryId!,
            rawName: request.rawValue,
          ),
      };

      if (!mounted) {
        return isSuccess;
      }

      if (isSuccess) {
        _setTableState(
          _reducer.resolveSubmitSuccess(
            target: request.successTarget,
            rows: _rows,
            createdEntryId: request.mode == DirectoryTableSubmitMode.create
                ? _findEntryIdByName(request.rawValue)
                : null,
          ),
          clearFormError: true,
        );
      } else {
        _showActionErrorIfNeeded();
        _requestEditorFocus();
      }

      return isSuccess;
    }();

    _pendingSubmit = submitFuture;
    submitFuture.whenComplete(() {
      _pendingSubmit = null;
    });
    return submitFuture;
  }

  void _dispatch(
    DirectoryTableEvent event, {
    bool clearFormError = false,
  }) {
    final viewModel = widget.viewModel;
    if (viewModel.isLoading || viewModel.isSaving) {
      return;
    }

    final transition = _reducer.reduce(
      state: _tableState,
      event: event,
      rows: _rows,
    );

    _setTableState(
      transition.state,
      clearFormError: clearFormError,
    );

    final submitRequest = transition.submitRequest;
    if (submitRequest != null) {
      unawaited(_submit(submitRequest));
    }
  }

  Offset _toTableLocalPosition(Offset globalPosition) {
    final renderObject = _tableAreaKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return globalPosition;
    }
    return renderObject.globalToLocal(globalPosition);
  }

  void _handleEntryTapDown(T entry) {
    if (_tableState.isEditing) {
      return;
    }

    final tableState = _tableState;
    if (tableState is DirectoryTableSelectedRow &&
        tableState.entryId == entry.id &&
        !tableState.isContextMenuOpen) {
      return;
    }

    _setTableState(
      DirectoryTableSelectedRow(entryId: entry.id),
    );
  }

  @override
  void beginEdit(String entryId) {
    _setTableState(
      _reducer.resolveSubmitSuccess(
        target: DirectoryTableSuccessTarget.editRow(entryId),
        rows: _rows,
      ),
      clearFormError: true,
    );
  }

  @override
  Future<void> deleteEntry(T entry) async {
    final previousEntries = widget.viewModel.entries;
    final deletedIndex = previousEntries.indexWhere(
      (candidate) => candidate.id == entry.id,
    );

    final confirmed = await showDialog<bool>(
      context: this.context,
      builder: (context) {
        return AlertDialog(
          title: Text(_config.deleteConfirmationTitle),
          content: Text(_config.deleteConfirmationMessage(entry)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final isSuccess = await widget.viewModel.deleteEntry(entry.id);
    if (!mounted) {
      return;
    }

    if (!isSuccess) {
      _showActionErrorIfNeeded();
      return;
    }

    final nextEntries = widget.viewModel.entries;
    if (nextEntries.isEmpty) {
      _setTableState(const DirectoryTableNoSelection());
      return;
    }

    final nextSelectionIndex = deletedIndex.clamp(0, nextEntries.length - 1);
    _setTableState(
      DirectoryTableSelectedRow(
        entryId: nextEntries[nextSelectionIndex].id,
      ),
    );
  }

  bool _handleTableKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || widget.viewModel.isSaving) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _dispatch(const DirectoryTableEvent.pressArrowDown());
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _dispatch(const DirectoryTableEvent.pressArrowUp());
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dispatch(const DirectoryTableEvent.pressEscape());
      return true;
    }
    if (_isEnterKey(event.logicalKey) ||
        event.logicalKey == LogicalKeyboardKey.f2) {
      _dispatch(const DirectoryTableEvent.pressEnter());
      return true;
    }

    return false;
  }

  Widget _buildIndicatorCell({
    required Widget child,
  }) {
    return Container(
      width: _indicatorColumnWidth,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _tableDividerColor),
        ),
      ),
      child: child,
    );
  }

  Widget _buildHeaderRow(BuildContext context, int count) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _dispatch(const DirectoryTableEvent.clickOutside()),
      child: Container(
        color: const Color(0xFFD7E8FB),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIndicatorCell(
              child: SizedBox(key: Key(_config.tableDividerKey)),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  _config.sectionTitleBuilder(count),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF123A63),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHeaderRow(BuildContext context) {
    if (!_config.showColumnHeaders) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8),
        border: Border(
          bottom: BorderSide(color: _rowBorderColor),
        ),
      ),
      child: Row(
        children: [
          _buildIndicatorCell(child: const SizedBox.shrink()),
          Expanded(
            child: Row(
              children: [
                for (final column in _config.columns)
                  Expanded(
                    flex: column.flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        column.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_rowButtonActions.isNotEmpty)
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required bool isEditing,
    required bool isAddRow,
    required bool isSelected,
  }) {
    if (isEditing) {
      return const Icon(Icons.edit, size: 16, color: Color(0xFF1D4F8C));
    }
    if (isAddRow) {
      return const Text(
        '*',
        style: TextStyle(
          color: Color(0xFF56718D),
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (isSelected) {
      return const Text(
        '▶',
        style: TextStyle(
          color: Color(0xFF1D4F8C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNameEditor(NamedDirectoryViewModel<T> viewModel) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _dispatch(const DirectoryTableEvent.pressEscape());
          return KeyEventResult.handled;
        }
        if (_isEnterKey(event.logicalKey)) {
          _dispatch(const DirectoryTableEvent.pressEnter());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _dispatch(const DirectoryTableEvent.pressArrowUp());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _dispatch(const DirectoryTableEvent.pressArrowDown());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        key: Key('${_config.entryKeyPrefix}_name_field'),
        focusNode: _editorFocusNode,
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(
          isDense: true,
          hintText: _config.inlineFieldHintText,
          errorText: viewModel.formErrorMessage,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        textInputAction: TextInputAction.done,
        onChanged: (value) => _dispatch(
          DirectoryTableEvent.textChanged(value),
          clearFormError: true,
        ),
        onSubmitted: (_) => _dispatch(const DirectoryTableEvent.pressEnter()),
      ),
    );
  }

  List<Widget> _buildDisplayColumns(BuildContext context, T entry) {
    return [
      for (final column in _config.columns)
        Expanded(
          flex: column.flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              column.cellText(entry),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
    ];
  }

  Widget _buildRowButtons(T entry) {
    if (_rowButtonActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in _rowButtonActions)
          IconButton(
            tooltip: action.label,
            onPressed: () => unawaited(action.onInvoke(this, entry)),
            icon: Icon(action.icon ?? Icons.more_horiz),
          ),
      ],
    );
  }

  Widget _buildEntryRow(
    BuildContext context,
    NamedDirectoryViewModel<T> viewModel,
    T entry,
  ) {
    final isEditing = _isEditingEntry(entry);
    final isSelected = _isSelectedEntry(entry);
    final backgroundColor = isEditing
        ? const Color(0xFFE3F0FF)
        : isSelected
            ? const Color(0xFFF0F7FF)
            : Colors.white;

    return Listener(
      key: Key('${_config.entryKeyPrefix}_row_${entry.id}'),
      onPointerDown: viewModel.isSaving
          ? null
          : (event) {
              if (event.buttons == kPrimaryMouseButton) {
                _handleEntryTapDown(entry);
              }
            },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: viewModel.isSaving || !_tableState.isEditing
            ? null
            : () => _dispatch(DirectoryTableEvent.clickRow(entry.id)),
        onDoubleTap: viewModel.isSaving
            ? null
            : () => _dispatch(
                  DirectoryTableEvent.doubleClickRow(entry.id),
                  clearFormError: true,
                ),
        onSecondaryTapDown: viewModel.isSaving
            ? null
            : (details) => _dispatch(
                  DirectoryTableEvent.rightClickRow(
                    entryId: entry.id,
                    position: _toTableLocalPosition(details.globalPosition),
                  ),
                ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _rowBorderColor),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIndicatorCell(
                child: _buildIndicator(
                  isEditing: isEditing,
                  isAddRow: false,
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        if (isEditing)
                          Expanded(child: _buildNameEditor(viewModel))
                        else
                          ..._buildDisplayColumns(context, entry),
                        if (_rowButtonActions.isNotEmpty) _buildRowButtons(entry),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRow(
    BuildContext context,
    NamedDirectoryViewModel<T> viewModel,
  ) {
    final isEditing = _tableState is DirectoryTableEditNewRow;
    final backgroundColor =
        isEditing ? const Color(0xFFDDEAF8) : const Color(0xFFE8F0F6);

    return GestureDetector(
      key: Key('${_config.entryKeyPrefix}_add_row'),
      behavior: HitTestBehavior.opaque,
      onTap: viewModel.isSaving
          ? null
          : () => _dispatch(
                const DirectoryTableEvent.clickNewRow(),
                clearFormError: true,
              ),
      onSecondaryTapDown: viewModel.isSaving
          ? null
          : (_) => _dispatch(const DirectoryTableEvent.rightClickNewRow()),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _rowBorderColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIndicatorCell(
              child: _buildIndicator(
                isEditing: isEditing,
                isAddRow: true,
                isSelected: false,
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: backgroundColor,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: isEditing
                      ? _buildNameEditor(viewModel)
                      : Text(
                          _config.addRowLabel,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF60758B),
                              ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenu(Size size) {
    final tableState = _tableState;
    if (tableState is! DirectoryTableSelectedRow ||
        tableState.contextMenuPosition == null) {
      return const SizedBox.shrink();
    }

    final entry = findEntryById(tableState.entryId);
    if (entry == null || _contextMenuActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final contextMenuPosition = tableState.contextMenuPosition!;
    final menuHeight = _contextMenuActions.length * _contextMenuItemHeight;
    final left = math.min<double>(
      math.max(contextMenuPosition.dx, 0),
      math.max(size.width - _contextMenuWidth, 0),
    );
    final top = math.min<double>(
      math.max(contextMenuPosition.dy, 0),
      math.max(size.height - menuHeight, 0),
    );

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 8,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: _contextMenuWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < _contextMenuActions.length; index++) ...[
                _ContextMenuButton(
                  label: _contextMenuActions[index].label,
                  onTap: () => unawaited(
                    _contextMenuActions[index].onInvoke(this, entry),
                  ),
                ),
                if (index != _contextMenuActions.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableArea(
    BuildContext context,
    NamedDirectoryViewModel<T> viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: _tableAreaKey,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _dispatch(const DirectoryTableEvent.clickOutside()),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FBFD),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_config.showColumnHeaders) _buildColumnHeaderRow(context),
                  for (final entry in viewModel.entries)
                    _buildEntryRow(context, viewModel, entry),
                  _buildAddRow(context, viewModel),
                ],
              ),
            ),
            _buildContextMenu(constraints.biggest),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, child) {
        final viewModel = widget.viewModel;

        return Dialog(
          key: Key(_config.dialogKey),
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: Focus(
            autofocus: true,
            focusNode: _tableFocusNode,
            onKeyEvent: (node, event) => _handleTableKeyEvent(event)
                ? KeyEventResult.handled
                : KeyEventResult.ignored,
            child: SizedBox(
              width: 720,
              height: 560,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F7FA),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD0D7DE)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _dispatch(
                              const DirectoryTableEvent.clickOutside(),
                            ),
                            child: Text(
                              _config.dialogTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Закрыть',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.loadErrorMessage != null
                            ? _NamedDirectoryLoadError(
                                message: viewModel.loadErrorMessage!,
                                retryButtonText: _config.retryButtonText,
                                onRetry: viewModel.loadEntries,
                              )
                            : Column(
                                children: [
                                  _buildHeaderRow(
                                    context,
                                    viewModel.entries.length,
                                  ),
                                  Expanded(
                                    child: _buildTableArea(context, viewModel),
                                  ),
                                ],
                              ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        _dispatch(const DirectoryTableEvent.clickOutside()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F7FA),
                        border: Border(
                          top: BorderSide(color: Color(0xFFD0D7DE)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(_config.okButtonText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContextMenuButton extends StatelessWidget {
  const _ContextMenuButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }
}

class _NamedDirectoryLoadError extends StatelessWidget {
  const _NamedDirectoryLoadError({
    required this.message,
    required this.retryButtonText,
    required this.onRetry,
  });

  final String message;
  final String retryButtonText;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => unawaited(onRetry()),
              child: Text(retryButtonText),
            ),
          ],
        ),
      ),
    );
  }
}
