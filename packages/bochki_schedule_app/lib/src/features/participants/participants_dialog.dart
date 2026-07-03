import 'dart:async';

import 'package:flutter/material.dart';

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

  String? _editingParticipantId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(Participant participant) {
    setState(() {
      _editingParticipantId = participant.id;
      _nameController.text = participant.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
    widget.viewModel.clearFormError();
  }

  void _cancelEditing() {
    setState(() {
      _editingParticipantId = null;
      _nameController.clear();
    });
    widget.viewModel.clearFormError();
  }

  Future<void> _submitParticipant() async {
    final viewModel = widget.viewModel;
    final isSuccess = _editingParticipantId == null
        ? await viewModel.createParticipant(_nameController.text)
        : await viewModel.updateParticipant(
            participantId: _editingParticipantId!,
            rawName: _nameController.text,
          );
    if (!isSuccess || !mounted) {
      return;
    }

    setState(() {
      _editingParticipantId = null;
      _nameController.clear();
    });
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

    final viewModel = widget.viewModel;
    final isSuccess = await viewModel.deleteParticipant(participant.id);
    if (!mounted) {
      return;
    }
    if (isSuccess) {
      if (_editingParticipantId == participant.id) {
        _cancelEditing();
      }
      return;
    }

    final message =
        viewModel.actionErrorMessage ?? 'Не удалось удалить участника.';
    viewModel.clearActionError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, child) {
        final viewModel = widget.viewModel;
        final isEditing = _editingParticipantId != null;

        return Dialog(
          key: const Key('participants_directory_dialog'),
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 760,
            height: 600,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Участники',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD0D7DE)),
                      ),
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : viewModel.loadErrorMessage != null
                              ? _ParticipantsLoadError(
                                  message: viewModel.loadErrorMessage!,
                                  onRetry: viewModel.loadParticipants,
                                )
                              : viewModel.participants.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Пока нет ни одного участника.',
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: viewModel.participants.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final participant =
                                            viewModel.participants[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFD8DEE4),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  participant.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              TextButton(
                                                onPressed: viewModel.isSaving
                                                    ? null
                                                    : () => _startEditing(
                                                          participant,
                                                        ),
                                                child: const Text(
                                                  'Редактировать',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton(
                                                onPressed: viewModel.isSaving
                                                    ? null
                                                    : () => unawaited(
                                                          _deleteParticipant(
                                                            participant,
                                                          ),
                                                        ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                ),
                                                child: const Text('Удалить'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD0D7DE)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isEditing
                                ? 'Редактировать участника'
                                : 'Новый участник',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('participant_name_field'),
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Имя',
                              errorText: viewModel.formErrorMessage,
                            ),
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => viewModel.clearFormError(),
                            onSubmitted: viewModel.isSaving
                                ? null
                                : (_) => unawaited(_submitParticipant()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isEditing) ...[
                                TextButton(
                                  onPressed: viewModel.isSaving
                                      ? null
                                      : _cancelEditing,
                                  child: const Text('Отменить редактирование'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              FilledButton(
                                onPressed: viewModel.isSaving
                                    ? null
                                    : () => unawaited(_submitParticipant()),
                                child: Text(
                                  isEditing ? 'Сохранить' : 'Добавить',
                                ),
                              ),
                            ],
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
