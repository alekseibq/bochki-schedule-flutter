import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/workdays/workday.dart';
import 'workday_date_format.dart';
import 'workdays_view_model.dart';

/// Reusable workdays list body; hosts only provide navigation to the form.
class WorkdaysContent extends StatefulWidget {
  const WorkdaysContent({
    required this.viewModel,
    required this.columnWidths,
    required this.onColumnWidthsChanged,
    required this.onOpenCreate,
    required this.onOpenEdit,
    required this.onOpenReorder,
    super.key,
  });

  static const defaultColumnWidths = [260.0, 160.0, 116.0, 100.0, 90.0];

  final WorkdaysViewModel viewModel;
  final List<double> columnWidths;
  final Future<void> Function(List<double>) onColumnWidthsChanged;
  final VoidCallback onOpenCreate;
  final ValueChanged<Workday> onOpenEdit;
  final ValueChanged<Workday> onOpenReorder;

  @override
  State<WorkdaysContent> createState() => _WorkdaysContentState();
}

class _WorkdaysContentState extends State<WorkdaysContent> {
  String? _selectedWorkdayId;
  late List<double> _widths;

  @override
  void initState() {
    super.initState();
    _widths = _normalizedWidths(widget.columnWidths);
    widget.viewModel.addListener(_showActionErrorIfNeeded);
  }

  @override
  void didUpdateWidget(covariant WorkdaysContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columnWidths != widget.columnWidths) {
      _widths = _normalizedWidths(widget.columnWidths);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showActionErrorIfNeeded);
    super.dispose();
  }

  List<double> _normalizedWidths(List<double> widths) {
    final migrated = widths.length == 4
        ? [widths[0], widths[1], 116.0, widths[2], widths[3]]
        : widths;
    const minimums = [120.0, 100.0, 96.0, 72.0, 72.0];
    if (migrated.length != minimums.length ||
        List.generate(minimums.length, (i) => i).any(
          (i) => !migrated[i].isFinite || migrated[i] < minimums[i],
        )) {
      return List<double>.from(WorkdaysContent.defaultColumnWidths);
    }
    return List<double>.from(migrated);
  }

  void _showActionErrorIfNeeded() {
    final message = widget.viewModel.actionErrorMessage;
    if (!mounted || message == null) return;
    widget.viewModel.clearActionError();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _resize(int index, double delta) {
    const minimums = [120.0, 100.0, 96.0, 72.0, 72.0];
    final current = _widths[index];
    final actual = index == _widths.length - 1
        ? delta.clamp(minimums[index] - current, double.infinity)
        : delta.clamp(
            minimums[index] - current,
            _widths[index + 1] - minimums[index + 1],
          );
    if (actual == 0) return;
    setState(() {
      _widths[index] = current + actual;
      if (index != _widths.length - 1) _widths[index + 1] -= actual;
    });
    unawaited(widget.onColumnWidthsChanged(List<double>.from(_widths)));
  }

  Future<void> _delete(Workday workday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить день?'),
        content: Text('День "${workday.name}" будет удален.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Продолжить')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final references = await widget.viewModel.countReferences(workday.id);
    if (!mounted) return;
    if (references > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Невозможно удалить день'),
          content: Text(
            'День "${workday.name}" используется в $references '
            '${_assignedProcedureWord(references)}. Сначала удалите или '
            'переназначьте эти процедуры.',
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'))
          ],
        ),
      );
      return;
    }
    final deleted = await widget.viewModel.deleteWorkday(workday.id);
    if (deleted && mounted && _selectedWorkdayId == workday.id) {
      setState(() => _selectedWorkdayId = null);
    }
  }

  String _assignedProcedureWord(int count) {
    final remainder100 = count % 100;
    if (remainder100 >= 11 && remainder100 <= 14) return 'назначенных процедур';
    return switch (count % 10) {
      1 => 'назначенная процедура',
      2 || 3 || 4 => 'назначенные процедуры',
      _ => 'назначенных процедур',
    };
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.viewModel.loadErrorMessage case final message?) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(message),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: widget.viewModel.loadWorkdays,
                    child: const Text('Повторить')),
              ]),
            );
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    key: const Key('workday_add_button'),
                    onPressed:
                        widget.viewModel.isSaving ? null : widget.onOpenCreate,
                    child: const Text('Создать'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _table()),
              ]);
        },
      );

  Widget _table() => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD0D7DE)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = _widths.fold<double>(0, (sum, value) => sum + value);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width:
                  width < constraints.maxWidth ? constraints.maxWidth : width,
              child: Column(children: [
                Container(
                  key: const Key('workdays_table_header'),
                  height: 32,
                  color: const Color(0xFFF2F5F8),
                  child: Row(children: [
                    for (var index = 0; index < _widths.length; index++)
                      _HeaderCell(
                        width: _widths[index],
                        label: const [
                          'Название',
                          'Дата',
                          'Перестановки',
                          'Изменить',
                          'Удалить'
                        ][index],
                        resizeHandleKey: Key('workdays_column_resizer_$index'),
                        onResize: (delta) => _resize(index, delta),
                      ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFD7DFE8)),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.viewModel.workdays.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFD7DFE8)),
                    itemBuilder: (_, index) =>
                        _row(widget.viewModel.workdays[index]),
                  ),
                ),
              ]),
            ),
          );
        }),
      );

  Widget _row(Workday workday) {
    final selected = _selectedWorkdayId == workday.id;
    return InkWell(
      key: Key('workday_row_${workday.id}'),
      onTap: () => setState(() => _selectedWorkdayId = workday.id),
      child: Container(
        height: 36,
        color: selected ? const Color(0xFFF0F6FF) : Colors.transparent,
        child: Row(children: [
          _Cell(
            _widths[0],
            Row(children: [
              SizedBox(width: 24, child: Text(selected ? '▶' : '')),
              Expanded(child: Text(workday.name)),
            ]),
          ),
          _Cell(_widths[1], Text(formatWorkdayDate(workday.calendarDate))),
          _Cell(
              _widths[2],
              TextButton(
                  key: Key('workday_reorder_${workday.id}'),
                  onPressed: widget.viewModel.isSaving
                      ? null
                      : () => widget.onOpenReorder(workday),
                  child: const Text('Перестановки'))),
          _Cell(
              _widths[3],
              TextButton(
                  key: Key('workday_edit_${workday.id}'),
                  onPressed: widget.viewModel.isSaving
                      ? null
                      : () => widget.onOpenEdit(workday),
                  child: const Text('Изм.'))),
          _Cell(
              _widths[4],
              TextButton(
                  key: Key('workday_delete_${workday.id}'),
                  onPressed: widget.viewModel.isSaving
                      ? null
                      : () => unawaited(_delete(workday)),
                  child: const Text('Удл.'))),
        ]),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.width, this.child);
  final double width;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(alignment: Alignment.centerLeft, child: child)));
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
      {required this.width,
      required this.label,
      required this.resizeHandleKey,
      required this.onResize});
  final double width;
  final String label;
  final Key resizeHandleKey;
  final ValueChanged<double> onResize;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Stack(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
          Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                      key: resizeHandleKey,
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) =>
                          onResize(details.delta.dx),
                      child:
                          const SizedBox(width: 8, height: double.infinity)))),
        ]),
      );
}
