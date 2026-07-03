import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/participants/participant.dart';
import 'participants_view_model.dart';

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

  String? _selectedParticipantId;
  String? _editingParticipantId;
  bool _isCreating = false;
  Future<bool>? _pendingSubmit;
  String? _pendingTransitionParticipantId;
  bool _pendingTransitionToAddRow = false;
  bool _ignoreNextTapOutsideSubmit = false;
  String? _tapDownHandledParticipantId;
  bool _tapDownHandledAddRow = false;

  bool get _isEditing => _isCreating || _editingParticipantId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  bool _isEditingParticipant(Participant participant) {
    return _editingParticipantId == participant.id;
  }

  bool _isSelectedParticipant(Participant participant) {
    return _selectedParticipantId == participant.id;
  }

  void _requestEditorFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editorFocusNode.requestFocus();
      }
    });
  }

  void _startEditingParticipant(Participant participant) {
    setState(() {
      _selectedParticipantId = participant.id;
      _editingParticipantId = participant.id;
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
      _isCreating = true;
      _nameController.clear();
    });
    widget.viewModel.clearFormError();
    _requestEditorFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingParticipantId = null;
      _isCreating = false;
      _nameController.clear();
    });
    widget.viewModel.clearFormError();
    _editorFocusNode.unfocus();
  }

  void _prepareParticipantTransition(Participant participant) {
    if (_isEditing && !_isEditingParticipant(participant)) {
      _pendingTransitionParticipantId = participant.id;
      _pendingTransitionToAddRow = false;
      _ignoreNextTapOutsideSubmit = true;
    }
  }

  void _prepareAddRowTransition() {
    if (_isEditing && !_isCreating) {
      _pendingTransitionParticipantId = null;
      _pendingTransitionToAddRow = true;
      _ignoreNextTapOutsideSubmit = true;
    }
  }

  void _clearPendingTransition() {
    _pendingTransitionParticipantId = null;
    _pendingTransitionToAddRow = false;
  }

  Future<void> _submitAndStartEditing(Participant participant) async {
    final isSuccess = await _submitCurrentEditing();
    if (!mounted || !isSuccess) {
      return;
    }
    _startEditingParticipant(participant);
  }

  Future<void> _submitAndStartCreating() async {
    final isSuccess = await _submitCurrentEditing();
    if (!mounted || !isSuccess) {
      return;
    }
    _startCreatingParticipant();
  }

  void _handleParticipantTapDown(Participant participant) {
    if (_isEditing && !_isEditingParticipant(participant)) {
      _tapDownHandledParticipantId = participant.id;
      _ignoreNextTapOutsideSubmit = true;
      unawaited(_submitAndStartEditing(participant));
      return;
    }
    _prepareParticipantTransition(participant);
  }

  void _handleAddRowTapDown() {
    if (_isEditing && !_isCreating) {
      _tapDownHandledAddRow = true;
      _ignoreNextTapOutsideSubmit = true;
      unawaited(_submitAndStartCreating());
      return;
    }
    _prepareAddRowTransition();
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

  String? _findParticipantIdByName(String name) {
    final normalizedName = Participant.sortKeyForName(name);
    for (final participant in widget.viewModel.participants) {
      if (Participant.sortKeyForName(participant.name) == normalizedName) {
        return participant.id;
      }
    }
    return null;
  }

  Future<bool> _submitCurrentEditing() {
    if (!_isEditing) {
      return Future<bool>.value(true);
    }
    if (_pendingSubmit != null) {
      return _pendingSubmit!;
    }

    final editingParticipantId = _editingParticipantId;
    final isCreating = _isCreating;
    final rawName = _nameController.text;
    final viewModel = widget.viewModel;

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
        setState(() {
          _editingParticipantId = null;
          _isCreating = false;
          _nameController.clear();
          _selectedParticipantId = isCreating
              ? _findParticipantIdByName(rawName)
              : editingParticipantId;
        });
        _editorFocusNode.unfocus();
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

  Future<void> _handleParticipantTap(Participant participant) async {
    if (_tapDownHandledParticipantId == participant.id) {
      _tapDownHandledParticipantId = null;
      return;
    }

    final shouldTransitionToEdit =
        _pendingTransitionParticipantId == participant.id;
    _clearPendingTransition();

    if (_isEditingParticipant(participant)) {
      setState(() {
        _selectedParticipantId = participant.id;
      });
      return;
    }

    if (_isEditing || shouldTransitionToEdit) {
      final isSuccess = await _submitCurrentEditing();
      if (!mounted || !isSuccess) {
        return;
      }
      _startEditingParticipant(participant);
      return;
    }

    setState(() {
      _selectedParticipantId = participant.id;
    });
  }

  Future<void> _handleParticipantDoubleTap(Participant participant) async {
    _clearPendingTransition();

    if (_isEditingParticipant(participant)) {
      return;
    }

    if (_isEditing) {
      final isSuccess = await _submitCurrentEditing();
      if (!mounted || !isSuccess) {
        return;
      }
    }

    _startEditingParticipant(participant);
  }

  Future<void> _handleAddRowTap() async {
    if (_tapDownHandledAddRow) {
      _tapDownHandledAddRow = false;
      return;
    }

    final shouldTransitionToAddRow = _pendingTransitionToAddRow;
    _clearPendingTransition();

    if (_isCreating) {
      return;
    }

    if (_isEditing || shouldTransitionToAddRow) {
      final isSuccess = await _submitCurrentEditing();
      if (!mounted || !isSuccess) {
        return;
      }
    }

    _startCreatingParticipant();
  }

  Future<void> _deleteParticipant(Participant participant) async {
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
      if (_editingParticipantId == participant.id) {
        _cancelEditing();
      }
      if (_selectedParticipantId == participant.id) {
        setState(() {
          _selectedParticipantId = null;
        });
      }
      return;
    }

    _showActionErrorIfNeeded();
  }

  Future<void> _showParticipantContextMenu(
    Participant participant,
    TapDownDetails details,
  ) async {
    if (_isEditing && !_isEditingParticipant(participant)) {
      final isSuccess = await _submitCurrentEditing();
      if (!mounted || !isSuccess) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedParticipantId = participant.id;
    });

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

  Key _rowKey(String value) => Key('participant_row_$value');

  Widget _buildHeaderRow(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFD7E8FB),
        border: Border(
          bottom: BorderSide(color: Color(0xFFB6CCE3)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Участники ($count)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF123A63),
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
            : (_) {
                if (_ignoreNextTapOutsideSubmit) {
                  _ignoreNextTapOutsideSubmit = false;
                  return;
                }
                if (_pendingTransitionParticipantId != null ||
                    _pendingTransitionToAddRow) {
                  return;
                }
                unawaited(_submitCurrentEditing());
              },
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
      key: _rowKey(participant.id),
      behavior: HitTestBehavior.opaque,
      onTapDown: viewModel.isSaving
          ? null
          : (_) => _handleParticipantTapDown(participant),
      onTap: viewModel.isSaving
          ? null
          : () => unawaited(_handleParticipantTap(participant)),
      onDoubleTap: viewModel.isSaving
          ? null
          : () => unawaited(_handleParticipantDoubleTap(participant)),
      onSecondaryTapDown: viewModel.isSaving
          ? null
          : (details) => unawaited(
                _showParticipantContextMenu(participant, details),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFD8E1EA)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.center,
                child: _buildIndicator(
                  isEditing: isEditing,
                  isAddRow: false,
                  isSelected: isSelected,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isEditing
                  ? _buildNameEditor(viewModel)
                  : Text(
                      participant.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRow(BuildContext context, ParticipantsViewModel viewModel) {
    final isEditing = _isCreating;

    return GestureDetector(
      key: const Key('participant_add_row'),
      behavior: HitTestBehavior.opaque,
      onTapDown: viewModel.isSaving ? null : (_) => _handleAddRowTapDown(),
      onTap: viewModel.isSaving ? null : () => unawaited(_handleAddRowTap()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F0F6),
          border: Border(
            bottom: BorderSide(color: Color(0xFFD8E1EA)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.center,
                child: _buildIndicator(
                  isEditing: isEditing,
                  isAddRow: true,
                  isSelected: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isEditing
                  ? _buildNameEditor(viewModel)
                  : Text(
                      'Добавить новую запись',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF60758B),
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
