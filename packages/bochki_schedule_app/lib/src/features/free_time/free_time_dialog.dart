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
              child: DropdownButtonFormField<ScheduleGapPeopleFilter>(
                value: viewModel.people,
                decoration: const InputDecoration(labelText: 'Искать для'),
                items: const [
                  DropdownMenuItem(
                      value: ScheduleGapPeopleFilter.all,
                      child: Text('Участники и сопровождающие')),
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
          ]),
          const SizedBox(height: 12),
          Expanded(child: _body()),
        ]),
      );

  Widget _body() {
    if (viewModel.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (viewModel.error != null) return Center(child: Text(viewModel.error!));
    if (viewModel.gaps.isEmpty)
      return const Center(child: Text('Нет данных по выбранным фильтрам'));
    return ListView.separated(
      itemCount: viewModel.gaps.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final gap = viewModel.gaps[index];
        return ListTile(
          title: Text('${gap.workday.name}: ${gap.human.name}'),
          subtitle:
              Text('${gap.startTime}–${gap.endTime} (${gap.durationLabel})'),
          trailing: FilledButton(
            onPressed: () => onOccupy(gap),
            child: const Text('Занять'),
          ),
        );
      },
    );
  }
}
