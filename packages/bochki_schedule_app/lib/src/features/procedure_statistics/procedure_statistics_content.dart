import 'package:flutter/material.dart';

import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/workday.dart';

class ProcedureStatisticsContent extends StatefulWidget {
  const ProcedureStatisticsContent({
    required this.workdays,
    required this.people,
    required this.kinds,
    required this.countFor,
    required this.isLoading,
    required this.error,
    required this.dayId,
    required this.peopleFilter,
    required this.mode,
    required this.onDayChanged,
    required this.onPeopleChanged,
    required this.onModeChanged,
    this.onAdd,
    super.key,
  });

  final List<Workday> workdays;
  final List<Human> people;
  final List<ProcedureKind> kinds;
  final int Function(Human person, ProcedureKind kind) countFor;
  final bool isLoading;
  final String? error;
  final String? dayId;
  final ProcedureStatisticsPeopleFilter peopleFilter;
  final ProcedureStatisticsMode mode;
  final ValueChanged<String?> onDayChanged;
  final ValueChanged<ProcedureStatisticsPeopleFilter> onPeopleChanged;
  final ValueChanged<ProcedureStatisticsMode> onModeChanged;
  final Future<void> Function()? onAdd;

  @override
  State<ProcedureStatisticsContent> createState() =>
      _ProcedureStatisticsContentState();
}

class _ProcedureStatisticsContentState
    extends State<ProcedureStatisticsContent> {
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          height: 56,
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFE9EEF2),
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: widget.onAdd == null ? null : () => widget.onAdd!.call(),
            child: const Text('Добавить запись'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('procedure_statistics_day'),
                value: widget.dayId,
                decoration: const InputDecoration(labelText: 'День'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все дни')),
                  ...widget.workdays.map((day) =>
                      DropdownMenuItem(value: day.id, child: Text(day.name))),
                ],
                onChanged: widget.onDayChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField(
                value: widget.peopleFilter,
                decoration: const InputDecoration(labelText: 'Участники'),
                items: const [
                  DropdownMenuItem(
                      value: ProcedureStatisticsPeopleFilter.all,
                      child: Text('Все')),
                  DropdownMenuItem(
                      value: ProcedureStatisticsPeopleFilter.participants,
                      child: Text('Участники')),
                  DropdownMenuItem(
                      value: ProcedureStatisticsPeopleFilter.assistants,
                      child: Text('Сопровождающие')),
                ],
                onChanged: (value) {
                  if (value != null) widget.onPeopleChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField(
                value: widget.mode,
                decoration: const InputDecoration(labelText: 'Режим'),
                items: const [
                  DropdownMenuItem(
                      value: ProcedureStatisticsMode.participation,
                      child: Text('Участие')),
                  DropdownMenuItem(
                      value: ProcedureStatisticsMode.assisting,
                      child: Text('Ассистирование')),
                ],
                onChanged: (value) {
                  if (value != null) widget.onModeChanged(value);
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.error != null
                  ? Center(child: Text(widget.error!))
                  : widget.people.isEmpty
                      ? const Center(
                          child: Text('Нет данных по выбранным фильтрам'))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  horizontalMargin: 0,
                                  columnSpacing: 16,
                                  columns: [
                                    const DataColumn(
                                      headingRowAlignment:
                                          MainAxisAlignment.center,
                                      label: Align(
                                          alignment: Alignment.center,
                                          child: Text('Человек')),
                                    ),
                                    ...widget.kinds.map((kind) {
                                      final label = _shortKindName(kind.name);
                                      return DataColumn(
                                        headingRowAlignment:
                                            MainAxisAlignment.center,
                                        tooltip: label == kind.name
                                            ? null
                                            : kind.name,
                                        label: Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                                width: 72,
                                                child: Text(label,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 9)))),
                                      );
                                    }),
                                  ],
                                  rows: [
                                    for (final person in widget.people)
                                      DataRow(cells: [
                                        DataCell(Text(person.name)),
                                        ...widget.kinds.map((kind) => DataCell(
                                            SizedBox(
                                                width: 72,
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                        '${widget.countFor(person, kind)}'))))),
                                      ]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
        ),
      ]);
}

String _shortKindName(String value) =>
    value.length <= 5 ? value : '${value.substring(0, 4)}...';
