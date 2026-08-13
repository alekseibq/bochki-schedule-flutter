import 'package:flutter/foundation.dart';
import '../../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

final class ProcedureStatisticsViewModel extends ChangeNotifier {
  ProcedureStatisticsViewModel(
      {required BuildProcedureStatisticsTableUseCase buildUseCase,
      required ListWorkdaysUseCase listWorkdaysUseCase})
      : _build = buildUseCase,
        _days = listWorkdaysUseCase;
  final BuildProcedureStatisticsTableUseCase _build;
  final ListWorkdaysUseCase _days;
  List<Workday> workdays = const [];
  ProcedureStatisticsTable? table;
  bool isLoading = false;
  String? error;
  String? dayId;
  ProcedureStatisticsPeopleFilter peopleFilter =
      ProcedureStatisticsPeopleFilter.all;
  ProcedureStatisticsMode mode = ProcedureStatisticsMode.participation;
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      workdays = await _days.execute();
      table = await _build.execute(
          dayId: dayId, peopleFilter: peopleFilter, mode: mode);
    } catch (_) {
      error = 'Не удалось загрузить статистику процедур.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDay(String? value) async {
    dayId = value;
    await load();
  }

  Future<void> setPeople(ProcedureStatisticsPeopleFilter value) async {
    peopleFilter = value;
    await load();
  }

  Future<void> setMode(ProcedureStatisticsMode value) async {
    mode = value;
    await load();
  }
}
