import 'package:flutter/foundation.dart';

import '../../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../../domain/schedule_gaps/schedule_gap.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';
import 'free_time_operations.dart';

/// Host-independent state of the free-time feature.
final class FreeTimeViewModel extends ChangeNotifier {
  FreeTimeViewModel({
    required BuildScheduleGapsUseCase buildScheduleGapsUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
  }) : _operations = UseCaseFreeTimeOperations(
          buildScheduleGapsUseCase: buildScheduleGapsUseCase,
          listWorkdaysUseCase: listWorkdaysUseCase,
        );

  FreeTimeViewModel.fromOperations(FreeTimeOperations operations)
      : _operations = operations;

  final FreeTimeOperations _operations;
  String? dayId;
  ScheduleGapPeopleFilter people = ScheduleGapPeopleFilter.all;
  int fromMinutes = 480;
  int toMinutes = 1200;
  int minimumDurationMinutes = 30;
  List<Workday> workdays = const [];
  List<ScheduleGap> gaps = const [];
  bool isLoading = true;
  String? error;
  int _loadVersion = 0;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    final query = ScheduleGapsQuery(
      dayId: dayId,
      fromMinutes: fromMinutes,
      toMinutes: toMinutes,
      peopleFilter: people,
      minimumDurationMinutes: minimumDurationMinutes,
    );
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final loadedWorkdays = await _operations.listWorkdays();
      final loadedGaps = await _operations.build(query);
      if (_disposed || version != _loadVersion) return;
      workdays = loadedWorkdays;
      gaps = loadedGaps;
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      error = 'Не удалось загрузить свободное время.';
    } finally {
      if (!_disposed && version == _loadVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> setDay(String? value) async {
    dayId = value;
    await load();
  }

  Future<void> setPeople(ScheduleGapPeopleFilter value) async {
    people = value;
    await load();
  }

  Future<void> setFrom(int value) async {
    fromMinutes = value;
    if (fromMinutes > toMinutes) {
      final old = toMinutes;
      toMinutes = fromMinutes;
      fromMinutes = old;
    }
    await load();
  }

  Future<void> setTo(int value) async {
    toMinutes = value;
    if (fromMinutes > toMinutes) {
      final old = fromMinutes;
      fromMinutes = toMinutes;
      toMinutes = old;
    }
    await load();
  }

  Future<void> setMinimumDuration(int value) async {
    minimumDurationMinutes = value;
    await load();
  }
}
