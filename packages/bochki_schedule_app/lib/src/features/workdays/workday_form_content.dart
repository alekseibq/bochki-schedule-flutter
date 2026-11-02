import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_date_format.dart';
import 'workdays_view_model.dart';

/// Reusable workday editor body; dialog and child-window hosts provide chrome.
class WorkdayFormContent extends StatefulWidget {
  const WorkdayFormContent({
    required this.viewModel,
    required this.initialWorkday,
    required this.isEditing,
    required this.onSaved,
    required this.onCancel,
    super.key,
  });

  final WorkdaysViewModel viewModel;
  final Workday initialWorkday;
  final bool isEditing;
  final ValueChanged<Workday> onSaved;
  final VoidCallback onCancel;

  @override
  State<WorkdayFormContent> createState() => _WorkdayFormContentState();
}

class _WorkdayFormContentState extends State<WorkdayFormContent> {
  late final TextEditingController _name;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialWorkday.name);
    _date = widget.initialWorkday.calendarDate;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
      widget.viewModel.clearFormError();
    }
  }

  Future<void> _submit() async {
    final result = widget.isEditing
        ? await widget.viewModel.updateWorkday(
            workdayId: widget.initialWorkday.id,
            rawName: _name.text,
            rawCalendarDate: formatWorkdayDate(_date),
          )
        : await widget.viewModel.createWorkday(
            rawName: _name.text,
            rawCalendarDate: formatWorkdayDate(_date),
          );
    if (result != null && mounted) widget.onSaved(result);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.viewModel,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('workday_name_field'),
              controller: _name,
              enabled: !widget.viewModel.isSaving,
              maxLength: 20,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (_) => widget.viewModel.clearFormError(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('workday_date_field'),
              onPressed: widget.viewModel.isSaving ? null : _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(formatWorkdayDate(_date)),
            ),
            if (widget.viewModel.formErrorMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Color(0xFFB42318))),
            ],
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: widget.viewModel.isSaving ? null : widget.onCancel,
                  child: const Text('Отмена')),
              const SizedBox(width: 12),
              FilledButton(
                  onPressed: widget.viewModel.isSaving ? null : _submit,
                  child: Text(widget.isEditing ? 'Сохранить' : 'Создать')),
            ]),
          ],
        ),
      );
}
