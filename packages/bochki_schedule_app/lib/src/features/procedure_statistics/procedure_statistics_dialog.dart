import 'package:flutter/material.dart';
import 'procedure_statistics_content.dart';
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
                return ProcedureStatisticsContent(
                  workdays: viewModel.workdays,
                  people: table?.people ?? const [],
                  kinds: table?.kinds ?? const [],
                  countFor: (person, kind) => table?.count(person, kind) ?? 0,
                  isLoading: viewModel.isLoading,
                  error: viewModel.error,
                  dayId: viewModel.dayId,
                  peopleFilter: viewModel.peopleFilter,
                  mode: viewModel.mode,
                  onDayChanged: viewModel.setDay,
                  onPeopleChanged: viewModel.setPeople,
                  onModeChanged: viewModel.setMode,
                  onAdd: () async {
                    await onAdd();
                    await viewModel.load();
                  },
                );
              })));
}
