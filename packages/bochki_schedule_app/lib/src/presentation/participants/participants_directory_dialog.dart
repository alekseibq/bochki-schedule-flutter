import 'dart:async';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/material.dart';

import '../../application/participants_directory_use_case.dart';

class ParticipantsDirectoryDialog extends StatefulWidget {
  const ParticipantsDirectoryDialog({
    required this.document,
    required this.useCase,
    super.key,
  });

  final ProjectDocument document;
  final ParticipantsDirectoryUseCase useCase;

  @override
  State<ParticipantsDirectoryDialog> createState() =>
      _ParticipantsDirectoryDialogState();
}

class _ParticipantsDirectoryDialogState
    extends State<ParticipantsDirectoryDialog> {
  final TextEditingController _nameController = TextEditingController();

  late ProjectDocument _document;
  int? _editingParticipantId;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(_ParticipantRecord participant) {
    setState(() {
      _editingParticipantId = participant.id;
      _nameController.text = participant.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
      _nameError = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingParticipantId = null;
      _nameController.clear();
      _nameError = null;
    });
  }

  Future<void> _showMutationError(String message) async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitParticipant() async {
    final result = _editingParticipantId == null
        ? await widget.useCase.addParticipant(
            _document,
            _nameController.text,
          )
        : await widget.useCase.editParticipant(
            _document,
            _editingParticipantId!,
            _nameController.text,
          );

    if (!result.isSuccess) {
      setState(() {
        _nameError = result.errorMessage;
      });
      return;
    }

    setState(() {
      _document = result.document!;
      _editingParticipantId = null;
      _nameController.clear();
      _nameError = null;
    });
  }

  Future<void> _deleteParticipant(_ParticipantRecord participant) async {
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

    if (confirmed != true) {
      return;
    }

    final result = await widget.useCase.deleteParticipant(
      _document,
      participant.id,
    );
    if (!result.isSuccess) {
      await _showMutationError(
        result.errorMessage ?? 'Не удалось удалить участника.',
      );
      return;
    }

    setState(() {
      _document = result.document!;
      if (_editingParticipantId == participant.id) {
        _editingParticipantId = null;
        _nameController.clear();
        _nameError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeParticipants = widget.useCase
        .activeParticipants(_document)
        .map(_ParticipantRecord.fromJson)
        .toList(growable: false);
    final isEditing = _editingParticipantId != null;

    return Dialog(
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
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
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD0D7DE)),
                  ),
                  child: activeParticipants.isEmpty
                      ? const Center(
                          child: Text('Пока нет ни одного участника.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeParticipants.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final participant = activeParticipants[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                    onPressed: () => _startEditing(participant),
                                    child: const Text('Редактировать'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => unawaited(
                                      _deleteParticipant(participant),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('participant_name_field'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя',
                          errorText: _nameError,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => unawaited(_submitParticipant()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isEditing) ...[
                            TextButton(
                              onPressed: _cancelEditing,
                              child: const Text('Отменить редактирование'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          FilledButton(
                            onPressed: () => unawaited(_submitParticipant()),
                            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
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
  }
}

final class _ParticipantRecord {
  const _ParticipantRecord({
    required this.id,
    required this.name,
    required this.deleted,
  });

  factory _ParticipantRecord.fromJson(Map<String, Object?> json) {
    return _ParticipantRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final bool deleted;

  _ParticipantRecord copyWith({
    int? id,
    String? name,
    bool? deleted,
  }) {
    return _ParticipantRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'deleted': deleted,
    };
  }
}
