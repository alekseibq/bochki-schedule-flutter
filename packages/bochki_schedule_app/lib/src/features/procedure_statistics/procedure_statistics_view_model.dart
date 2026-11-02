import 'package:flutter/foundation.dart';
import '../../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';
import 'procedure_statistics_operations.dart';

final class ProcedureStatisticsViewModel extends ChangeNotifier {
  ProcedureStatisticsViewModel(
      {required BuildProcedureStatisticsTableUseCase buildUseCase,
      required ListWorkdaysUseCase listWorkdaysUseCase})
      : _operations = UseCaseProcedureStatisticsOperations(
          buildUseCase: buildUseCase,
          listWorkdaysUseCase: listWorkdaysUseCase,
        );
  ProcedureStatisticsViewModel.fromOperations(this._operations);
  final ProcedureStatisticsOperations _operations;
  List<Workday> workdays = const [];
  ProcedureStatisticsTable? table;
  bool isLoading = false;
  String? error;
  String? dayId;
  ProcedureStatisticsPeopleFilter peopleFilter =
      ProcedureStatisticsPeopleFilter.all;
  ProcedureStatisticsMode mode = ProcedureStatisticsMode.participation;
  int _loadVersion = 0;
  bool _disposed = false;
  Future<void> load() async {
    final version = ++_loadVersion;
    final selectedDay = dayId;
    final selectedPeople = peopleFilter;
    final selectedMode = mode;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await _operations.load(
          dayId: selectedDay, peopleFilter: selectedPeople, mode: selectedMode);
      if (_disposed || version != _loadVersion) return;
      workdays = snapshot.workdays;
      table = snapshot.table;
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      error = 'Не удалось загрузить статистику процедур.';
    } finally {
      if (!_disposed && version == _loadVersion) {
        isLoading = false;
        notifyListeners();
      }
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
