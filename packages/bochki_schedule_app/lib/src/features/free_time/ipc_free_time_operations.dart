import '../../domain/humans/human.dart';
import '../../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../../domain/schedule_gaps/schedule_gap.dart';
import '../../domain/workdays/workday.dart';
import 'free_time_operations.dart';

typedef FreeTimeIpcInvoker = Future<Object?> Function(
    String method, Object? arguments);

final class IpcFreeTimeOperations implements FreeTimeOperations {
  const IpcFreeTimeOperations(this._invoke);
  final FreeTimeIpcInvoker _invoke;

  @override
  Future<List<Workday>> listWorkdays() async => _workdays(await _snapshot());

  @override
  Future<List<ScheduleGap>> build(ScheduleGapsQuery query) async {
    final value = await _invoke('freeTime', {
      'dayId': query.dayId,
      'fromMinutes': query.fromMinutes,
      'toMinutes': query.toMinutes,
      'peopleFilter': query.peopleFilter.name,
      'minimumDurationMinutes': query.minimumDurationMinutes,
    });
    final map = Map<String, dynamic>.from(value as Map);
    return (map['gaps'] as List? ?? const [])
        .map((value) => _gap(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _snapshot() async => Map<String, dynamic>.from(
        await _invoke('freeTime', {
          'dayId': null,
          'fromMinutes': 480,
          'toMinutes': 1200,
          'peopleFilter': ScheduleGapPeopleFilter.all.name,
          'minimumDurationMinutes': 30,
        }) as Map,
      );

  List<Workday> _workdays(Map<String, dynamic> value) =>
      (value['workdays'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) => Workday(
                id: item['id'] as String,
                name: item['name'] as String,
                calendarDate: DateTime.parse(item['date'] as String),
              ))
          .toList(growable: false);

  ScheduleGap _gap(Map<String, dynamic> value) {
    final day = Map<String, dynamic>.from(value['day'] as Map);
    final human = Map<String, dynamic>.from(value['human'] as Map);
    return ScheduleGap(
      workday: Workday(
          id: day['id'] as String,
          name: day['name'] as String,
          calendarDate: DateTime.parse(day['date'] as String)),
      human: Human(
          id: human['id'] as String,
          name: human['name'] as String,
          shortName: human['shortName'] as String? ?? '',
          isParticipant: human['isParticipant'] as bool? ?? false,
          isAssistant: human['isAssistant'] as bool? ?? false),
      startMinutes: _minutes(value['start'] as String),
      endMinutes: _minutes(value['end'] as String),
    );
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
