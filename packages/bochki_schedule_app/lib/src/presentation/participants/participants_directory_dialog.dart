import 'dart:async';

import 'package:flutter/material.dart';

class ParticipantsDirectoryDialog extends StatefulWidget {
  const ParticipantsDirectoryDialog({
    required this.participants,
    required this.nextId,
    required this.onChanged,
    super.key,
  });

  final List<Map<String, Object?>> participants;
  final int nextId;
  final Future<void> Function(
    List<Map<String, Object?>>,
    int nextId,
  ) onChanged;

  @override
  State<ParticipantsDirectoryDialog> createState() =>
      _ParticipantsDirectoryDialogState();
}

class _ParticipantsDirectoryDialogState
    extends State<ParticipantsDirectoryDialog> {
  final TextEditingController _nameController = TextEditingController();

  late List<_ParticipantRecord> _participants;
  late int _nextId;
  int? _editingParticipantId;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _participants = widget.participants
        .map(_ParticipantRecord.fromJson)
        .toList(growable: true);
    _nextId = widget.nextId;
    _participants.sort(_compareParticipantsByName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static int _compareParticipantsByName(
    _ParticipantRecord left,
    _ParticipantRecord right,
  ) {
    return _normalizedSortKey(left.name)
        .compareTo(_normalizedSortKey(right.name));
  }

  static String _normalizedSortKey(String value) {
    return _normalizeName(value).toLowerCase();
  }

  static String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<_ParticipantRecord> get _activeParticipants {
    final activeParticipants = _participants
        .where((participant) => !participant.deleted)
        .toList(growable: false);
    activeParticipants.sort(_compareParticipantsByName);
    return activeParticipants;
  }

  Future<void> _persistChanges() async {
    await widget.onChanged(
      _participants.map((participant) => participant.toJson()).toList(
            growable: false,
          ),
      _nextId,
    );
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

  bool _hasDuplicateName(String normalizedName) {
    final normalizedCandidate = normalizedName.toLowerCase();
    return _participants.any((participant) {
      if (participant.deleted) {
        return false;
      }
      if (participant.id == _editingParticipantId) {
        return false;
      }
      return _normalizedSortKey(participant.name) == normalizedCandidate;
    });
  }

  Future<void> _submitParticipant() async {
    final normalizedName = _normalizeName(_nameController.text);
    if (normalizedName.isEmpty) {
      setState(() {
        _nameError = 'Введите имя участника.';
      });
      return;
    }

    if (_hasDuplicateName(normalizedName)) {
      setState(() {
        _nameError = 'Участник с таким именем уже есть.';
      });
      return;
    }

    setState(() {
      if (_editingParticipantId == null) {
        _participants.add(
          _ParticipantRecord(
            id: _nextId,
            name: normalizedName,
            deleted: false,
          ),
        );
        _nextId += 1;
      } else {
        final index = _participants.indexWhere(
          (participant) => participant.id == _editingParticipantId,
        );
        if (index != -1) {
          _participants[index] = _participants[index].copyWith(
            name: normalizedName,
          );
        }
      }

      _editingParticipantId = null;
      _nameController.clear();
      _nameError = null;
      _participants.sort(_compareParticipantsByName);
    });

    await _persistChanges();
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

    setState(() {
      final index = _participants.indexWhere(
        (candidate) => candidate.id == participant.id,
      );
      if (index != -1) {
        _participants[index] = _participants[index].copyWith(deleted: true);
      }
      if (_editingParticipantId == participant.id) {
        _editingParticipantId = null;
        _nameController.clear();
        _nameError = null;
      }
    });

    await _persistChanges();
  }

  @override
  Widget build(BuildContext context) {
    final activeParticipants = _activeParticipants;
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
