import 'package:flutter/foundation.dart';

import '../../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../../domain/schedule_gaps/schedule_gap.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

/// Host-independent state of the free-time feature.
final class FreeTimeViewModel extends ChangeNotifier {
  FreeTimeViewModel({
    required BuildScheduleGapsUseCase buildScheduleGapsUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
  })  : _build = buildScheduleGapsUseCase,
        _days = listWorkdaysUseCase;

  final BuildScheduleGapsUseCase _build;
  final ListWorkdaysUseCase _days;
  String? dayId;
  ScheduleGapPeopleFilter people = ScheduleGapPeopleFilter.all;
  int fromMinutes = 480;
  int toMinutes = 1200;
  int minimumDurationMinutes = 30;
  List<Workday> workdays = const [];
  List<ScheduleGap> gaps = const [];
  bool isLoading = true;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      workdays = await _days.execute();
      gaps = await _build.execute(ScheduleGapsQuery(
        dayId: dayId,
        fromMinutes: fromMinutes,
        toMinutes: toMinutes,
        peopleFilter: people,
        minimumDurationMinutes: minimumDurationMinutes,
      ));
    } catch (_) {
      error = 'Не удалось загрузить свободное время.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
