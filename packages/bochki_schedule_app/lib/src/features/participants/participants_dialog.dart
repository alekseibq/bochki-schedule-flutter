import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/participants/participant.dart';
import 'participants_view_model.dart';

const double _indicatorColumnWidth = 40;
const Color _tableDividerColor = Color(0xFFD7DFE8);
const Color _rowBorderColor = Color(0xFFD8E1EA);
const Key _tableDividerKey = Key('participants_table_divider');

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

  String? _selectedParticipantId;
  String? _editingParticipantId;
  String? _editingInitialName;
  bool _isCreating = false;
  Future<bool>? _pendingSubmit;

  bool get _isEditing => _isCreating || _editingParticipantId != null;

  bool _isEnterKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    _nameController.dispose();
    _editorFocusNode.dispose();
    _tableFocusNode.dispose();
    super.dispose();
  }

  bool _isEditingParticipant(Participant participant) {
    return _editingParticipantId == participant.id;
  }

  bool _isSelectedParticipant(Participant participant) {
    return _selectedParticipantId == participant.id;
  }

  void _requestEditorFocus() {
    if (_editorFocusNode.context != null) {
      _editorFocusNode.requestFocus();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editorFocusNode.requestFocus();
      }
    });
  }

  void _requestTableFocus() {
    if (_tableFocusNode.context != null) {
      _tableFocusNode.requestFocus();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tableFocusNode.requestFocus();
      }
    });
  }

  void _startEditingParticipant(Participant participant) {
    setState(() {
      _selectedParticipantId = participant.id;
      _editingParticipantId = participant.id;
      _editingInitialName = participant.name;
      _isCreating = false;
      _nameController.text = participant.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
    widget.viewModel.clearFormError();
    _requestEditorFocus();
  }

  void _startCreatingParticipant() {
    setState(() {
      _selectedParticipantId = null;
      _editingParticipantId = null;
      _editingInitialName = null;
      _isCreating = true;
      _nameController.clear();
    });
    widget.viewModel.clearFormError();
    _requestEditorFocus();
  }

  void _finishEditing({
    required String? selectedParticipantId,
  }) {
    setState(() {
      _selectedParticipantId = selectedParticipantId;
      _editingParticipantId = null;
      _editingInitialName = null;
      _isCreating = false;
      _nameController.clear();
    });
    widget.viewModel.clearFormError();
    _editorFocusNode.unfocus();
    _requestTableFocus();
  }

  void _cancelEditing() {
    _finishEditing(selectedParticipantId: _editingParticipantId);
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

  Future<bool> _submitCurrentEditing({
    bool cancelEmptyCreate = false,
  }) {
    if (!_isEditing) {
      return Future<bool>.value(true);
    }
    if (_pendingSubmit != null) {
      return _pendingSubmit!;
    }

    final editingParticipantId = _editingParticipantId;
    final editingInitialName = _editingInitialName;
    final isCreating = _isCreating;
    final rawName = _nameController.text;
    final normalizedName = Participant.normalizeName(rawName);
    final viewModel = widget.viewModel;

    if (isCreating && cancelEmptyCreate && normalizedName.isEmpty) {
      _finishEditing(selectedParticipantId: _selectedParticipantId);
      return Future<bool>.value(true);
    }

    if (!isCreating &&
        editingParticipantId != null &&
        normalizedName == Participant.normalizeName(editingInitialName ?? '')) {
      _finishEditing(selectedParticipantId: editingParticipantId);
      return Future<bool>.value(true);
    }

    final submitFuture = () async {
      final isSuccess = isCreating
          ? await viewModel.createParticipant(rawName)
          : await viewModel.updateParticipant(
              participantId: editingParticipantId!,
              rawName: rawName,
            );

      if (!mounted) {
        return isSuccess;
      }

      if (isSuccess) {
        _finishEditing(
          selectedParticipantId: isCreating
              ? _findParticipantIdByName(rawName)
              : editingParticipantId,
        );
      } else {
        _showActionErrorIfNeeded();
      }

      return isSuccess;
    }();

    _pendingSubmit = submitFuture;
    submitFuture.whenComplete(() {
      _pendingSubmit = null;
    });
    return submitFuture;
  }

  void _restoreSelectionAfterFailedSubmit({
    required String? previousEditingParticipantId,
    required bool previousIsCreating,
  }) {
    setState(() {
      _selectedParticipantId =
          previousIsCreating ? null : previousEditingParticipantId;
    });
    _requestTableFocus();
  }

  Future<void> _selectParticipant(Participant participant) async {
    final previousEditingParticipantId = _editingParticipantId;
    final previousIsCreating = _isCreating;

    if (_isEditingParticipant(participant)) {
      if (_selectedParticipantId != participant.id) {
        setState(() {
          _selectedParticipantId = participant.id;
        });
      }
      _requestTableFocus();
      return;
    }

    if (_isEditing) {
      final isSuccess = await _submitCurrentEditing(cancelEmptyCreate: true);
      if (!mounted || !isSuccess) {
        _restoreSelectionAfterFailedSubmit(
          previousEditingParticipantId: previousEditingParticipantId,
          previousIsCreating: previousIsCreating,
        );
        return;
      }
    }

    setState(() {
      _selectedParticipantId = participant.id;
    });
    _requestTableFocus();
  }

  void _handleParticipantTapDown(Participant participant) {
    if (_selectedParticipantId == participant.id) {
      _requestTableFocus();
      return;
    }

    setState(() {
      _selectedParticipantId = participant.id;
    });
    _requestTableFocus();
  }

  Future<void> _handleParticipantDoubleTap(Participant participant) async {
    if (_isEditingParticipant(participant)) {
      return;
    }

    if (_isEditing) {
      final isSuccess = await _submitCurrentEditing(cancelEmptyCreate: true);
      if (!mounted || !isSuccess) {
        return;
      }
    }

    _startEditingParticipant(participant);
  }

  Future<void> _handleAddRowTap() async {
    if (_isCreating) {
      return;
    }

    if (_isEditing) {
      final isSuccess = await _submitCurrentEditing(cancelEmptyCreate: true);
      if (!mounted || !isSuccess) {
        return;
      }
    }

    _startCreatingParticipant();
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

    if (isSuccess) {
      final nextParticipants = widget.viewModel.participants;
      final nextSelectionIndex = nextParticipants.isEmpty
          ? null
          : deletedIndex.clamp(0, nextParticipants.length - 1) as int;
      final nextSelectedParticipantId = nextParticipants.isEmpty
          ? null
          : nextParticipants[nextSelectionIndex!].id;

      setState(() {
        if (_editingParticipantId == participant.id) {
          _editingParticipantId = null;
          _editingInitialName = null;
          _isCreating = false;
          _nameController.clear();
          _editorFocusNode.unfocus();
        }

        if (_selectedParticipantId == participant.id) {
          _selectedParticipantId = nextSelectedParticipantId;
        }
      });
      _requestTableFocus();
      return;
    }

    _showActionErrorIfNeeded();
  }

  Future<void> _showParticipantContextMenu(
    Participant participant,
    TapDownDetails details,
  ) async {
    final previousEditingParticipantId = _editingParticipantId;
    final previousIsCreating = _isCreating;

    if (_selectedParticipantId != participant.id) {
      setState(() {
        _selectedParticipantId = participant.id;
      });
    }
    _requestTableFocus();

    if (_isEditing && !_isEditingParticipant(participant)) {
      final isSuccess = await _submitCurrentEditing(cancelEmptyCreate: true);
      if (!mounted || !isSuccess) {
        _restoreSelectionAfterFailedSubmit(
          previousEditingParticipantId: previousEditingParticipantId,
          previousIsCreating: previousIsCreating,
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) {
      return;
    }

    final menuAction = await showMenu<_ParticipantMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          details.globalPosition.dx,
          details.globalPosition.dy,
          0,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem<_ParticipantMenuAction>(
          value: _ParticipantMenuAction.edit,
          child: Text('Edit'),
        ),
        PopupMenuItem<_ParticipantMenuAction>(
          value: _ParticipantMenuAction.delete,
          child: Text('Delete'),
        ),
      ],
      popUpAnimationStyle: AnimationStyle.noAnimation,
    );

    if (!mounted || menuAction == null) {
      return;
    }

    switch (menuAction) {
      case _ParticipantMenuAction.edit:
        _startEditingParticipant(participant);
      case _ParticipantMenuAction.delete:
        unawaited(_deleteParticipant(participant));
    }
  }

  void _moveSelection(int offset) {
    final participants = widget.viewModel.participants;
    if (participants.isEmpty) {
      return;
    }

    final currentIndex = _selectedParticipantId == null
        ? -1
        : participants.indexWhere(
            (participant) => participant.id == _selectedParticipantId,
          );
    final targetIndex = (currentIndex == -1
        ? (offset > 0 ? 0 : participants.length - 1)
        : (currentIndex + offset).clamp(0, participants.length - 1)) as int;

    setState(() {
      _selectedParticipantId = participants[targetIndex].id;
    });
    _requestTableFocus();
  }

  void _handleMoveSelectionShortcut(
    ParticipantsViewModel viewModel,
    int offset,
  ) {
    if (viewModel.isLoading || viewModel.isSaving || _isEditing) {
      return;
    }
    _moveSelection(offset);
  }

  void _handleStartEditingShortcut(ParticipantsViewModel viewModel) {
    if (viewModel.isLoading || viewModel.isSaving || _isEditing) {
      return;
    }

    final selectedParticipantId = _selectedParticipantId;
    if (selectedParticipantId == null) {
      return;
    }

    final participant = _findParticipantById(selectedParticipantId);
    if (participant == null) {
      return;
    }

    _startEditingParticipant(participant);
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent || _editorFocusNode.hasFocus) {
      return false;
    }

    final viewModel = widget.viewModel;
    if (viewModel.isLoading || viewModel.isSaving || _isEditing) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return true;
    }
    if (_isEnterKey(event.logicalKey) ||
        event.logicalKey == LogicalKeyboardKey.f2) {
      _handleStartEditingShortcut(viewModel);
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
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
          _cancelEditing();
          return KeyEventResult.handled;
        }
        if (_isEnterKey(event.logicalKey)) {
          if (!viewModel.isSaving) {
            unawaited(_submitCurrentEditing());
          }
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
        onChanged: (_) => viewModel.clearFormError(),
        onTapOutside: viewModel.isSaving
            ? null
            : (_) => unawaited(
                  _submitCurrentEditing(cancelEmptyCreate: true),
                ),
        onSubmitted: viewModel.isSaving
            ? null
            : (_) => unawaited(_submitCurrentEditing()),
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
          : () => unawaited(_selectParticipant(participant)),
      onDoubleTap: viewModel.isSaving
          ? null
          : () => unawaited(_handleParticipantDoubleTap(participant)),
      onSecondaryTapDown: viewModel.isSaving
          ? null
          : (details) => unawaited(
                _showParticipantContextMenu(participant, details),
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
    final isEditing = _isCreating;
    final backgroundColor =
        isEditing ? const Color(0xFFDDEAF8) : const Color(0xFFE8F0F6);

    return GestureDetector(
      key: const Key('participant_add_row'),
      behavior: HitTestBehavior.opaque,
      onTap: viewModel.isSaving ? null : () => unawaited(_handleAddRowTap()),
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
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _handleMoveSelectionShortcut(viewModel, 1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _handleMoveSelectionShortcut(viewModel, -1),
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    _handleStartEditingShortcut(viewModel),
                const SingleActivator(LogicalKeyboardKey.f2): () =>
                    _handleStartEditingShortcut(viewModel),
              },
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
                            child: Text(
                              'Список участников',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FBFD),
                        ),
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
                                        child: ListView(
                                          padding: EdgeInsets.zero,
                                          children: [
                                            for (final participant
                                                in viewModel.participants)
                                              _buildParticipantRow(
                                                context,
                                                viewModel,
                                                participant,
                                              ),
                                            _buildAddRow(context, viewModel),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    Container(
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ParticipantMenuAction {
  edit,
  delete,
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
