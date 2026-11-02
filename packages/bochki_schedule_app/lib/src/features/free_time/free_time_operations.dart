import '../../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../../domain/schedule_gaps/schedule_gap.dart';
import '../../domain/workdays/workday.dart';
import '../../domain/workdays/list_workdays_use_case.dart';

/// Data boundary shared by direct and child-window free-time hosts.
abstract interface class FreeTimeOperations {
  Future<List<Workday>> listWorkdays();

  Future<List<ScheduleGap>> build(ScheduleGapsQuery query);
}

final class UseCaseFreeTimeOperations implements FreeTimeOperations {
  const UseCaseFreeTimeOperations({
    required BuildScheduleGapsUseCase buildScheduleGapsUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
  })  : _build = buildScheduleGapsUseCase,
        _workdays = listWorkdaysUseCase;

  final BuildScheduleGapsUseCase _build;
  final ListWorkdaysUseCase _workdays;

  @override
  Future<List<Workday>> listWorkdays() => _workdays.execute();

  @override
  Future<List<ScheduleGap>> build(ScheduleGapsQuery query) =>
      _build.execute(query);
}
