import 'package:flutter/material.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_session_time.dart';
import '../../domain/workdays/workday.dart';

class ProcedureSessionDialog extends StatefulWidget {
  const ProcedureSessionDialog({
    required this.initialValue,
    required this.workdays,
    required this.participants,
    required this.procedureKinds,
    required this.assistants,
    required this.programSettings,
    this.isSaving = false,
    super.key,
  });

  final ProcedureSessionRaw initialValue;
  final List<Workday> workdays;
  final List<Human> participants;
  final List<ProcedureKind> procedureKinds;
  final List<Assistant> assistants;
  final ProgramSettings programSettings;
  final bool isSaving;

  bool get isEditing => initialValue.id != 'draft';

  @override
  State<ProcedureSessionDialog> createState() => _ProcedureSessionDialogState();
}

class _ProcedureSessionDialogState extends State<ProcedureSessionDialog> {
  late String _dayId;
  late String _participantId;
  late String _procedureKindId;
  late String? _assistantId;
  late String _hour;
  late String _minute;
  String? _formErrorText;

  static final List<String> _minutes = [
    for (int minute = 0; minute <= 55; minute += 5) '$minute'.padLeft(2, '0'),
  ];

  @override
  void initState() {
    super.initState();
    _dayId = widget.initialValue.dayId;
    _participantId = widget.initialValue.participantId;
    _procedureKindId = widget.initialValue.procedureKindId;
    _assistantId = widget.initialValue.assistantId;
    _hour = widget.initialValue.startTime.substring(0, 2);
    _minute = widget.initialValue.startTime.substring(3, 5);
    if (!requiresAssistant) {
      _assistantId = null;
    }
  }

  ProcedureKind? get _selectedProcedureKind {
    for (final entry in widget.procedureKinds) {
      if (entry.id == _procedureKindId) {
        return entry;
      }
    }
    return null;
  }

  bool get requiresAssistant => _selectedProcedureKind?.isCurated ?? false;

  List<String> get _hours {
    final hours = [
      for (int hour = widget.programSettings.minimumHour;
          hour <= widget.programSettings.maximumHour;
          hour++)
        hour.toString().padLeft(2, '0'),
    ];
    if (!hours.contains(_hour)) {
      hours.add(_hour);
      hours.sort();
    }
    return hours;
  }

  List<String> get _availableMinutes {
    if (_minutes.contains(_minute)) {
      return _minutes;
    }
    final minutes = [..._minutes, _minute]..sort();
    return minutes;
  }

  String get _finishTime {
    final procedureKind = _selectedProcedureKind;
    if (procedureKind == null) {
      return 'ошибка';
    }
    return ProcedureSessionTime.fromMinutes(
      ProcedureSessionTime.toMinutes('$_hour:$_minute') +
          procedureKind.participantBusyTime,
    );
  }

  String get _scheduleHint {
    final minimumHour =
        widget.programSettings.minimumHour.toString().padLeft(2, '0');
    final maximumHour =
        widget.programSettings.maximumHour.toString().padLeft(2, '0');
    return 'Допустимое время начала: $minimumHour:00-$maximumHour:55. '
        'Обед: с ${_formatSettingsTime(widget.programSettings.lunchStart)} '
        'до ${_formatSettingsTime(widget.programSettings.lunchEnd)}.';
  }

  List<DropdownMenuItem<String>> _buildWorkdayItems() {
    final items = [
      for (final workday in widget.workdays)
        DropdownMenuItem<String>(
          value: workday.id,
          child: Text(workday.name),
        ),
    ];
    if (!items.any((item) => item.value == _dayId)) {
      items.add(
        DropdownMenuItem<String>(
          value: _dayId,
          child: Text('Ошибка: день не найден ($_dayId)'),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildParticipantItems() {
    final items = [
      for (final participant in widget.participants)
        DropdownMenuItem<String>(
          value: participant.id,
          child: Text(participant.name),
        ),
    ];
    if (!items.any((item) => item.value == _participantId)) {
      items.add(
        DropdownMenuItem<String>(
          value: _participantId,
          child: Text('Ошибка: участник не найден ($_participantId)'),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildProcedureKindItems() {
    final items = [
      for (final procedureKind in widget.procedureKinds)
        DropdownMenuItem<String>(
          value: procedureKind.id,
          child: Text(procedureKind.name),
        ),
    ];
    if (!items.any((item) => item.value == _procedureKindId)) {
      items.add(
        DropdownMenuItem<String>(
          value: _procedureKindId,
          child: Text('Ошибка: процедура не найдена ($_procedureKindId)'),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildAssistantItems() {
    final items = [
      for (final assistant in widget.assistants)
        DropdownMenuItem<String>(
          value: assistant.id,
          child: Text(assistant.name),
        ),
    ];
    final currentAssistantId = _assistantId;
    if (currentAssistantId != null &&
        !items.any((item) => item.value == currentAssistantId)) {
      items.add(
        DropdownMenuItem<String>(
          value: currentAssistantId,
          child: Text('Ошибка: ассистент не найден ($currentAssistantId)'),
        ),
      );
    }
    return items;
  }

  Future<void> _openStatisticsPlaceholder() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Статистика процедур'),
          content: const Text('Заглушка. Здесь будет отдельная статистика.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    final procedureSession = ProcedureSessionRaw(
      id: widget.initialValue.id,
      dayId: _dayId,
      participantId: _participantId,
      startTime: '$_hour:$_minute',
      procedureKindId: _procedureKindId,
      assistantId: requiresAssistant ? _assistantId : null,
    );

    if (requiresAssistant && procedureSession.assistantId == null) {
      setState(() {
        _formErrorText = 'Выберите ассистента.';
      });
      return;
    }

    Navigator.of(context).pop(procedureSession);
  }

  void _clearError() {
    if (_formErrorText == null) {
      return;
    }
    setState(() {
      _formErrorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: Key(
        widget.isEditing
            ? 'procedure_session_edit_dialog'
            : 'procedure_session_create_dialog',
      ),
      title: Text(
        widget.isEditing
            ? 'Редактирование назначенной процедуры'
            : 'Новая назначенная процедура',
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const Key('procedure_statistics_button'),
                  onPressed:
                      widget.isSaving ? null : _openStatisticsPlaceholder,
                  child: const Text('Открыть статистику процедур'),
                ),
              ),
              const SizedBox(height: 16),
              _DialogRow(
                label: 'Процедура',
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key:
                            const Key('procedure_session_procedure_kind_field'),
                        value: _procedureKindId,
                        isExpanded: true,
                        items: _buildProcedureKindItems(),
                        onChanged: widget.isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _procedureKindId = value;
                                  if (!requiresAssistant) {
                                    _assistantId = null;
                                  }
                                  _clearError();
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message:
                          'Информация о процедуре будет показана в следующем инкременте.',
                      child: Icon(Icons.info_outline, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DialogRow(
                label: 'Участник',
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('procedure_session_participant_field'),
                        value: _participantId,
                        isExpanded: true,
                        items: _buildParticipantItems(),
                        onChanged: widget.isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _participantId = value;
                                  _clearError();
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message:
                          'Информация об участнике будет показана в следующем инкременте.',
                      child: Icon(Icons.info_outline, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _scheduleHint,
                key: const Key('procedure_session_schedule_hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DialogRow(
                      label: 'Время начала',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: DropdownButtonFormField<String>(
                              key: const Key('procedure_session_hour_field'),
                              value: _hour,
                              isExpanded: true,
                              items: [
                                for (final hour in _hours)
                                  DropdownMenuItem<String>(
                                    value: hour,
                                    child: Text(hour),
                                  ),
                              ],
                              onChanged: widget.isSaving
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _hour = value;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 88,
                            child: DropdownButtonFormField<String>(
                              key: const Key('procedure_session_minute_field'),
                              value: _minute,
                              isExpanded: true,
                              items: [
                                for (final minute in _availableMinutes)
                                  DropdownMenuItem<String>(
                                    value: minute,
                                    child: Text(minute),
                                  ),
                              ],
                              onChanged: widget.isSaving
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _minute = value;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _DialogRow(
                      label: 'День',
                      child: DropdownButtonFormField<String>(
                        key: const Key('procedure_session_day_field'),
                        value: _dayId,
                        isExpanded: true,
                        items: _buildWorkdayItems(),
                        onChanged: widget.isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _dayId = value;
                                  _clearError();
                                });
                              },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DialogRow(
                label: 'Ассистент',
                child: DropdownButtonFormField<String>(
                  key: const Key('procedure_session_assistant_field'),
                  value: _assistantId,
                  isExpanded: true,
                  hint: Text(requiresAssistant
                      ? 'Выберите ассистента'
                      : 'Не требуется'),
                  items: _buildAssistantItems(),
                  onChanged: !requiresAssistant || widget.isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _assistantId = value;
                            _clearError();
                          });
                        },
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Дополнительная информация',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                  color: const Color(0xFFF8FAFC),
                ),
                child: Text('Время окончания процедуры: $_finishTime'),
              ),
              if (_formErrorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formErrorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('procedure_session_save_button'),
          onPressed: widget.isSaving ? null : _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  String _formatSettingsTime(ProgramSettingsTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(label),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
