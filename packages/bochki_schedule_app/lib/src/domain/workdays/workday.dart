import '../named_directory/named_directory_entry.dart';

import 'workdays_validation_exception.dart';

final class Workday {
  Workday({
    required String id,
    required String name,
    required DateTime calendarDate,
  })  : id = NamedDirectoryEntry.normalizeId(id),
        name = NamedDirectoryEntry.normalizeName(name),
        calendarDate = _normalizeCalendarDate(calendarDate) {
    if (this.id.isEmpty) {
      throw const WorkdaysValidationException(
        'Идентификатор дня не должен быть пустым.',
      );
    }
    if (this.name.isEmpty) {
      throw const WorkdaysValidationException(
        'Введите название дня.',
      );
    }
  }

  final String id;
  final String name;
  final DateTime calendarDate;

  static String normalizeName(String value) {
    return NamedDirectoryEntry.normalizeName(value);
  }

  static String sortKeyForName(String value) {
    return NamedDirectoryEntry.sortKeyForName(value);
  }

  Workday copyWith({
    String? id,
    String? name,
    DateTime? calendarDate,
  }) {
    return Workday(
      id: id ?? this.id,
      name: name ?? this.name,
      calendarDate: calendarDate ?? this.calendarDate,
    );
  }

  static DateTime _normalizeCalendarDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
