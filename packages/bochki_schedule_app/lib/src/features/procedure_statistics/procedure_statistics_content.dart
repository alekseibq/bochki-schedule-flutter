import 'package:flutter/material.dart';

import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../../domain/workdays/workday.dart';

/// Shared statistics UI. Containers supply data and commands; this widget does
/// not know whether it is rendered in a dialog or a desktop child window.
class ProcedureStatisticsContent extends StatelessWidget {
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
    required this.onAdd,
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
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          height: 56,
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFE9EEF2),
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: onAdd,
            child: const Text('Добавить запись'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('procedure_statistics_day'),
                value: dayId,
                decoration: const InputDecoration(labelText: 'День'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все дни')),
                  ...workdays.map(
                    (day) => DropdownMenuItem(value: day.id, child: Text(day.name)),
                  ),
                ],
                onChanged: onDayChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField(
                value: peopleFilter,
                decoration: const InputDecoration(labelText: 'Участники'),
                items: const [
                  DropdownMenuItem(value: ProcedureStatisticsPeopleFilter.all, child: Text('Все')),
                  DropdownMenuItem(value: ProcedureStatisticsPeopleFilter.participants, child: Text('Участники')),
                  DropdownMenuItem(value: ProcedureStatisticsPeopleFilter.assistants, child: Text('Ассистенты')),
                ],
                onChanged: (value) {
                  if (value != null) onPeopleChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField(
                value: mode,
                decoration: const InputDecoration(labelText: 'Режим'),
                items: const [
                  DropdownMenuItem(value: ProcedureStatisticsMode.participation, child: Text('Участие')),
                  DropdownMenuItem(value: ProcedureStatisticsMode.assisting, child: Text('Ассистирование')),
                ],
                onChanged: (value) {
                  if (value != null) onModeChanged(value);
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error!))
                  : people.isEmpty
                      ? const Center(child: Text('Нет данных по выбранным фильтрам'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('Человек')),
                                ...kinds.map((kind) => DataColumn(label: Text(kind.name))),
                              ],
                              rows: [
                                for (final person in people)
                                  DataRow(cells: [
                                    DataCell(Text(person.shortName)),
                                    ...kinds.map((kind) => DataCell(Text('${countFor(person, kind)}'))),
                                  ]),
                              ],
                            ),
                          ),
                        ),
        ),
      ]);
}
