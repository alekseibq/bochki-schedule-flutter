import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_kinds/procedure_kind_pattern.dart';
import 'procedure_kinds_view_model.dart';

class ProcedureKindDialog extends StatefulWidget {
  const ProcedureKindDialog({
    required this.viewModel,
    required this.procedureKinds,
    this.initialProcedureKind,
    this.onSaved,
    this.onCancel,
    this.formSession = 0,
    this.windowMode = false,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;
  final List<ProcedureKind> procedureKinds;
  final ProcedureKind? initialProcedureKind;
  final Future<void> Function(ProcedureKind procedureKind)? onSaved;
  final VoidCallback? onCancel;

  /// Changes only when the editor is opened again, not when its data refreshes.
  final int formSession;
  final bool windowMode;

  bool get isEditing => initialProcedureKind != null;

  @override
  State<ProcedureKindDialog> createState() => _ProcedureKindDialogState();
}

class _ProcedureKindDialogState extends State<ProcedureKindDialog> {
  static const double _labelColumnWidth = 172;
  static const double _numericFieldWidth = 72;

  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _participantBusyTimeController;
  late final TextEditingController _assistantBusyTimeController;
  late final TextEditingController _resourceBusyTimeController;
  late final ScrollController _scrollController;

  late String _patternId;

  bool get _isCurated => _patternId == ProcedureKindPatterns.curated.patternId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shortNameController = TextEditingController();
    _capacityController = TextEditingController();
    _participantBusyTimeController = TextEditingController();
    _assistantBusyTimeController = TextEditingController();
    _resourceBusyTimeController = TextEditingController();
    _scrollController = ScrollController();
    _initializeForm();
  }

  @override
  void didUpdateWidget(covariant ProcedureKindDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formSession != oldWidget.formSession) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final initialProcedureKind = widget.initialProcedureKind;
    _patternId = initialProcedureKind?.patternId ??
        ProcedureKindPatterns.curated.patternId;
    _nameController.text = initialProcedureKind?.name ?? '';
    _shortNameController.text = initialProcedureKind == null ||
            initialProcedureKind.shortName == initialProcedureKind.name
        ? ''
        : initialProcedureKind.shortName;
    _capacityController.text =
        initialProcedureKind == null ? '1' : '${initialProcedureKind.capacity}';
    _participantBusyTimeController.text =
        initialProcedureKind?.participantBusyTime.toString() ?? '';
    _assistantBusyTimeController.text =
        initialProcedureKind?.assistantBusyTime?.toString() ?? '';
    _resourceBusyTimeController.text =
        initialProcedureKind?.resourceBusyTime?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _capacityController.dispose();
    _participantBusyTimeController.dispose();
    _assistantBusyTimeController.dispose();
    _resourceBusyTimeController.dispose();
    _scrollController.dispose();
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
    controller.text = '$nextValue';
    widget.viewModel.clearFormError();
  }

  Future<void> _showPopularValues({
    required TextEditingController controller,
    required Iterable<int?> values,
    required String fieldName,
  }) async {
    final popularValues = values.whereType<int>().toSet().toList()..sort();
    final selectedValue = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Популярные значения: $fieldName'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in popularValues)
              OutlinedButton(
                key: Key('procedure_kind_${fieldName}_suggestion_$value'),
                onPressed: () => Navigator.of(context).pop(value),
                child: Text('$value'),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: Key('procedure_kind_${fieldName}_suggestion_skip'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (selectedValue == null) {
      return;
    }
    controller.text = '$selectedValue';
    widget.viewModel.clearFormError();
  }

  Future<void> _submit() async {
    final savedProcedureKind = widget.isEditing
        ? await widget.viewModel.updateProcedureKind(
            procedureKindId: widget.initialProcedureKind!.id,
            patternId: _patternId,
            rawName: _nameController.text,
            rawShortName: _shortNameController.text,
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
            rawShortName: _shortNameController.text,
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

    if (widget.onSaved case final callback?) {
      await callback(savedProcedureKind);
      return;
    }
    Navigator.of(context).pop(savedProcedureKind);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final formGap = 12 * scale;
        final contentWidth =
            (MediaQuery.sizeOf(context).width - (widget.windowMode ? 16 : 128))
                .clamp(0.0, double.infinity)
                .toDouble();
        final isNarrowLayout = !widget.windowMode && contentWidth < 520;

        return AlertDialog(
          key: Key(
            widget.isEditing
                ? 'procedure_kind_edit_dialog'
                : 'procedure_kind_create_dialog',
          ),
          title: widget.windowMode
              ? null
              : Text(
                  widget.isEditing
                      ? 'Редактирование процедуры'
                      : 'Новая процедура',
                ),
          insetPadding: widget.windowMode ? EdgeInsets.zero : null,
          alignment: widget.windowMode ? Alignment.topCenter : null,
          contentPadding: widget.windowMode ? EdgeInsets.all(8 * scale) : null,
          actionsPadding: widget.windowMode
              ? EdgeInsets.fromLTRB(8 * scale, 0, 8 * scale, 8 * scale)
              : null,
          content: SizedBox(
            width: contentWidth,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormRow(
                      label: 'Тип процедуры',
                      labelWidth: _labelColumnWidth,
                      isNarrowLayout: isNarrowLayout,
                      child: SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          key: const Key('procedure_kind_pattern_field'),
                          value: _patternId,
                          isExpanded: true,
                          items: [
                            for (final pattern in ProcedureKindPatterns.values)
                              DropdownMenuItem<String>(
                                value: pattern.patternId,
                                child: Text(pattern.longName),
                              ),
                          ],
                          onChanged:
                              widget.viewModel.isSaving ? null : _setPatternId,
                        ),
                      ),
                    ),
                    SizedBox(height: formGap),
                    _FormRow(
                      label: 'Название',
                      labelWidth: _labelColumnWidth,
                      isNarrowLayout: isNarrowLayout,
                      child: TextField(
                        key: const Key('procedure_kind_name_field'),
                        controller: _nameController,
                        enabled: !widget.viewModel.isSaving,
                        onChanged: (_) => widget.viewModel.clearFormError(),
                      ),
                    ),
                    SizedBox(height: formGap),
                    _FormRow(
                      label: 'Краткое название',
                      labelWidth: _labelColumnWidth,
                      isNarrowLayout: isNarrowLayout,
                      child: TextField(
                        key: const Key('procedure_kind_short_name_field'),
                        controller: _shortNameController,
                        enabled: !widget.viewModel.isSaving,
                        onChanged: (_) => widget.viewModel.clearFormError(),
                      ),
                    ),
                    SizedBox(height: formGap),
                    _FormRow(
                      label: 'Емкость',
                      labelWidth: _labelColumnWidth,
                      isNarrowLayout: isNarrowLayout,
                      child: _NumericField(
                        fieldKey: const Key('procedure_kind_capacity_field'),
                        controller: _capacityController,
                        enabled: !widget.viewModel.isSaving,
                        fieldWidth: _numericFieldWidth,
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
                    ),
                    SizedBox(height: formGap),
                    _FormRow(
                      label: 'Время участника (мин)',
                      labelWidth: _labelColumnWidth,
                      isNarrowLayout: isNarrowLayout,
                      child: _NumericField(
                        fieldKey: const Key(
                          'procedure_kind_participant_busy_time_field',
                        ),
                        controller: _participantBusyTimeController,
                        enabled: !widget.viewModel.isSaving,
                        fieldWidth: _numericFieldWidth,
                        onChanged: () => widget.viewModel.clearFormError(),
                        onIncrement: () => _adjustNumericField(
                          _participantBusyTimeController,
                          1,
                        ),
                        onDecrement: () => _adjustNumericField(
                          _participantBusyTimeController,
                          -1,
                        ),
                        onShowPopularValues: () => _showPopularValues(
                          controller: _participantBusyTimeController,
                          values: widget.procedureKinds.map(
                            (procedureKind) =>
                                procedureKind.participantBusyTime,
                          ),
                          fieldName: 'participant_busy_time',
                        ),
                      ),
                    ),
                    if (_isCurated) ...[
                      SizedBox(height: formGap),
                      _FormRow(
                        label: 'Время сопровождающего (мин)',
                        labelWidth: _labelColumnWidth,
                        isNarrowLayout: isNarrowLayout,
                        child: _NumericField(
                          fieldKey: const Key(
                            'procedure_kind_assistant_busy_time_field',
                          ),
                          controller: _assistantBusyTimeController,
                          enabled: !widget.viewModel.isSaving,
                          fieldWidth: _numericFieldWidth,
                          onChanged: () => widget.viewModel.clearFormError(),
                          onIncrement: () => _adjustNumericField(
                            _assistantBusyTimeController,
                            1,
                          ),
                          onDecrement: () => _adjustNumericField(
                            _assistantBusyTimeController,
                            -1,
                          ),
                          onShowPopularValues: () => _showPopularValues(
                            controller: _assistantBusyTimeController,
                            values: widget.procedureKinds.map(
                              (procedureKind) =>
                                  procedureKind.assistantBusyTime,
                            ),
                            fieldName: 'assistant_busy_time',
                          ),
                        ),
                      ),
                      SizedBox(height: formGap),
                      _FormRow(
                        label: 'Время ресурса (мин)',
                        labelWidth: _labelColumnWidth,
                        isNarrowLayout: isNarrowLayout,
                        child: _NumericField(
                          fieldKey: const Key(
                            'procedure_kind_resource_busy_time_field',
                          ),
                          controller: _resourceBusyTimeController,
                          enabled: !widget.viewModel.isSaving,
                          fieldWidth: _numericFieldWidth,
                          onChanged: () => widget.viewModel.clearFormError(),
                          onIncrement: () => _adjustNumericField(
                            _resourceBusyTimeController,
                            1,
                          ),
                          onDecrement: () => _adjustNumericField(
                            _resourceBusyTimeController,
                            -1,
                          ),
                          onShowPopularValues: () => _showPopularValues(
                            controller: _resourceBusyTimeController,
                            values: widget.procedureKinds.map(
                              (procedureKind) => procedureKind.resourceBusyTime,
                            ),
                            fieldName: 'resource_busy_time',
                          ),
                        ),
                      ),
                    ],
                    if (widget.viewModel.formErrorMessage
                        case final message?) ...[
                      SizedBox(height: formGap),
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
          ),
          actions: [
            TextButton(
              onPressed: widget.viewModel.isSaving
                  ? null
                  : () {
                      if (widget.onCancel case final callback?) {
                        callback();
                        return;
                      }
                      Navigator.of(context).pop();
                    },
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

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.labelWidth,
    required this.isNarrowLayout,
    required this.child,
  });

  final String label;
  final double labelWidth;
  final bool isNarrowLayout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);

    if (isNarrowLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 4 * scale),
          child,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth * scale,
          child: Padding(
            padding: EdgeInsets.only(right: 16 * scale),
            child: Text(label, textAlign: TextAlign.right),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.fieldWidth,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
    this.onShowPopularValues,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final double fieldWidth;
  final VoidCallback onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onShowPopularValues;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: fieldWidth * scale,
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              isDense: true,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        SizedBox(width: 8 * scale),
        IconButton(
          key: Key('${fieldKey}_decrement'),
          onPressed: enabled ? onDecrement : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Уменьшить',
        ),
        IconButton(
          key: Key('${fieldKey}_increment'),
          onPressed: enabled ? onIncrement : null,
          icon: const Icon(Icons.add),
          tooltip: 'Увеличить',
        ),
        if (onShowPopularValues case final callback?)
          IconButton(
            key: Key('${fieldKey}_popular_values'),
            onPressed: enabled ? callback : null,
            icon: const Icon(Icons.history),
            tooltip: 'Популярные значения',
          ),
      ],
    );
  }
}
