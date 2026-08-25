import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_date_format.dart';
import 'workdays_view_model.dart';

class WorkdayDialog extends StatefulWidget {
  const WorkdayDialog({
    required this.viewModel,
    required this.initialWorkday,
    this.isEditing = false,
    super.key,
  });

  final WorkdaysViewModel viewModel;
  final Workday initialWorkday;
  final bool isEditing;

  @override
  State<WorkdayDialog> createState() => _WorkdayDialogState();
}

class _WorkdayDialogState extends State<WorkdayDialog> {
  static const double _dialogWidth = 520;
  static const double _labelColumnWidth = 132;

  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialWorkday.name);
    _selectedDate = widget.initialWorkday.calendarDate;
    _dateController = TextEditingController(
      text: formatWorkdayDate(_selectedDate),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final savedWorkday = widget.isEditing
        ? await widget.viewModel.updateWorkday(
            workdayId: widget.initialWorkday.id,
            rawName: _nameController.text,
            rawCalendarDate: formatWorkdayDate(_selectedDate),
          )
        : await widget.viewModel.createWorkday(
            rawName: _nameController.text,
            rawCalendarDate: formatWorkdayDate(_selectedDate),
          );
    if (!mounted || savedWorkday == null) {
      return;
    }

    Navigator.of(context).pop(savedWorkday);
  }

  Future<void> _selectDate() async {
    if (widget.viewModel.isSaving) {
      return;
    }
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || selectedDate == null) {
      return;
    }
    setState(() {
      _selectedDate = selectedDate;
      _dateController.text = formatWorkdayDate(selectedDate);
    });
    widget.viewModel.clearFormError();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return AlertDialog(
          key: Key(
            widget.isEditing ? 'workday_edit_dialog' : 'workday_create_dialog',
          ),
          title: Text(widget.isEditing ? 'Редактирование дня' : 'Новый день'),
          content: SizedBox(
            width: _dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormRow(
                  label: 'Название',
                  labelWidth: _labelColumnWidth,
                  child: TextField(
                    key: const Key('workday_name_field'),
                    controller: _nameController,
                    enabled: !widget.viewModel.isSaving,
                    maxLength: 20,
                    onChanged: (_) => widget.viewModel.clearFormError(),
                  ),
                ),
                const SizedBox(height: 12),
                _FormRow(
                  label: 'Дата',
                  labelWidth: _labelColumnWidth,
                  child: TextField(
                    key: const Key('workday_date_field'),
                    controller: _dateController,
                    enabled: !widget.viewModel.isSaving,
                    readOnly: true,
                    showCursor: false,
                    onTap: _selectDate,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                if (widget.viewModel.formErrorMessage case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
              ],
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
        Expanded(child: child),
      ],
    );
  }
}
