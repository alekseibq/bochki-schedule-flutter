import 'package:flutter/material.dart';

import '../../domain/schedule_gaps/schedule_gap.dart';
import '../../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import 'free_time_view_model.dart';

class FreeTimeDialog extends StatelessWidget {
  const FreeTimeDialog({
    required this.viewModel,
    required this.onOccupy,
    super.key,
  });

  final FreeTimeViewModel viewModel;
  final Future<void> Function(ScheduleGap gap) onOccupy;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Свободное время'),
        content: SizedBox(
          width: 1040,
          height: 560,
          child: FreeTimeContent(viewModel: viewModel, onOccupy: onOccupy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
}

class FreeTimeContent extends StatelessWidget {
  const FreeTimeContent({
    required this.viewModel,
    required this.onOccupy,
    super.key,
  });

  final FreeTimeViewModel viewModel;
  final Future<void> Function(ScheduleGap gap) onOccupy;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: viewModel,
        builder: (_, __) => Column(children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                value: viewModel.dayId,
                decoration: const InputDecoration(labelText: 'День'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все дни')),
                  ...viewModel.workdays.map(
                    (day) =>
                        DropdownMenuItem(value: day.id, child: Text(day.name)),
                  ),
                ],
                onChanged: (value) {
                  if (value != viewModel.dayId) viewModel.setDay(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: _timeFilter(
                    'Время с', viewModel.fromMinutes, viewModel.setFrom)),
            const SizedBox(width: 12),
            Expanded(
                child: _timeFilter(
                    'Время до', viewModel.toMinutes, viewModel.setTo)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<ScheduleGapPeopleFilter>(
                isExpanded: true,
                value: viewModel.people,
                decoration: const InputDecoration(labelText: 'Искать для'),
                items: const [
                  DropdownMenuItem(
                      value: ScheduleGapPeopleFilter.all,
                      child: Text('Участники и сопровождающие',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: ScheduleGapPeopleFilter.participants,
                      child: Text('Участники')),
                  DropdownMenuItem(
                      value: ScheduleGapPeopleFilter.assistants,
                      child: Text('Сопровождающие')),
                ],
                onChanged: (value) {
                  if (value != null) viewModel.setPeople(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                value: viewModel.minimumDurationMinutes,
                decoration: const InputDecoration(
                    labelText: 'Показывать интервалы более'),
                items: [
                  for (var value = 30; value <= 300; value += 30)
                    DropdownMenuItem(
                        value: value,
                        child: Text(value == 30
                            ? '30 мин'
                            : '${value ~/ 60}ч ${(value % 60).toString().padLeft(2, '0')}мин')),
                ],
                onChanged: (value) {
                  if (value != null) viewModel.setMinimumDuration(value);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(child: _body()),
        ]),
      );

  Widget _timeFilter(
          String label, int selected, Future<void> Function(int) onChanged) =>
      DropdownButtonFormField<int>(
        isExpanded: true,
        value: selected,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var value = 480; value <= 1200; value += 30)
            DropdownMenuItem(
              value: value,
              child: Text(
                  '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}'),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );

  Widget _body() {
    if (viewModel.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (viewModel.error != null) return Center(child: Text(viewModel.error!));
    if (viewModel.gaps.isEmpty)
      return const Center(child: Text('Нет данных по выбранным фильтрам'));
    return _FreeTimeResults(gaps: viewModel.gaps, onOccupy: onOccupy);
  }
}

class _FreeTimeResults extends StatefulWidget {
  const _FreeTimeResults({required this.gaps, required this.onOccupy});
  final List<ScheduleGap> gaps;
  final Future<void> Function(ScheduleGap) onOccupy;

  @override
  State<_FreeTimeResults> createState() => _FreeTimeResultsState();
}

class _FreeTimeResultsState extends State<_FreeTimeResults> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scroll,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('День')),
                DataColumn(label: Text('Человек')),
                DataColumn(label: Text('Начало')),
                DataColumn(label: Text('Конец')),
                DataColumn(label: Text('Длительность')),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (final gap in widget.gaps)
                  DataRow(cells: [
                    DataCell(Text(gap.workday.name)),
                    DataCell(Text(gap.human.name)),
                    DataCell(Text(gap.startTime)),
                    DataCell(Text(gap.endTime)),
                    DataCell(Text(gap.durationLabel)),
                    DataCell(FilledButton.tonal(
                      onPressed: () => widget.onOccupy(gap),
                      child: const Text('Занять участника'),
                    )),
                  ]),
              ],
            ),
          ),
        ),
      );
}
