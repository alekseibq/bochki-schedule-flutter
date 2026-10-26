import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/procedure_sessions/procedure_session_rich.dart';
import '../../domain/procedure_sessions/procedure_session_tooltip_builder.dart';
import '../../presentation/app_tooltips.dart';
import 'quick_reassignments_view_model.dart';

/// Reusable feature content; production hosts it in a child window.
class QuickReassignmentsContent extends StatefulWidget {
  const QuickReassignmentsContent({
    required this.viewModel,
    required this.columnWidths,
    required this.onColumnWidthsChanged,
    super.key,
  });
  final QuickReassignmentsViewModel viewModel;
  final List<double> columnWidths;
  final Future<void> Function(List<double>) onColumnWidthsChanged;

  @override
  State<QuickReassignmentsContent> createState() => _QuickContentState();
}

class _QuickContentState extends State<QuickReassignmentsContent> {
  static const _columns = [
    _QuickColumn('Время', 100, 70),
    _QuickColumn('Процедура', 240, 130),
    _QuickColumn('Участник', 300, 160),
    _QuickColumn('Сопровождающий', 300, 180),
  ];
  static const _divider = Color(0xFFD7DFE8);
  final _tooltipBuilder = const ProcedureSessionTooltipBuilder();
  late List<double> _widths;
  var _hasRestoredWidths = false;

  @override
  void initState() {
    super.initState();
    _widths = widget.columnWidths.length == _columns.length
        ? List<double>.from(widget.columnWidths)
        : _columns.map((column) => column.initialWidth).toList();
  }

  @override
  void didUpdateWidget(covariant QuickReassignmentsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasRestoredWidths &&
        widget.columnWidths.length == _columns.length &&
        widget.columnWidths != oldWidget.columnWidths) {
      _widths = List<double>.from(widget.columnWidths);
      _hasRestoredWidths = true;
    }
  }

  void _resize(int index, double delta) {
    final left = _widths[index];
    final minimum = _columns[index].minimumWidth;
    if (index == _columns.length - 1) {
      final actual = delta.clamp(minimum - left, double.infinity);
      if (actual == 0) return;
      setState(() => _widths[index] = left + actual);
    } else {
      final right = _widths[index + 1];
      final actual = delta.clamp(
        minimum - left,
        right - _columns[index + 1].minimumWidth,
      );
      if (actual == 0) return;
      setState(() {
        _widths[index] = left + actual;
        _widths[index + 1] = right - actual;
      });
    }
    unawaited(widget.onColumnWidthsChanged(List.unmodifiable(_widths)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.viewModel,
        builder: (_, __) {
          if (widget.viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            _filters(),
            const SizedBox(height: 16),
            Expanded(child: _table()),
          ]);
        },
      );

  Widget _filters() => Row(children: [
        Expanded(
            child: _field(
                'День',
                widget.viewModel.dayId,
                [
                  for (final day in widget.viewModel.workdays)
                    DropdownMenuItem(value: day.id, child: Text(day.name)),
                ],
                widget.viewModel.setDay)),
        const SizedBox(width: 12),
        Expanded(
            child: _field('Участники', widget.viewModel.people, [
          for (final value in QuickPeopleFilter.values)
            DropdownMenuItem(value: value, child: Text(value.label)),
        ], (value) {
          if (value != null) widget.viewModel.setPeople(value);
        })),
        const SizedBox(width: 12),
        Expanded(
            child: _field('Сортировка', widget.viewModel.sort, [
          for (final value in QuickSort.values)
            DropdownMenuItem(value: value, child: Text(value.label)),
        ], (value) {
          if (value != null) widget.viewModel.setSort(value);
        })),
      ]);

  Widget _field<T>(String label, T? value, List<DropdownMenuItem<T>> items,
          ValueChanged<T?> onChanged) =>
      DropdownButtonFormField<T>(
        decoration: InputDecoration(labelText: label),
        value: value,
        items: items,
        onChanged: onChanged,
      );

  Widget _table() {
    final entries = widget.viewModel.entries;
    if (entries.isEmpty) {
      return const Center(
          child: Text(
        'Нет назначенных процедур с сопровождающим по выбранным фильтрам',
      ));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final tableWidth = _widths.fold<double>(0, (sum, width) => sum + width);
      return SingleChildScrollView(
        key: const Key('quick_reassignments_table_horizontal_scroll'),
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth < constraints.maxWidth
              ? constraints.maxWidth
              : tableWidth,
          child: Column(children: [
            Container(
              key: const Key('quick_reassignments_table_header'),
              height: 32,
              color: const Color(0xFFF2F5F8),
              child: Row(children: [
                for (var index = 0; index < _columns.length; index++)
                  _QuickHeaderCell(
                    width: _widths[index],
                    label: _columns[index].label,
                    resizeHandleKey:
                        Key('quick_reassignments_column_resizer_$index'),
                    onResize: (delta) => _resize(index, delta),
                  ),
              ]),
            ),
            const Divider(height: 1, color: _divider),
            Expanded(
                child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _divider),
              itemBuilder: (_, index) => _row(entries[index]),
            )),
          ]),
        ),
      );
    });
  }

  Widget _row(ProcedureSessionRich entry) => Container(
        height: 42,
        color: Colors.white,
        child: Row(children: [
          _QuickCell(width: _widths[0], child: Text(entry.startTime)),
          _QuickCell(
              width: _widths[1],
              child: Text(entry.procedureKind?.shortName ?? 'Не найдено')),
          _QuickCell(
              width: _widths[2],
              child: _person(
                entry: entry,
                value: entry.participantId,
                label: entry.participant?.name ?? 'Не найден',
                candidates: widget.viewModel.participantCandidates(entry),
                onChanged: (id) =>
                    widget.viewModel.changeParticipant(entry, id),
              )),
          _QuickCell(
              width: _widths[3],
              child: _person(
                entry: entry,
                value: entry.assistantId,
                label: entry.assistantId == null
                    ? 'Сопровождающий не назначен'
                    : entry.assistant?.name ?? 'Не найден',
                candidates: widget.viewModel.assistantCandidates(entry),
                assistant: true,
                onChanged: (candidate) =>
                    widget.viewModel.chooseAssistant(entry, candidate),
              )),
        ]),
      );

  Widget _person({
    required ProcedureSessionRich entry,
    required String? value,
    required String label,
    required List<dynamic> candidates,
    required Future<void> Function(dynamic) onChanged,
    bool assistant = false,
  }) {
    final candidatesById = <String, dynamic>{};
    for (final candidate in candidates) {
      final id =
          assistant ? candidate.human.id as String : candidate.id as String;
      candidatesById.putIfAbsent(id, () => candidate);
    }
    return Row(children: [
      Expanded(
          child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        items: [
          if (value != null && !candidatesById.containsKey(value))
            DropdownMenuItem(value: value, child: const Text('Не найден')),
          for (final candidate in candidatesById.entries)
            DropdownMenuItem(
              value: candidate.key,
              child: Text(_candidateLabel(candidate.value, value, assistant)),
            ),
        ],
        onChanged: (id) {
          final candidate = id == null ? null : candidatesById[id];
          if (candidate != null) {
            unawaited(onChanged(assistant ? candidate : id));
          }
        },
      )),
      Tooltip(
        richMessage: _personTooltip(entry, value, label),
        child: const Icon(Icons.info_outline, size: 18),
      ),
    ]);
  }

  TextSpan _personTooltip(
      ProcedureSessionRich entry, String? humanId, String empty) {
    if (humanId == null) return TextSpan(text: empty);
    final matches =
        widget.viewModel.humans.where((human) => human.id == humanId);
    if (matches.isEmpty) return TextSpan(text: empty);
    final data = _tooltipBuilder.personSchedule(
      humanId: humanId,
      humanName: matches.first.name,
      dayId: entry.dayId,
      currentSessionId: entry.id,
      accentParticipantId: entry.participantId,
      accentAssistantId: entry.assistantId,
      savedSessions: widget.viewModel.allEntries.map((item) => item.raw),
      workdays: widget.viewModel.workdays,
      humans: widget.viewModel.humans,
      procedureKinds: widget.viewModel.procedureKinds,
      assistants: widget.viewModel.assistants,
      programSettings: widget.viewModel.programSettings,
    );
    return TextSpan(children: [
      TextSpan(text: data.title.text, style: AppTooltips.textStyle(data.title)),
      for (final line in data.lines)
        TextSpan(text: '\n${line.text}', style: AppTooltips.textStyle(line)),
    ]);
  }

  String _candidateLabel(dynamic candidate, String? value, bool assistant) =>
      assistant
          ? candidate.human.id == value
              ? candidate.human.name as String
              : candidate.isSwap
                  ? '${candidate.human.name} (${candidate.swapSession.participant?.name ?? 'Не найден'})'
                  : '${candidate.human.name} (Свободен)'
          : candidate.id == value
              ? candidate.name as String
              : '${candidate.name} (свободен)';
}

/// Widget-test fallback; production uses [QuickReassignmentsContent].
class QuickReassignmentsDialog extends StatelessWidget {
  const QuickReassignmentsDialog({required this.viewModel, super.key});
  final QuickReassignmentsViewModel viewModel;
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Быстрые перестановки'),
        content: SizedBox(
          width: 1000,
          height: 500,
          child: QuickReassignmentsContent(
            viewModel: viewModel,
            columnWidths: const [],
            onColumnWidthsChanged: (_) async {},
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'))
        ],
      );
}

class _QuickColumn {
  const _QuickColumn(this.label, this.initialWidth, this.minimumWidth);
  final String label;
  final double initialWidth;
  final double minimumWidth;
}

class _QuickCell extends StatelessWidget {
  const _QuickCell({required this.width, required this.child});
  final double width;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
}

class _QuickHeaderCell extends StatelessWidget {
  const _QuickHeaderCell({
    required this.width,
    required this.label,
    required this.resizeHandleKey,
    required this.onResize,
  });
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
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                key: resizeHandleKey,
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
                child: const SizedBox(width: 8, height: double.infinity),
              ),
            ),
          ),
        ]),
      );
}
