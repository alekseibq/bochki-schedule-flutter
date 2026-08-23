import '../humans/human.dart';
import '../humans/list_humans_use_case.dart';
import '../procedure_kinds/list_procedure_kinds_use_case.dart';
import '../procedure_sessions/list_procedure_sessions_use_case.dart';
import '../procedure_sessions/procedure_session_time.dart';
import '../program_settings/get_program_settings_use_case.dart';
import '../workdays/workday.dart';
import '../workdays/list_workdays_use_case.dart';
import 'schedule_gap.dart';

enum ScheduleGapPeopleFilter { all, participants, assistants }

final class ScheduleGapsQuery {
  const ScheduleGapsQuery({
    this.dayId,
    required this.fromMinutes,
    required this.toMinutes,
    required this.peopleFilter,
    required this.minimumDurationMinutes,
  });

  final String? dayId;
  final int fromMinutes;
  final int toMinutes;
  final ScheduleGapPeopleFilter peopleFilter;
  final int minimumDurationMinutes;
}

final class BuildScheduleGapsUseCase {
  BuildScheduleGapsUseCase({
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required ListHumansUseCase listHumansUseCase,
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required ListProcedureSessionsUseCase listProcedureSessionsUseCase,
    required GetProgramSettingsUseCase getProgramSettingsUseCase,
  })  : _listWorkdaysUseCase = listWorkdaysUseCase,
        _listHumansUseCase = listHumansUseCase,
        _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _listProcedureSessionsUseCase = listProcedureSessionsUseCase,
        _getProgramSettingsUseCase = getProgramSettingsUseCase;

  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final ListHumansUseCase _listHumansUseCase;
  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final ListProcedureSessionsUseCase _listProcedureSessionsUseCase;
  final GetProgramSettingsUseCase _getProgramSettingsUseCase;

  Future<List<ScheduleGap>> execute(ScheduleGapsQuery query) async {
    final settings = await _getProgramSettingsUseCase.execute();
    final workdays = await _listWorkdaysUseCase.execute();
    final humans = await _listHumansUseCase.execute();
    final kinds = await _listProcedureKindsUseCase.execute();
    final sessions = await _listProcedureSessionsUseCase.execute();
    final kindsById = {for (final kind in kinds) kind.id: kind};
    final dayStart =
        settings.minimumTime.hour * 60 + settings.minimumTime.minute;
    final dayEnd = settings.maximumTime.hour * 60 + settings.maximumTime.minute;
    final result = <ScheduleGap>[];

    for (final day in workdays) {
      if (query.dayId != null && query.dayId != day.id) continue;
      for (final human
          in humans.where((human) => _matchesRole(human, query.peopleFilter))) {
        final occupied = <_Interval>[];
        for (final session in sessions.where((item) => item.dayId == day.id)) {
          final kind = kindsById[session.procedureKindId];
          if (kind == null) continue;
          final start = ProcedureSessionTime.toMinutes(session.startTime);
          if (session.participantId == human.id) {
            occupied.add(_Interval(start, start + kind.participantBusyTime));
          }
          if (session.assistantId == human.id &&
              kind.assistantBusyTime != null) {
            occupied.add(_Interval(start, start + kind.assistantBusyTime!));
          }
        }
        var cursor = dayStart;
        for (final interval in _merge(occupied, dayStart, dayEnd)) {
          if (cursor < interval.start) {
            _addIfMatches(result, day, human, cursor, interval.start, query);
          }
          if (interval.end > cursor) {
            cursor = interval.end;
          }
        }
        if (cursor < dayEnd) {
          _addIfMatches(result, day, human, cursor, dayEnd, query);
        }
      }
    }
    result.sort((a, b) {
      final byDay = a.workday.name.compareTo(b.workday.name);
      if (byDay != 0) return byDay;
      final byStart = a.startMinutes.compareTo(b.startMinutes);
      if (byStart != 0) return byStart;
      final byDuration = b.durationMinutes.compareTo(a.durationMinutes);
      return byDuration != 0
          ? byDuration
          : a.human.name.compareTo(b.human.name);
    });
    return List.unmodifiable(result);
  }

  static bool _matchesRole(Human human, ScheduleGapPeopleFilter filter) =>
      switch (filter) {
        ScheduleGapPeopleFilter.all => true,
        ScheduleGapPeopleFilter.participants => !human.isAssistant,
        ScheduleGapPeopleFilter.assistants => human.isAssistant,
      };

  static List<_Interval> _merge(List<_Interval> input, int min, int max) {
    final intervals = input
        .map((item) =>
            _Interval(item.start.clamp(min, max), item.end.clamp(min, max)))
        .where((item) => item.start < item.end)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final result = <_Interval>[];
    for (final current in intervals) {
      if (result.isEmpty || current.start > result.last.end) {
        result.add(current);
      } else if (current.end > result.last.end) {
        result[result.length - 1] = _Interval(result.last.start, current.end);
      }
    }
    return result;
  }

  static void _addIfMatches(List<ScheduleGap> result, Workday day, Human human,
      int start, int end, ScheduleGapsQuery query) {
    final overlapsFilter = start < query.toMinutes && end > query.fromMinutes;
    if (overlapsFilter && end - start >= query.minimumDurationMinutes) {
      result.add(ScheduleGap(
          workday: day, human: human, startMinutes: start, endMinutes: end));
    }
  }
}

final class _Interval {
  const _Interval(this.start, this.end);
  final int start;
  final int end;
}
