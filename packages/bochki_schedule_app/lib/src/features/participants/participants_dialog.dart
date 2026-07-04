import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/participants/participant.dart';
import 'participants_table_state.dart';
import 'participants_view_model.dart';

const double _indicatorColumnWidth = 40;
const Color _tableDividerColor = Color(0xFFD7DFE8);
const Color _rowBorderColor = Color(0xFFD8E1EA);
const Key _tableDividerKey = Key('participants_table_divider');
const double _contextMenuWidth = 144;
const double _contextMenuHeight = 88;

class ParticipantsDialog extends StatefulWidget {
  const ParticipantsDialog({
    required this.viewModel,
    super.key,
  });

  final ParticipantsViewModel viewModel;

  @override
  State<ParticipantsDialog> createState() => _ParticipantsDialogState();
}

class _ParticipantsDialogState extends State<ParticipantsDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _tableFocusNode = FocusNode();
  final GlobalKey _tableAreaKey = GlobalKey();
  final ParticipantsTableReducer _reducer = const ParticipantsTableReducer();

  ParticipantsTableState _tableState = const ParticipantsTableNoSelection();
  Future<bool>? _pendingSubmit;

  List<ParticipantsTableRowData> get _rows => [
        for (final participant in widget.viewModel.participants)
          ParticipantsTableRowData(
            id: participant.id,
            name: participant.name,
          ),
      ];

  bool _isEnterKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _editorFocusNode.dispose();
    _tableFocusNode.dispose();
    super.dispose();
  }

  bool _isEditingParticipant(Participant participant) {
    final tableState = _tableState;
    return tableState is ParticipantsTableEditDataRow &&
        tableState.participantId == participant.id;
  }

  bool _isSelectedParticipant(Participant participant) {
    return _tableState.selectedParticipantId == participant.id;
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

  void _syncControllerFromState(ParticipantsTableState state) {
    final nextText = switch (state) {
      ParticipantsTableEditDataRow(:final currentValue) => currentValue,
      ParticipantsTableEditNewRow(:final currentValue) => currentValue,
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
    ParticipantsTableState nextState, {
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

  Participant? _findParticipantById(String participantId) {
    for (final participant in widget.viewModel.participants) {
      if (participant.id == participantId) {
        return participant;
      }
    }
    return null;
  }

  String? _findParticipantIdByName(String name) {
    final normalizedName = Participant.sortKeyForName(name);
    for (final participant in widget.viewModel.participants) {
      if (Participant.sortKeyForName(participant.name) == normalizedName) {
        return participant.id;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _submit(
    ParticipantsTableSubmitRequest request,
  ) {
    if (_pendingSubmit != null) {
      return _pendingSubmit!;
    }

    final viewModel = widget.viewModel;
    final submitFuture = () async {
      final isSuccess = switch (request.mode) {
        ParticipantsTableSubmitMode.create =>
          await viewModel.createParticipant(request.rawValue),
        ParticipantsTableSubmitMode.update => await viewModel.updateParticipant(
            participantId: request.participantId!,
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
            createdParticipantId:
                request.mode == ParticipantsTableSubmitMode.create
                    ? _findParticipantIdByName(request.rawValue)
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
    ParticipantsTableEvent event, {
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

  void _handleParticipantTapDown(Participant participant) {
    if (_tableState.isEditing) {
      return;
    }

    final tableState = _tableState;
    if (tableState is ParticipantsTableSelectedDataRow &&
        tableState.participantId == participant.id &&
        !tableState.isContextMenuOpen) {
      return;
    }

    _setTableState(
      ParticipantsTableSelectedDataRow(participantId: participant.id),
    );
  }

  Future<void> _deleteParticipant(Participant participant) async {
    final previousParticipants = widget.viewModel.participants;
    final deletedIndex = previousParticipants.indexWhere(
      (candidate) => candidate.id == participant.id,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить участника?'),
          content: Text(
            'Участник "${participant.name}" будет скрыт из списка.',
          ),
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

    final isSuccess = await widget.viewModel.deleteParticipant(participant.id);
    if (!mounted) {
      return;
    }

    if (!isSuccess) {
      _showActionErrorIfNeeded();
      return;
    }

    final nextParticipants = widget.viewModel.participants;
    if (nextParticipants.isEmpty) {
      _setTableState(const ParticipantsTableNoSelection());
      return;
    }

    final nextSelectionIndex =
        deletedIndex.clamp(0, nextParticipants.length - 1);
    _setTableState(
      ParticipantsTableSelectedDataRow(
        participantId: nextParticipants[nextSelectionIndex].id,
      ),
    );
  }

  bool _handleTableKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || widget.viewModel.isSaving) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _dispatch(const ParticipantsTableEvent.pressArrowDown());
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _dispatch(const ParticipantsTableEvent.pressArrowUp());
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dispatch(const ParticipantsTableEvent.pressEscape());
      return true;
    }
    if (_isEnterKey(event.logicalKey) ||
        event.logicalKey == LogicalKeyboardKey.f2) {
      _dispatch(const ParticipantsTableEvent.pressEnter());
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
      onTap: () => _dispatch(const ParticipantsTableEvent.clickOutside()),
      child: Container(
        color: const Color(0xFFD7E8FB),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIndicatorCell(
              child: const SizedBox(key: _tableDividerKey),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  'Участники ($count)',
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

  Widget _buildNameEditor(ParticipantsViewModel viewModel) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _dispatch(const ParticipantsTableEvent.pressEscape());
          return KeyEventResult.handled;
        }
        if (_isEnterKey(event.logicalKey)) {
          _dispatch(const ParticipantsTableEvent.pressEnter());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _dispatch(const ParticipantsTableEvent.pressArrowUp());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _dispatch(const ParticipantsTableEvent.pressArrowDown());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        key: const Key('participant_name_field'),
        focusNode: _editorFocusNode,
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Введите имя участника',
          errorText: viewModel.formErrorMessage,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        textInputAction: TextInputAction.done,
        onChanged: (value) => _dispatch(
          ParticipantsTableEvent.textChanged(value),
          clearFormError: true,
        ),
        onSubmitted: (_) =>
            _dispatch(const ParticipantsTableEvent.pressEnter()),
      ),
    );
  }

  Widget _buildParticipantRow(
    BuildContext context,
    ParticipantsViewModel viewModel,
    Participant participant,
  ) {
    final isEditing = _isEditingParticipant(participant);
    final isSelected = _isSelectedParticipant(participant);
    final backgroundColor = isEditing
        ? const Color(0xFFE3F0FF)
        : isSelected
            ? const Color(0xFFF0F7FF)
            : Colors.white;

    return GestureDetector(
      key: Key('participant_row_${participant.id}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: viewModel.isSaving
          ? null
          : (_) => _handleParticipantTapDown(participant),
      onTap: viewModel.isSaving
          ? null
          : () => _dispatch(
                ParticipantsTableEvent.clickDataRow(participant.id),
              ),
      onDoubleTap: viewModel.isSaving
          ? null
          : () => _dispatch(
                ParticipantsTableEvent.doubleClickDataRow(participant.id),
                clearFormError: true,
              ),
      onSecondaryTapDown: viewModel.isSaving
          ? null
          : (details) => _dispatch(
                ParticipantsTableEvent.rightClickDataRow(
                  participantId: participant.id,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: isEditing
                      ? _buildNameEditor(viewModel)
                      : Text(
                          participant.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRow(BuildContext context, ParticipantsViewModel viewModel) {
    final isEditing = _tableState is ParticipantsTableEditNewRow;
    final backgroundColor =
        isEditing ? const Color(0xFFDDEAF8) : const Color(0xFFE8F0F6);

    return GestureDetector(
      key: const Key('participant_add_row'),
      behavior: HitTestBehavior.opaque,
      onTap: viewModel.isSaving
          ? null
          : () => _dispatch(
                const ParticipantsTableEvent.clickNewRow(),
                clearFormError: true,
              ),
      onSecondaryTapDown: viewModel.isSaving
          ? null
          : (_) => _dispatch(const ParticipantsTableEvent.rightClickNewRow()),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: isEditing
                      ? _buildNameEditor(viewModel)
                      : Text(
                          'Добавить новую запись',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    if (tableState is ParticipantsTableSelectedDataRow &&
        tableState.contextMenuPosition != null) {
      final participantId = tableState.participantId;
      final contextMenuPosition = tableState.contextMenuPosition!;
      final participant = _findParticipantById(participantId);
      if (participant == null) {
        return const SizedBox.shrink();
      }

      final left = math.min<double>(
        math.max(contextMenuPosition.dx, 0),
        math.max(size.width - _contextMenuWidth, 0),
      );
      final top = math.min<double>(
        math.max(contextMenuPosition.dy, 0),
        math.max(size.height - _contextMenuHeight, 0),
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
                _ContextMenuButton(
                  label: 'Edit',
                  onTap: () {
                    _setTableState(
                      _reducer.resolveSubmitSuccess(
                        target: ParticipantsTableSuccessTarget.editRow(
                          participantId,
                        ),
                        rows: _rows,
                      ),
                      clearFormError: true,
                    );
                  },
                ),
                const Divider(height: 1),
                _ContextMenuButton(
                  label: 'Delete',
                  onTap: () {
                    _setTableState(
                      ParticipantsTableSelectedDataRow(
                        participantId: participantId,
                      ),
                    );
                    unawaited(_deleteParticipant(participant));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTableArea(
    BuildContext context,
    ParticipantsViewModel viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: _tableAreaKey,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _dispatch(const ParticipantsTableEvent.clickOutside()),
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
                  for (final participant in viewModel.participants)
                    _buildParticipantRow(context, viewModel, participant),
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
          key: const Key('participants_directory_dialog'),
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
                                const ParticipantsTableEvent.clickOutside()),
                            child: Text(
                              'Список участников',
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
                            ? _ParticipantsLoadError(
                                message: viewModel.loadErrorMessage!,
                                onRetry: viewModel.loadParticipants,
                              )
                            : Column(
                                children: [
                                  _buildHeaderRow(
                                    context,
                                    viewModel.participants.length,
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
                        _dispatch(const ParticipantsTableEvent.clickOutside()),
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
                            child: const Text('Ok'),
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

class _ParticipantsLoadError extends StatelessWidget {
  const _ParticipantsLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
