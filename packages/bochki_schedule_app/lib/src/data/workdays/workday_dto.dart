import '../../domain/workdays/workday.dart';

final class WorkdayDto {
  const WorkdayDto({
    required this.id,
    required this.name,
    required this.calendarDateIso,
    required this.deleted,
  });

  factory WorkdayDto.fromJson(Map<String, Object?> json) {
    return WorkdayDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      calendarDateIso: (json['calendarDate'] as String? ?? '').trim(),
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory WorkdayDto.fromDomain(
    Workday workday, {
    required bool deleted,
  }) {
    return WorkdayDto(
      id: int.parse(workday.id),
      name: workday.name,
      calendarDateIso: _formatIsoDate(workday.calendarDate),
      deleted: deleted,
    );
  }

  final int id;
  final String name;
  final String calendarDateIso;
  final bool deleted;

  Workday toDomain() {
    return Workday(
      id: '$id',
      name: name,
      calendarDate: _parseIsoDate(calendarDateIso),
    );
  }

  WorkdayDto copyWith({
    int? id,
    String? name,
    String? calendarDateIso,
    bool? deleted,
  }) {
    return WorkdayDto(
      id: id ?? this.id,
      name: name ?? this.name,
      calendarDateIso: calendarDateIso ?? this.calendarDateIso,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'calendarDate': calendarDateIso,
      'deleted': deleted,
    };
  }

  static DateTime _parseIsoDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      return DateTime(1970, 1, 1);
    }
    final year = int.tryParse(parts[0]) ?? 1970;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return DateTime(year, month, day);
  }

  static String _formatIsoDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
