final class ProgramSettingsTime {
  const ProgramSettingsTime({
    required this.hour,
    required this.minute,
  })  : assert(hour >= 0 && hour <= 23, 'hour must be between 0 and 23'),
        assert(
          minute >= 0 && minute <= 50 && minute % 10 == 0,
          'minute must be between 0 and 50 in 10-minute increments',
        );

  final int hour;
  final int minute;

  factory ProgramSettingsTime.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Program settings time must be an object.');
    }

    return ProgramSettingsTime(
      hour: _readHour(json['hour']),
      minute: _readMinute(json['minute']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hour': hour,
      'minute': minute,
    };
  }

  int compareTo(ProgramSettingsTime other) {
    final hourComparison = hour.compareTo(other.hour);
    if (hourComparison != 0) {
      return hourComparison;
    }
    return minute.compareTo(other.minute);
  }

  ProgramSettingsTime copyWith({
    int? hour,
    int? minute,
  }) {
    return ProgramSettingsTime(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  static int _readHour(Object? value) {
    if (value is! num) {
      throw const FormatException(
        'Program settings time field "hour" must be a number.',
      );
    }

    final hour = value.toInt();
    if (hour < 0 || hour > 23) {
      throw const FormatException(
        'Program settings time hour must be between 0 and 23.',
      );
    }
    return hour;
  }

  static int _readMinute(Object? value) {
    if (value is! num) {
      throw const FormatException(
        'Program settings time field "minute" must be a number.',
      );
    }

    final minute = value.toInt();
    if (minute < 0 || minute > 50 || minute % 10 != 0) {
      throw const FormatException(
        'Program settings time minute must be between 0 and 50 in 10-minute increments.',
      );
    }
    return minute;
  }
}
