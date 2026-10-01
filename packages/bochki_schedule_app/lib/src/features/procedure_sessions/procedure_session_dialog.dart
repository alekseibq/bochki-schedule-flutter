import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_session_schedule_projection.dart';
import '../../domain/procedure_sessions/procedure_session_tooltip_builder.dart';
import '../../domain/procedure_sessions/procedure_session_time.dart';
import '../../domain/procedure_sessions/conflict_resource_type.dart';
import '../../domain/procedure_sessions/schedule_conflict_type.dart';
import '../../domain/workdays/workday.dart';
import 'procedure_session_submit_result.dart';

class ProcedureSessionDialog extends StatefulWidget {
  const ProcedureSessionDialog({
    required this.initialValue,
    required this.workdays,
    required this.humans,
    required this.procedureKinds,
    required this.assistants,
    this.procedureSessions = const [],
    required this.programSettings,
    required this.onSubmit,
    this.onSavedAndRendered,
    this.onClose,
    this.isSaving = false,
    super.key,
  });

  final ProcedureSessionRaw initialValue;
  final List<Workday> workdays;
  final List<Human> humans;
  final List<ProcedureKind> procedureKinds;
  final List<Assistant> assistants;
  final List<ProcedureSessionRaw> procedureSessions;
  final ProgramSettings programSettings;
  final Future<ProcedureSessionSubmitResult> Function(
    ProcedureSessionRaw procedureSession,
    bool allowConflicts,
  ) onSubmit;
  final Future<void> Function(int operationId)? onSavedAndRendered;
  final FutureOr<void> Function()? onClose;
  final bool isSaving;

  bool get isEditing => initialValue.id != 'draft';

  @override
  State<ProcedureSessionDialog> createState() => _ProcedureSessionDialogState();
}

class _ProcedureSessionDialogState extends State<ProcedureSessionDialog> {
  late String _dayId;
  late String? _participantId;
  late String _procedureKindId;
  late String? _assistantId;
  late String _hour;
  late String _minute;
  String? _formErrorText;
  List<String> _conflictMessages = const [];
  String? _confirmedSnapshot;
  bool _isSubmitting = false;

  static const _previewId = '__procedure_session_editor_preview__';
  static const _normalTextColor = Colors.black;
  static const _conflictTextColor = Colors.red;
  final _scheduleProjection = const ProcedureSessionScheduleProjection();
  final _tooltipBuilder = const ProcedureSessionTooltipBuilder();

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

  bool get requiresAssistant =>
      _selectedProcedureKind?.requiresAssistant ?? false;
  bool get _isBusy => widget.isSaving || _isSubmitting;

  List<String> get _hours {
    final hours = [
      for (int hour = widget.programSettings.minimumTime.hour;
          hour <= widget.programSettings.maximumTime.hour;
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
        widget.programSettings.minimumTime.hour.toString().padLeft(2, '0');
    final maximumHour =
        widget.programSettings.maximumTime.hour.toString().padLeft(2, '0');
    return 'Доступные часы начала: $minimumHour-$maximumHour.';
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
      for (final participant in widget.humans)
        DropdownMenuItem<String>(
          value: participant.id,
          child: Text(participant.name,
              style: _resourceTextStyle(
                _hasParticipantConflict(participant.id),
              )),
        ),
    ];
    if (_participantId != null &&
        !items.any((item) => item.value == _participantId)) {
      items.add(
        DropdownMenuItem<String>(
          value: _participantId!,
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
          child: Text(procedureKind.name,
              style: _resourceTextStyle(
                _hasProcedureConflict(procedureKind.id),
              )),
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
          child: Text(_assistantLabel(assistant),
              style: _resourceTextStyle(
                _hasAssistantConflict(assistant.id),
              )),
        ),
    ];
    final currentAssistantId = _assistantId;
    if (currentAssistantId != null &&
        !items.any((item) => item.value == currentAssistantId)) {
      items.add(
        DropdownMenuItem<String>(
          value: currentAssistantId,
          child: Text('Ошибка: сопровождающий не найден ($currentAssistantId)'),
        ),
      );
    }
    return items;
  }

  String _assistantLabel(Assistant assistant) {
    if (!(_selectedProcedureKind?.isCurated ?? false)) {
      return assistant.name;
    }
    final count = _tooltipBuilder.assistantHistoryCount(
      participantId: _participantId,
      assistantId: assistant.id,
      editingSessionId: widget.isEditing ? widget.initialValue.id : '',
      savedSessions: widget.procedureSessions,
      procedureKinds: widget.procedureKinds,
    );
    return count == 0 ? assistant.name : '${assistant.name} (был $count раз)';
  }

  ProcedureSessionRaw get _currentSession => ProcedureSessionRaw(
        id: widget.initialValue.id,
        dayId: _dayId,
        participantId: _participantId,
        startTime: '$_hour:$_minute',
        procedureKindId: _procedureKindId,
        assistantId: requiresAssistant ? _assistantId : null,
      );

  bool get _selectedProcedureHasConflict =>
      _hasProcedureConflict(_procedureKindId);
  bool get _selectedParticipantHasConflict =>
      _participantId != null && _hasParticipantConflict(_participantId!);
  bool get _selectedAssistantHasConflict =>
      _assistantId != null && _hasAssistantConflict(_assistantId!);

  bool _hasProcedureConflict(String procedureKindId) => _hasResourceConflict(
        _currentSession.copyWith(procedureKindId: procedureKindId),
        resourceType: ConflictResourceType.item,
        resourceId: procedureKindId,
      );

  bool _hasParticipantConflict(String humanId) => _hasResourceConflict(
        _currentSession.copyWith(participantId: humanId),
        resourceType: ConflictResourceType.human,
        resourceId: humanId,
      );

  bool _hasAssistantConflict(String humanId) => _hasResourceConflict(
        _currentSession.copyWith(assistantId: humanId),
        resourceType: ConflictResourceType.human,
        resourceId: humanId,
      );

  bool _hasResourceConflict(
    ProcedureSessionRaw candidate, {
    required ConflictResourceType resourceType,
    required String resourceId,
  }) {
    final candidateId = candidate.id == 'draft' ? _previewId : candidate.id;
    final projected = _scheduleProjection.project(
      savedSessions: widget.procedureSessions,
      candidate: candidate,
      candidateId: candidateId,
      workdays: widget.workdays,
      humans: widget.humans,
      procedureKinds: widget.procedureKinds,
      assistants: widget.assistants,
      programSettings: widget.programSettings,
    );
    final entry =
        projected.where((entry) => entry.id == candidateId).firstOrNull;
    return entry?.conflicts.any((conflict) =>
            conflict.type == ScheduleConflictType.resourceOverload &&
            conflict.resourceType == resourceType &&
            conflict.resourceId == resourceId) ??
        false;
  }

  TextStyle _resourceTextStyle(bool hasConflict) => TextStyle(
        color: hasConflict ? _conflictTextColor : _normalTextColor,
      );

  Widget _infoTooltip({
    required Key key,
    required ProcedureSessionTooltipData? data,
    required String emptyMessage,
    required bool hasConflict,
  }) {
    final message = data == null
        ? TextSpan(text: emptyMessage)
        : TextSpan(
            children: [
              TextSpan(
                  text: data.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              for (final line in data.lines)
                TextSpan(
                  text: '\n${line.text}',
                  style: TextStyle(
                      color: switch (line.tone) {
                    ProcedureSessionTooltipTone.conflict => _conflictTextColor,
                    ProcedureSessionTooltipTone.companion =>
                      const Color(0xFF1B5E20),
                    ProcedureSessionTooltipTone.normal => _normalTextColor,
                  }),
                ),
            ],
          );
    return Tooltip(
      richMessage: message,
      child: Icon(
        Icons.info_outline,
        key: key,
        size: 18,
        color: hasConflict ? _conflictTextColor : _normalTextColor,
      ),
    );
  }

  ProcedureSessionTooltipData get _procedureTooltip =>
      _tooltipBuilder.procedureAvailability(
        dayId: _dayId,
        procedureKindId: _procedureKindId,
        editingSessionId: widget.isEditing ? widget.initialValue.id : '',
        savedSessions: widget.procedureSessions,
        workdays: widget.workdays,
        procedureKinds: widget.procedureKinds,
        programSettings: widget.programSettings,
      );

  ProcedureSessionTooltipData? _personTooltip(String? humanId) {
    if (humanId == null) return null;
    final name = [
      for (final human in widget.humans)
        if (human.id == humanId) human.name,
      for (final assistant in widget.assistants)
        if (assistant.id == humanId) assistant.name,
    ].firstOrNull;
    if (name == null) return null;
    return _tooltipBuilder.personSchedule(
      humanId: humanId,
      humanName: name,
      dayId: _dayId,
      savedSessions: widget.procedureSessions,
      workdays: widget.workdays,
      humans: widget.humans,
      procedureKinds: widget.procedureKinds,
      assistants: widget.assistants,
      programSettings: widget.programSettings,
    );
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
    unawaited(_submitAsync());
  }

  Future<void> _submitAsync() async {
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
        _formErrorText = 'Выберите сопровождающего.';
      });
      return;
    }

    final snapshot = _buildSnapshot(procedureSession);
    final allowConflicts = _confirmedSnapshot == snapshot;
    setState(() {
      _isSubmitting = true;
      _formErrorText = null;
    });

    final result = await widget.onSubmit(procedureSession, allowConflicts);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      if (result.didSave) {
        _conflictMessages = const [];
        _confirmedSnapshot = null;
        return;
      }
      if (result.hasConflicts) {
        _conflictMessages = result.conflictMessages;
        _confirmedSnapshot = snapshot;
      } else {
        _conflictMessages = const [];
        _confirmedSnapshot = null;
      }
      _formErrorText = result.errorMessage;
    });

    if (result.didSave) {
      await widget.onSavedAndRendered?.call(result.operationId!);
      await _close();
    }
  }

  Future<void> _close() async {
    final onClose = widget.onClose;
    if (onClose != null) {
      await onClose();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _clearError() {
    if (_formErrorText == null &&
        _conflictMessages.isEmpty &&
        _confirmedSnapshot == null) {
      return;
    }
    setState(() {
      _formErrorText = null;
      _conflictMessages = const [];
      _confirmedSnapshot = null;
    });
  }

  String _buildSnapshot(ProcedureSessionRaw procedureSession) {
    return [
      procedureSession.dayId,
      procedureSession.participantId,
      procedureSession.startTime,
      procedureSession.procedureKindId,
      procedureSession.assistantId ?? '',
    ].join('|');
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
                  onPressed: _isBusy ? null : _openStatisticsPlaceholder,
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
                        onChanged: _isBusy
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
                    _infoTooltip(
                      key: const Key('procedure_session_procedure_kind_info'),
                      data: _procedureTooltip,
                      emptyMessage: '',
                      hasConflict: _selectedProcedureHasConflict,
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
                        hint: const Text('Выберите участника'),
                        isExpanded: true,
                        items: _buildParticipantItems(),
                        onChanged: _isBusy
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
                    _infoTooltip(
                      key: const Key('procedure_session_participant_info'),
                      data: _personTooltip(_participantId),
                      emptyMessage: 'Выберите участника',
                      hasConflict: _selectedParticipantHasConflict,
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
                              onChanged: _isBusy
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _hour = value;
                                        _clearError();
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
                              onChanged: _isBusy
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _minute = value;
                                        _clearError();
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
                        onChanged: _isBusy
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
                label: 'Сопровождающий',
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('procedure_session_assistant_field'),
                        value: _assistantId,
                        isExpanded: true,
                        hint: Text(requiresAssistant
                            ? 'Выберите сопровождающего'
                            : 'Не требуется'),
                        items: _buildAssistantItems(),
                        onChanged: !requiresAssistant || _isBusy
                            ? null
                            : (value) {
                                setState(() {
                                  _assistantId = value;
                                  _clearError();
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _infoTooltip(
                      key: const Key('procedure_session_assistant_info'),
                      data: _personTooltip(_assistantId),
                      emptyMessage: 'Выберите сопровождающего',
                      hasConflict: _selectedAssistantHasConflict,
                    ),
                  ],
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
              if (_conflictMessages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD08A26)),
                    color: const Color(0xFFFFF7E8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Обнаружены конфликты. Повторное сохранение выполнит запись.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      for (final message in _conflictMessages) ...[
                        Text(message),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
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
          onPressed: _isBusy ? null : () => unawaited(_close()),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('procedure_session_save_button'),
          onPressed: _isBusy ? null : _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
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
