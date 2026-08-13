import 'package:flutter/material.dart';

import 'quick_reassignments_view_model.dart';

class QuickReassignmentsDialog extends StatelessWidget {
  const QuickReassignmentsDialog({required this.viewModel, super.key});
  final QuickReassignmentsViewModel viewModel;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Быстрые перестановки'),
        content: SizedBox(width: 1000, height: 500, child: _content()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'))
        ],
      );

  Widget _content() => AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = viewModel.entries;
          return Column(children: [
            Wrap(spacing: 12, runSpacing: 8, children: [
              _field(
                  'День',
                  viewModel.dayId,
                  [
                    for (final d in viewModel.workdays)
                      DropdownMenuItem(value: d.id, child: Text(d.name))
                  ],
                  viewModel.setDay),
              _field('Части дня', viewModel.part, [
                for (final v in QuickPart.values)
                  DropdownMenuItem(value: v, child: Text(v.label))
              ], (v) {
                if (v != null) viewModel.setPart(v);
              }),
              _field('Участники', viewModel.people, [
                for (final v in QuickPeopleFilter.values)
                  DropdownMenuItem(value: v, child: Text(v.label))
              ], (v) {
                if (v != null) viewModel.setPeople(v);
              }),
              _field('Сортировка', viewModel.sort, [
                for (final v in QuickSort.values)
                  DropdownMenuItem(value: v, child: Text(v.label))
              ], (v) {
                if (v != null) viewModel.setSort(v);
              }),
            ]),
            const SizedBox(height: 16),
            Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                            'Нет назначенных процедур с ассистентом по выбранным фильтрам'))
                    : DataTable(
                        columns: const [
                          DataColumn(label: Text('Время')),
                          DataColumn(label: Text('Процедура')),
                          DataColumn(label: Text('Участник')),
                          DataColumn(label: Text('Ассистент'))
                        ],
                        rows: [
                          for (final s in entries)
                            DataRow(cells: [
                              DataCell(Text(s.startTime)),
                              DataCell(Text(
                                  s.procedureKind?.shortName ?? 'Не найдено')),
                              DataCell(_person(
                                  s.participantId,
                                  s.participant?.name ?? 'Не найден',
                                  viewModel.participantCandidates(s),
                                  (id) => viewModel.changeParticipant(s, id))),
                              DataCell(_person(
                                  s.assistantId,
                                  s.assistant?.name ?? 'Ассистент не назначен',
                                  viewModel.assistantCandidates(s),
                                  (id) => viewModel.chooseAssistant(s, id),
                                  assistant: true)),
                            ])
                        ],
                      )),
          ]);
        },
      );

  Widget _field<T>(String label, T? value, List<DropdownMenuItem<T>> items,
          ValueChanged<T?> onChanged) =>
      SizedBox(
          width: 210,
          child: DropdownButtonFormField<T>(
              decoration: InputDecoration(labelText: label),
              value: value,
              items: items,
              onChanged: onChanged));
  Widget _person(String? value, String label, List<dynamic> candidates,
          Future<void> Function(dynamic) change,
          {bool assistant = false}) =>
      Row(children: [
        Expanded(
            child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                items: [
                  for (final h in candidates)
                    DropdownMenuItem(
                        value:
                            assistant ? h.human.id as String : h.id as String,
                        child: Text(assistant
                            ? (h.human.id == value
                                ? h.human.name as String
                                : h.isSwap
                                    ? '${h.human.name} (${h.swapSession.participant?.name ?? 'Не найден'})'
                                    : '${h.human.name} (Свободен)')
                            : (h.id == value
                                ? h.name as String
                                : '${h.name} (свободен)')))
                ],
                onChanged: (id) {
                  if (id != null) {
                    final item = candidates.firstWhere(
                        (h) => assistant ? h.human.id == id : h.id == id);
                    change(assistant ? item : id);
                  }
                })),
        Tooltip(message: label, child: const Icon(Icons.info_outline, size: 18))
      ]);
}
