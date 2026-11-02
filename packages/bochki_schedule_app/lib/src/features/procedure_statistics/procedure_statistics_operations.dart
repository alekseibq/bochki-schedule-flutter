import '../../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

final class ProcedureStatisticsSnapshot {
  const ProcedureStatisticsSnapshot(
      {required this.workdays, required this.table});
  final List<Workday> workdays;
  final ProcedureStatisticsTable table;
}

abstract interface class ProcedureStatisticsOperations {
  Future<ProcedureStatisticsSnapshot> load({
    required String? dayId,
    required ProcedureStatisticsPeopleFilter peopleFilter,
    required ProcedureStatisticsMode mode,
  });
}

final class UseCaseProcedureStatisticsOperations
    implements ProcedureStatisticsOperations {
  const UseCaseProcedureStatisticsOperations(
      {required this.buildUseCase, required this.listWorkdaysUseCase});
  final BuildProcedureStatisticsTableUseCase buildUseCase;
  final ListWorkdaysUseCase listWorkdaysUseCase;

  @override
  Future<ProcedureStatisticsSnapshot> load(
          {required String? dayId,
          required ProcedureStatisticsPeopleFilter peopleFilter,
          required ProcedureStatisticsMode mode}) async =>
      ProcedureStatisticsSnapshot(
        workdays: await listWorkdaysUseCase.execute(),
        table: await buildUseCase.execute(
            dayId: dayId, peopleFilter: peopleFilter, mode: mode),
      );
}
