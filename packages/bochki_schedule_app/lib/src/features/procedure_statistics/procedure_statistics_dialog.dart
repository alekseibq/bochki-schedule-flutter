import 'package:flutter/material.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import 'procedure_statistics_view_model.dart';

class ProcedureStatisticsDialog extends StatelessWidget {
  const ProcedureStatisticsDialog(
      {required this.viewModel, required this.onAdd, super.key});
  final ProcedureStatisticsViewModel viewModel;
  final Future<void> Function() onAdd;
  @override
  Widget build(BuildContext context) => Dialog(
      child: SizedBox(
          width: 1050,
          height: 620,
          child: AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) {
                final table = viewModel.table;
                return Column(children: [
                  Container(
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      color: const Color(0xFFE9EEF2),
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                          onPressed: () async {
                            await onAdd();
                            await viewModel.load();
                          },
                          child: const Text('Добавить запись'))),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                            child: DropdownButtonFormField<String?>(
                                key: const Key('procedure_statistics_day'),
                                value: viewModel.dayId,
                                decoration:
                                    const InputDecoration(labelText: 'День'),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('Все дни')),
                                  ...viewModel.workdays.map((d) =>
                                      DropdownMenuItem(
                                          value: d.id, child: Text(d.name)))
                                ],
                                onChanged: (v) => viewModel.setDay(v))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: DropdownButtonFormField(
                                value: viewModel.peopleFilter,
                                decoration: const InputDecoration(
                                    labelText: 'Участники'),
                                items: const [
                                  DropdownMenuItem(
                                      value:
                                          ProcedureStatisticsPeopleFilter.all,
                                      child: Text('Все')),
                                  DropdownMenuItem(
                                      value: ProcedureStatisticsPeopleFilter
                                          .participants,
                                      child: Text('Участники')),
                                  DropdownMenuItem(
                                      value: ProcedureStatisticsPeopleFilter
                                          .assistants,
                                      child: Text('Ассистенты'))
                                ],
                                onChanged: (v) {
                                  if (v != null) viewModel.setPeople(v);
                                })),
                        const SizedBox(width: 12),
                        Expanded(
                            child: DropdownButtonFormField(
                                value: viewModel.mode,
                                decoration:
                                    const InputDecoration(labelText: 'Режим'),
                                items: const [
                                  DropdownMenuItem(
                                      value:
                                          ProcedureStatisticsMode.participation,
                                      child: Text('Участие')),
                                  DropdownMenuItem(
                                      value: ProcedureStatisticsMode.assisting,
                                      child: Text('Ассистирование'))
                                ],
                                onChanged: (v) {
                                  if (v != null) viewModel.setMode(v);
                                }))
                      ])),
                  Expanded(
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : viewModel.error != null
                              ? Center(child: Text(viewModel.error!))
                              : table == null || table.people.isEmpty
                                  ? const Center(
                                      child: Text(
                                          'Нет данных по выбранным фильтрам'))
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                          child: DataTable(columns: [
                                        const DataColumn(
                                            label: Text('Человек')),
                                        ...table.kinds.map((k) =>
                                            DataColumn(label: Text(k.name)))
                                      ], rows: [
                                        for (final human in table.people)
                                          DataRow(cells: [
                                            DataCell(Text(human.shortName)),
                                            ...table.kinds.map((kind) =>
                                                DataCell(Text(
                                                    '${table.count(human, kind)}')))
                                          ])
                                      ]))))
                ]);
              })));
}
