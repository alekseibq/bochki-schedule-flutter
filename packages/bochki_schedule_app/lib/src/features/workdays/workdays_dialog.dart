import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_date_format.dart';
import 'workday_dialog.dart';
import 'workdays_view_model.dart';

class WorkdaysDialog extends StatefulWidget {
  const WorkdaysDialog({
    required this.viewModel,
    super.key,
  });

  final WorkdaysViewModel viewModel;

  @override
  State<WorkdaysDialog> createState() => _WorkdaysDialogState();
}

class _WorkdaysDialogState extends State<WorkdaysDialog> {
  String? _selectedWorkdayId;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_showActionErrorIfNeeded);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showActionErrorIfNeeded);
    super.dispose();
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

  Future<void> _openCreateDialog() async {
    widget.viewModel.clearFormError();
    final createdWorkday = await showDialog<Workday>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WorkdayDialog(
          viewModel: widget.viewModel,
          initialWorkday: widget.viewModel.suggestDraftWorkday(),
        );
      },
    );
    if (!mounted || createdWorkday == null) {
      return;
    }
    setState(() {
      _selectedWorkdayId = createdWorkday.id;
    });
  }

  Future<void> _openEditDialog(Workday workday) async {
    widget.viewModel.clearFormError();
    final updatedWorkday = await showDialog<Workday>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WorkdayDialog(
          viewModel: widget.viewModel,
          initialWorkday: workday,
          isEditing: true,
        );
      },
    );
    if (!mounted || updatedWorkday == null) {
      return;
    }
    setState(() {
      _selectedWorkdayId = updatedWorkday.id;
    });
  }

  Future<void> _openReorderDialog(Workday workday) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('workday_reorder_dialog'),
          title: Text('Перестановки: ${workday.name}'),
          content: const Text(
            'Заглушка. Здесь позже будет управление перестановками строк расписания.',
          ),
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

  Future<void> _deleteWorkday(Workday workday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить день?'),
          content: Text('День "${workday.name}" будет скрыт из списка.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final isSuccess = await widget.viewModel.deleteWorkday(workday.id);
    if (!mounted || !isSuccess) {
      return;
    }

    setState(() {
      if (_selectedWorkdayId == workday.id) {
        _selectedWorkdayId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return AlertDialog(
          key: const Key('workdays_dialog'),
          title: const Text('Список дней'),
          content: SizedBox(
            width: 900,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    key: const Key('workday_add_button'),
                    onPressed:
                        widget.viewModel.isSaving ? null : _openCreateDialog,
                    child: const Text('Создать'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (widget.viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.viewModel.loadErrorMessage case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.viewModel.loadWorkdays,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            key: const Key('workdays_table_header'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F8),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D7DE)),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('')),
                Expanded(flex: 3, child: Text('Название')),
                Expanded(flex: 2, child: Text('Дата')),
                SizedBox(width: 116, child: Text('')),
                SizedBox(width: 96, child: Text('')),
                SizedBox(width: 96, child: Text('')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.viewModel.workdays.length,
              itemBuilder: (context, index) {
                final workday = widget.viewModel.workdays[index];
                final isSelected = _selectedWorkdayId == workday.id;
                return InkWell(
                  key: Key('workday_row_${workday.id}'),
                  onTap: () {
                    setState(() {
                      _selectedWorkdayId = workday.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F6FF)
                          : Colors.transparent,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE5E9EF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(isSelected ? '▶' : ''),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(workday.name),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatWorkdayDate(workday.calendarDate)),
                        ),
                        SizedBox(
                          width: 116,
                          child: TextButton(
                            key: Key('workday_reorder_${workday.id}'),
                            onPressed: widget.viewModel.isSaving
                                ? null
                                : () => unawaited(_openReorderDialog(workday)),
                            child: const Text('Перестановки'),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: TextButton(
                            key: Key('workday_edit_${workday.id}'),
                            onPressed: widget.viewModel.isSaving
                                ? null
                                : () => unawaited(_openEditDialog(workday)),
                            child: const Text('Изменить'),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: TextButton(
                            key: Key('workday_delete_${workday.id}'),
                            onPressed: widget.viewModel.isSaving
                                ? null
                                : () => unawaited(_deleteWorkday(workday)),
                            child: const Text('Удалить'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
