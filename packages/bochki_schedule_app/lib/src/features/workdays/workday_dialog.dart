import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_form_content.dart';
import 'workdays_view_model.dart';

/// Fallback host for the shared workday editor content.
class WorkdayDialog extends StatelessWidget {
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
  Widget build(BuildContext context) => AlertDialog(
        key: Key(isEditing ? 'workday_edit_dialog' : 'workday_create_dialog'),
        title: Text(isEditing ? 'Редактирование дня' : 'Новый день'),
        content: SizedBox(
          width: 520,
          child: WorkdayFormContent(
            viewModel: viewModel,
            initialWorkday: initialWorkday,
            isEditing: isEditing,
            onSaved: (workday) => Navigator.of(context).pop(workday),
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      );
}
