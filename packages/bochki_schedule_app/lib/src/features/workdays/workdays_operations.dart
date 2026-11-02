import '../../domain/workdays/create_workday_use_case.dart';
import '../../domain/workdays/delete_workday_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/update_workday_use_case.dart';
import '../../domain/workdays/workday.dart';

/// Feature operations for the workdays list and editor hosts.
abstract interface class WorkdaysOperations {
  Future<List<Workday>> list();
  Future<Workday> create(Workday workday);
  Future<Workday> update(Workday workday);
  Future<int> countReferences(String id);
  Future<void> delete(String id);
  Future<List<double>> loadColumnWidths();
  Future<void> saveColumnWidths(List<double> widths);
}

final class UseCaseWorkdaysOperations implements WorkdaysOperations {
  const UseCaseWorkdaysOperations({
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required CreateWorkdayUseCase createWorkdayUseCase,
    required UpdateWorkdayUseCase updateWorkdayUseCase,
    required DeleteWorkdayUseCase deleteWorkdayUseCase,
    required Future<List<double>> Function() loadColumnWidths,
    required Future<void> Function(List<double>) saveColumnWidths,
  })  : _list = listWorkdaysUseCase,
        _create = createWorkdayUseCase,
        _update = updateWorkdayUseCase,
        _delete = deleteWorkdayUseCase,
        _loadColumnWidths = loadColumnWidths,
        _saveColumnWidths = saveColumnWidths;

  final ListWorkdaysUseCase _list;
  final CreateWorkdayUseCase _create;
  final UpdateWorkdayUseCase _update;
  final DeleteWorkdayUseCase _delete;
  final Future<List<double>> Function() _loadColumnWidths;
  final Future<void> Function(List<double>) _saveColumnWidths;

  @override
  Future<List<Workday>> list() => _list.execute();
  @override
  Future<Workday> create(Workday value) => _create.execute(value);
  @override
  Future<Workday> update(Workday value) => _update.execute(value);
  @override
  Future<int> countReferences(String id) => _delete.countReferences(id);
  @override
  Future<void> delete(String id) => _delete.execute(id);
  @override
  Future<List<double>> loadColumnWidths() => _loadColumnWidths();
  @override
  Future<void> saveColumnWidths(List<double> widths) =>
      _saveColumnWidths(widths);
}
