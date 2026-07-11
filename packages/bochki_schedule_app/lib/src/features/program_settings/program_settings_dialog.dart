import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/material.dart';

import 'program_settings_view_model.dart';

class ProgramSettingsDialog extends StatefulWidget {
  const ProgramSettingsDialog({
    required this.viewModel,
    super.key,
  });

  final ProgramSettingsViewModel viewModel;

  @override
  State<ProgramSettingsDialog> createState() => _ProgramSettingsDialogState();
}

class _ProgramSettingsDialogState extends State<ProgramSettingsDialog> {
  late int _lunchStartHour;
  late int _lunchStartMinute;
  late int _lunchEndHour;
  late int _lunchEndMinute;
  late int _minimumHour;
  late int _maximumHour;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_showActionErrorIfNeeded);
    final settings = widget.viewModel.settings ?? ProgramSettings.defaults;
    _applySettings(settings);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showActionErrorIfNeeded);
    super.dispose();
  }

  void _applySettings(ProgramSettings settings) {
    _lunchStartHour = settings.lunchStart.hour;
    _lunchStartMinute = settings.lunchStart.minute;
    _lunchEndHour = settings.lunchEnd.hour;
    _lunchEndMinute = settings.lunchEnd.minute;
    _minimumHour = settings.minimumHour;
    _maximumHour = settings.maximumHour;
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

  void _updateField(void Function() mutate) {
    setState(mutate);
    widget.viewModel.clearFormError();
  }

  Future<void> _save() async {
    final settings = ProgramSettings(
      lunchStart: ProgramSettingsTime(
        hour: _lunchStartHour,
        minute: _lunchStartMinute,
      ),
      lunchEnd: ProgramSettingsTime(
        hour: _lunchEndHour,
        minute: _lunchEndMinute,
      ),
      minimumHour: _minimumHour,
      maximumHour: _maximumHour,
    );

    final isSuccess = await widget.viewModel.saveProgramSettings(settings);
    if (!mounted || !isSuccess) {
      return;
    }

    Navigator.of(context).pop(settings);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return AlertDialog(
          key: const Key('program_settings_dialog'),
          title: const Text('Настройки'),
          content: SizedBox(
            width: 520,
            child: widget.viewModel.isLoading ? _buildLoading() : _buildBody(),
          ),
          actions: [
            TextButton(
              onPressed: widget.viewModel.isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              key: const Key('program_settings_save_button'),
              onPressed: widget.viewModel.isSaving ? null : _save,
              child: const Text('Сохранить'),
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
                onPressed: widget.viewModel.loadProgramSettings,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimeRow(
                  label: 'Начало обеда',
                  hourKey: const Key('program_settings_lunch_start_hour_field'),
                  minuteKey: const Key(
                    'program_settings_lunch_start_minute_field',
                  ),
                  selectedHour: _lunchStartHour,
                  selectedMinute: _lunchStartMinute,
                  onHourChanged: (value) =>
                      _updateField(() => _lunchStartHour = value),
                  onMinuteChanged: (value) =>
                      _updateField(() => _lunchStartMinute = value),
                ),
                const SizedBox(height: 16),
                _buildTimeRow(
                  label: 'Конец обеда',
                  hourKey: const Key('program_settings_lunch_end_hour_field'),
                  minuteKey: const Key(
                    'program_settings_lunch_end_minute_field',
                  ),
                  selectedHour: _lunchEndHour,
                  selectedMinute: _lunchEndMinute,
                  onHourChanged: (value) =>
                      _updateField(() => _lunchEndHour = value),
                  onMinuteChanged: (value) =>
                      _updateField(() => _lunchEndMinute = value),
                ),
                const SizedBox(height: 16),
                _buildHourField(
                  label: 'Минимальное время',
                  fieldKey: const Key('program_settings_minimum_hour_field'),
                  selectedHour: _minimumHour,
                  onChanged: (value) =>
                      _updateField(() => _minimumHour = value),
                ),
                const SizedBox(height: 16),
                _buildHourField(
                  label: 'Максимальное время',
                  fieldKey: const Key('program_settings_maximum_hour_field'),
                  selectedHour: _maximumHour,
                  onChanged: (value) =>
                      _updateField(() => _maximumHour = value),
                ),
                if (widget.viewModel.formErrorMessage case final message?) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    key: const Key('program_settings_form_error'),
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required String label,
    required Key hourKey,
    required Key minuteKey,
    required int selectedHour,
    required int selectedMinute,
    required ValueChanged<int> onHourChanged,
    required ValueChanged<int> onMinuteChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<int>(
                fieldKey: hourKey,
                value: selectedHour,
                items: List<int>.generate(24, (index) => index),
                formatter: _formatHour,
                onChanged: onHourChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<int>(
                fieldKey: minuteKey,
                value: selectedMinute,
                items: List<int>.generate(6, (index) => index * 10),
                formatter: _formatHour,
                onChanged: onMinuteChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHourField({
    required String label,
    required Key fieldKey,
    required int selectedHour,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        _buildDropdown<int>(
          fieldKey: fieldKey,
          value: selectedHour,
          items: List<int>.generate(24, (index) => index),
          formatter: _formatHour,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required Key fieldKey,
    required T value,
    required List<T> items,
    required String Function(T value) formatter,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: fieldKey,
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(formatter(item)),
          ),
      ],
      onChanged: widget.viewModel.isSaving
          ? null
          : (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
    );
  }

  String _formatHour(int value) => value.toString().padLeft(2, '0');
}
