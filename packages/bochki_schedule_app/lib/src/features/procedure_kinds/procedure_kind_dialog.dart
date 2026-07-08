import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_kinds/procedure_kind_pattern.dart';
import 'procedure_kinds_view_model.dart';

class ProcedureKindDialog extends StatefulWidget {
  const ProcedureKindDialog({
    required this.viewModel,
    this.initialProcedureKind,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;
  final ProcedureKind? initialProcedureKind;

  bool get isEditing => initialProcedureKind != null;

  @override
  State<ProcedureKindDialog> createState() => _ProcedureKindDialogState();
}

class _ProcedureKindDialogState extends State<ProcedureKindDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _participantBusyTimeController;
  late final TextEditingController _assistantBusyTimeController;
  late final TextEditingController _resourceBusyTimeController;

  late String _patternId;

  bool get _isCurated => _patternId == ProcedureKindPatterns.curated.patternId;

  @override
  void initState() {
    super.initState();
    final initialProcedureKind = widget.initialProcedureKind;
    _patternId = initialProcedureKind?.patternId ??
        ProcedureKindPatterns.curated.patternId;
    _nameController = TextEditingController(text: initialProcedureKind?.name);
    _capacityController = TextEditingController(
      text: initialProcedureKind == null
          ? ''
          : '${initialProcedureKind.capacity}',
    );
    _participantBusyTimeController = TextEditingController(
      text: initialProcedureKind == null
          ? ''
          : '${initialProcedureKind.participantBusyTime}',
    );
    _assistantBusyTimeController = TextEditingController(
      text: initialProcedureKind?.assistantBusyTime?.toString() ?? '',
    );
    _resourceBusyTimeController = TextEditingController(
      text: initialProcedureKind?.resourceBusyTime?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _participantBusyTimeController.dispose();
    _assistantBusyTimeController.dispose();
    _resourceBusyTimeController.dispose();
    super.dispose();
  }

  void _setPatternId(String? nextPatternId) {
    if (nextPatternId == null || nextPatternId == _patternId) {
      return;
    }

    setState(() {
      _patternId = nextPatternId;
      if (!_isCurated) {
        _assistantBusyTimeController.clear();
        _resourceBusyTimeController.clear();
      }
    });
    widget.viewModel.clearFormError();
  }

  void _adjustNumericField(TextEditingController controller, int delta) {
    final currentValue = int.tryParse(controller.text) ?? 0;
    final nextValue = currentValue + delta;
    if (nextValue < 0 || nextValue > 999) {
      return;
    }
    controller.text = nextValue == 0 ? '' : '$nextValue';
    widget.viewModel.clearFormError();
  }

  Future<void> _submit() async {
    final savedProcedureKind = widget.isEditing
        ? await widget.viewModel.updateProcedureKind(
            procedureKindId: widget.initialProcedureKind!.id,
            patternId: _patternId,
            rawName: _nameController.text,
            rawCapacity: _capacityController.text,
            rawParticipantBusyTime: _participantBusyTimeController.text,
            rawAssistantBusyTime:
                _isCurated ? _assistantBusyTimeController.text : null,
            rawResourceBusyTime:
                _isCurated ? _resourceBusyTimeController.text : null,
          )
        : await widget.viewModel.createProcedureKind(
            patternId: _patternId,
            rawName: _nameController.text,
            rawCapacity: _capacityController.text,
            rawParticipantBusyTime: _participantBusyTimeController.text,
            rawAssistantBusyTime:
                _isCurated ? _assistantBusyTimeController.text : null,
            rawResourceBusyTime:
                _isCurated ? _resourceBusyTimeController.text : null,
          );
    if (!mounted || savedProcedureKind == null) {
      return;
    }

    Navigator.of(context).pop(savedProcedureKind);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return AlertDialog(
          key: Key(
            widget.isEditing
                ? 'procedure_kind_edit_dialog'
                : 'procedure_kind_create_dialog',
          ),
          title: Text(
            widget.isEditing ? 'Редактирование процедуры' : 'Новая процедура',
          ),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('procedure_kind_pattern_field'),
                    value: _patternId,
                    decoration: const InputDecoration(
                      labelText: 'Тип процедуры',
                    ),
                    items: [
                      for (final pattern in ProcedureKindPatterns.values)
                        DropdownMenuItem<String>(
                          value: pattern.patternId,
                          child: Text(pattern.longName),
                        ),
                    ],
                    onChanged: widget.viewModel.isSaving ? null : _setPatternId,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('procedure_kind_name_field'),
                    controller: _nameController,
                    enabled: !widget.viewModel.isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                    ),
                    onChanged: (_) => widget.viewModel.clearFormError(),
                  ),
                  const SizedBox(height: 12),
                  _NumericField(
                    fieldKey: const Key('procedure_kind_capacity_field'),
                    label: 'Емкость',
                    controller: _capacityController,
                    enabled: !widget.viewModel.isSaving,
                    onChanged: () => widget.viewModel.clearFormError(),
                    onIncrement: () => _adjustNumericField(
                      _capacityController,
                      1,
                    ),
                    onDecrement: () => _adjustNumericField(
                      _capacityController,
                      -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NumericField(
                    fieldKey: const Key(
                      'procedure_kind_participant_busy_time_field',
                    ),
                    label: 'Время участника (мин)',
                    controller: _participantBusyTimeController,
                    enabled: !widget.viewModel.isSaving,
                    onChanged: () => widget.viewModel.clearFormError(),
                    onIncrement: () => _adjustNumericField(
                      _participantBusyTimeController,
                      1,
                    ),
                    onDecrement: () => _adjustNumericField(
                      _participantBusyTimeController,
                      -1,
                    ),
                  ),
                  if (_isCurated) ...[
                    const SizedBox(height: 12),
                    _NumericField(
                      fieldKey: const Key(
                        'procedure_kind_assistant_busy_time_field',
                      ),
                      label: 'Время ассистента (мин)',
                      controller: _assistantBusyTimeController,
                      enabled: !widget.viewModel.isSaving,
                      onChanged: () => widget.viewModel.clearFormError(),
                      onIncrement: () => _adjustNumericField(
                        _assistantBusyTimeController,
                        1,
                      ),
                      onDecrement: () => _adjustNumericField(
                        _assistantBusyTimeController,
                        -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NumericField(
                      fieldKey: const Key(
                        'procedure_kind_resource_busy_time_field',
                      ),
                      label: 'Время ресурса (мин)',
                      controller: _resourceBusyTimeController,
                      enabled: !widget.viewModel.isSaving,
                      onChanged: () => widget.viewModel.clearFormError(),
                      onIncrement: () => _adjustNumericField(
                        _resourceBusyTimeController,
                        1,
                      ),
                      onDecrement: () => _adjustNumericField(
                        _resourceBusyTimeController,
                        -1,
                      ),
                    ),
                  ],
                  if (widget.viewModel.formErrorMessage
                      case final message?) ...[
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: widget.viewModel.isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: widget.viewModel.isSaving ? null : _submit,
              child: Text(widget.isEditing ? 'Сохранить' : 'Создать'),
            ),
          ],
        );
      },
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(labelText: label),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              key: Key('${fieldKey}_increment'),
              onPressed: enabled ? onIncrement : null,
              icon: const Icon(Icons.add),
              tooltip: 'Увеличить',
            ),
            IconButton(
              key: Key('${fieldKey}_decrement'),
              onPressed: enabled ? onDecrement : null,
              icon: const Icon(Icons.remove),
              tooltip: 'Уменьшить',
            ),
          ],
        ),
      ],
    );
  }
}
