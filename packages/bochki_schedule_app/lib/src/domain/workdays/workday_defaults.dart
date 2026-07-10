import 'workday.dart';

final class WorkdayDefaults {
  const WorkdayDefaults({
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;

  Workday createDraft(Iterable<Workday> existingWorkdays) {
    final workdays = existingWorkdays.toList(growable: false);
    final latestCalendarDate = workdays.isEmpty
        ? _dateOnly(_nowProvider())
        : workdays
            .map((workday) => workday.calendarDate)
            .reduce((left, right) => left.isAfter(right) ? left : right);

    return Workday(
      id: 'new',
      name: 'День ${workdays.length + 1}',
      calendarDate: latestCalendarDate.add(const Duration(days: 1)),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
