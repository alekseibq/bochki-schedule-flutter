import 'package:flutter/foundation.dart';
import '../../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../../domain/procedure_statistics/procedure_statistics_table.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

final class ProcedureStatisticsViewModel extends ChangeNotifier {
  ProcedureStatisticsViewModel(
      {required BuildProcedureStatisticsTableUseCase buildUseCase,
      required ListWorkdaysUseCase listWorkdaysUseCase})
      : _load = ((dayId, people, mode) async => ProcedureStatisticsSnapshot(
              workdays: await listWorkdaysUseCase.execute(),
              table: await buildUseCase.execute(
                  dayId: dayId, peopleFilter: people, mode: mode),
            ));
  ProcedureStatisticsViewModel.fromLoader(this._load);
  final Future<ProcedureStatisticsSnapshot> Function(
      String?, ProcedureStatisticsPeopleFilter, ProcedureStatisticsMode) _load;
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
      final snapshot = await _load(selectedDay, selectedPeople, selectedMode);
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

final class ProcedureStatisticsSnapshot {
  const ProcedureStatisticsSnapshot(
      {required this.workdays, required this.table});
  final List<Workday> workdays;
  final ProcedureStatisticsTable table;
}
