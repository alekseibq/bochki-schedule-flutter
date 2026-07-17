import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import '../workdays/workday_date_format.dart';
import 'print_preset_params_view_model.dart';

enum PrintGroupBy {
  byNames('По фамилиям'),
  byDates('По времени');

  const PrintGroupBy(this.label);

  final String label;
}

class PrintPresetParamsDialog extends StatefulWidget {
  const PrintPresetParamsDialog({
    required this.viewModel,
    super.key,
  });

  final PrintPresetParamsViewModel viewModel;

  @override
  State<PrintPresetParamsDialog> createState() =>
      _PrintPresetParamsDialogState();
}

class _PrintPresetParamsDialogState extends State<PrintPresetParamsDialog> {
  static const double _dialogWidth = 700;
  static const double _labelColumnWidth = 172;
  static const double _selectFieldWidth = 240;
  static const double _textFieldWidth = 420;

  late final TextEditingController _textBeforeController;
  late final TextEditingController _textAfterController;
  late PrintGroupBy _groupBy;
  String? _selectedWorkdayId;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_handleViewModelChange);
    _groupBy = PrintGroupBy.byNames;
    _textBeforeController = TextEditingController();
    _textAfterController = TextEditingController();
    _applyLoadedValues();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChange);
    _textBeforeController.dispose();
    _textAfterController.dispose();
    super.dispose();
  }

  void _handleViewModelChange() {
    if (!mounted) {
      return;
    }
    _showActionErrorIfNeeded();
    _applyLoadedValues();
  }

  void _showActionErrorIfNeeded() {
    final message = widget.viewModel.actionErrorMessage;
    if (message == null) {
      return;
    }
    widget.viewModel.clearActionError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _applyLoadedValues() {
    if (widget.viewModel.isLoading ||
        widget.viewModel.loadErrorMessage != null) {
      return;
    }

    final params = widget.viewModel.params;
    final nextWorkdayId = widget.viewModel.initialWorkdayId;
    if (_selectedWorkdayId == nextWorkdayId &&
        _textBeforeController.text == params.textBefore &&
        _textAfterController.text == params.textAfter) {
      return;
    }

    _selectedWorkdayId = nextWorkdayId;
    _textBeforeController.text = params.textBefore;
    _textAfterController.text = params.textAfter;
  }

  Future<void> _saveAndClose() async {
    final selectedWorkdayId = _selectedWorkdayId;
    if (selectedWorkdayId == null) {
      return;
    }

    final isSuccess = await widget.viewModel.save(
      workdayId: selectedWorkdayId,
      textBefore: _textBeforeController.text,
      textAfter: _textAfterController.text,
    );
    if (!mounted || !isSuccess) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isActionEnabled =
            !widget.viewModel.isSaving && widget.viewModel.hasAvailableWorkdays;
        return AlertDialog(
          key: const Key('print_preset_params_dialog'),
          title: const Text('Распечатки'),
          content: SizedBox(
            width: _dialogWidth,
            child: widget.viewModel.isLoading ? _buildLoading() : _buildBody(),
          ),
          actions: [
            TextButton(
              key: const Key('print_preset_params_cancel_button'),
              onPressed: widget.viewModel.isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton.tonal(
              key: const Key('print_preset_params_open_button'),
              onPressed: isActionEnabled ? _saveAndClose : null,
              child: const Text('Открыть файл'),
            ),
            FilledButton(
              key: const Key('print_preset_params_save_button'),
              onPressed: isActionEnabled ? _saveAndClose : null,
              child: const Text('Сохранить файл'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody() {
    if (widget.viewModel.loadErrorMessage case final message?) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.viewModel.load,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormRow(
            label: 'Тип распечатки',
            labelWidth: _labelColumnWidth,
            child: SizedBox(
              width: _selectFieldWidth,
              child: DropdownButtonFormField<PrintGroupBy>(
                key: const Key('print_preset_group_by_field'),
                value: _groupBy,
                isExpanded: true,
                items: [
                  for (final option in PrintGroupBy.values)
                    DropdownMenuItem<PrintGroupBy>(
                      value: option,
                      child: Text(option.label),
                    ),
                ],
                onChanged: widget.viewModel.isSaving
                    ? null
                    : (nextValue) {
                        if (nextValue == null) {
                          return;
                        }
                        setState(() {
                          _groupBy = nextValue;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'День',
            labelWidth: _labelColumnWidth,
            child: SizedBox(
              width: _selectFieldWidth,
              child: DropdownButtonFormField<String>(
                key: const Key('print_preset_workday_field'),
                value: _selectedWorkdayId,
                isExpanded: true,
                hint: const Text('Нет доступных дней'),
                items: [
                  for (final workday in widget.viewModel.workdays)
                    DropdownMenuItem<String>(
                      value: workday.id,
                      child: Text(_formatWorkday(workday)),
                    ),
                ],
                onChanged: widget.viewModel.isSaving ||
                        !widget.viewModel.hasAvailableWorkdays
                    ? null
                    : (nextValue) {
                        if (nextValue == null) {
                          return;
                        }
                        setState(() {
                          _selectedWorkdayId = nextValue;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'Текст в начале дня',
            labelWidth: _labelColumnWidth,
            child: SizedBox(
              width: _textFieldWidth,
              child: TextField(
                key: const Key('print_preset_text_before_field'),
                controller: _textBeforeController,
                enabled: !widget.viewModel.isSaving,
                minLines: 2,
                maxLines: 2,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormRow(
            label: 'Текст в конце дня',
            labelWidth: _labelColumnWidth,
            child: SizedBox(
              width: _textFieldWidth,
              child: TextField(
                key: const Key('print_preset_text_after_field'),
                controller: _textAfterController,
                enabled: !widget.viewModel.isSaving,
                minLines: 2,
                maxLines: 2,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWorkday(Workday workday) {
    return '${workday.name} (${formatWorkdayDate(workday.calendarDate)})';
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.labelWidth,
    required this.child,
  });

  final String label;
  final double labelWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(label),
          ),
        ),
        Flexible(child: child),
      ],
    );
  }
}
