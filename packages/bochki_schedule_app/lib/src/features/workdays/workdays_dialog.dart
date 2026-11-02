import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_dialog.dart';
import 'workdays_content.dart';
import 'workdays_view_model.dart';

/// Fallback host for the shared workdays content.
class WorkdaysDialog extends StatefulWidget {
  const WorkdaysDialog({required this.viewModel, super.key});
  final WorkdaysViewModel viewModel;

  @override
  State<WorkdaysDialog> createState() => _WorkdaysDialogState();
}

class _WorkdaysDialogState extends State<WorkdaysDialog> {
  List<double> _columnWidths = WorkdaysContent.defaultColumnWidths;

  @override
  void initState() {
    super.initState();
    _loadColumnWidths();
  }

  Future<void> _loadColumnWidths() async {
    final widths = await widget.viewModel.loadColumnWidths();
    if (mounted && widths.isNotEmpty) {
      setState(() => _columnWidths = widths);
    }
  }

  Future<void> _openCreateDialog() async {
    widget.viewModel.clearFormError();
    await showDialog<Workday>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkdayDialog(
        viewModel: widget.viewModel,
        initialWorkday: widget.viewModel.suggestDraftWorkday(),
      ),
    );
  }

  Future<void> _openEditDialog(Workday workday) async {
    widget.viewModel.clearFormError();
    await showDialog<Workday>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkdayDialog(
        viewModel: widget.viewModel,
        initialWorkday: workday,
        isEditing: true,
      ),
    );
  }

  Future<void> _openReorderDialog(Workday workday) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('workday_reorder_dialog'),
          title: Text('Перестановки: ${workday.name}'),
          content: const Text(
            'Заглушка. Здесь позже будет управление перестановками строк расписания.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('workdays_dialog'),
        title: const Text('Список дней'),
        content: SizedBox(
          width: 900,
          height: 520,
          child: WorkdaysContent(
            viewModel: widget.viewModel,
            columnWidths: _columnWidths,
            onColumnWidthsChanged: (widths) async {
              setState(() => _columnWidths = widths);
              await widget.viewModel.saveColumnWidths(widths);
            },
            onOpenCreate: () => unawaited(_openCreateDialog()),
            onOpenEdit: (workday) => unawaited(_openEditDialog(workday)),
            onOpenReorder: (workday) => unawaited(_openReorderDialog(workday)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ok'),
          ),
        ],
      );
}
