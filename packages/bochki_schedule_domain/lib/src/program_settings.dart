import 'program_settings_time.dart';

final class ProgramSettings {
  const ProgramSettings({
    required this.lunchStart,
    required this.lunchEnd,
    required this.minimumTime,
    required this.maximumTime,
  });

  static const ProgramSettings defaults = ProgramSettings(
    lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
    lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
    minimumTime: ProgramSettingsTime(hour: 8, minute: 0),
    maximumTime: ProgramSettingsTime(hour: 20, minute: 0),
  );

  final ProgramSettingsTime lunchStart;
  final ProgramSettingsTime lunchEnd;
  final ProgramSettingsTime minimumTime;
  final ProgramSettingsTime maximumTime;

  factory ProgramSettings.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Program settings must be an object.');
    }

    return ProgramSettings(
      lunchStart: ProgramSettingsTime.fromJson(json['lunchStart']),
      lunchEnd: ProgramSettingsTime.fromJson(json['lunchEnd']),
      minimumTime: json.containsKey('minimumTime')
          ? ProgramSettingsTime.fromJson(json['minimumTime'])
          : ProgramSettingsTime(
              hour: _readHour(json['minimumHour'], fieldName: 'minimumHour'),
              minute: 0,
            ),
      maximumTime: json.containsKey('maximumTime')
          ? ProgramSettingsTime.fromJson(json['maximumTime'])
          : ProgramSettingsTime(
              hour: _readHour(json['maximumHour'], fieldName: 'maximumHour'),
              minute: 0,
            ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'lunchStart': lunchStart.toJson(),
      'lunchEnd': lunchEnd.toJson(),
      'minimumTime': minimumTime.toJson(),
      'maximumTime': maximumTime.toJson(),
    };
  }

  ProgramSettings copyWith({
    ProgramSettingsTime? lunchStart,
    ProgramSettingsTime? lunchEnd,
    ProgramSettingsTime? minimumTime,
    ProgramSettingsTime? maximumTime,
  }) {
    return ProgramSettings(
      lunchStart: lunchStart ?? this.lunchStart,
      lunchEnd: lunchEnd ?? this.lunchEnd,
      minimumTime: minimumTime ?? this.minimumTime,
      maximumTime: maximumTime ?? this.maximumTime,
    );
  }

  static int _readHour(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! num) {
      throw FormatException(
        'Program settings field "$fieldName" must be a number.',
      );
    }
    final hour = value.toInt();
    if (hour < 0 || hour > 23) {
      throw FormatException(
        'Program settings field "$fieldName" must be between 0 and 23.',
      );
    }
    return hour;
  }
}
