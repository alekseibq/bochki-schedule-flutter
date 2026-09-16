import 'program_settings_time.dart';

final class ProgramSettings {
  const ProgramSettings({
    required this.minimumTime,
    required this.maximumTime,
    this.uiScale = 1.1,
  });

  static const ProgramSettings defaults = ProgramSettings(
    minimumTime: ProgramSettingsTime(hour: 8, minute: 0),
    maximumTime: ProgramSettingsTime(hour: 20, minute: 0),
  );

  final ProgramSettingsTime minimumTime;
  final ProgramSettingsTime maximumTime;
  final double uiScale;

  factory ProgramSettings.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Program settings must be an object.');
    }

    return ProgramSettings(
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
      uiScale: _readUiScale(json['uiScale']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'minimumTime': minimumTime.toJson(),
      'maximumTime': maximumTime.toJson(),
      'uiScale': uiScale,
    };
  }

  ProgramSettings copyWith({
    ProgramSettingsTime? minimumTime,
    ProgramSettingsTime? maximumTime,
    double? uiScale,
  }) {
    return ProgramSettings(
      minimumTime: minimumTime ?? this.minimumTime,
      maximumTime: maximumTime ?? this.maximumTime,
      uiScale: uiScale ?? this.uiScale,
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

  static double _readUiScale(Object? value) {
    if (value == null) return 1.1;
    const allowed = [1.0, 1.05, 1.1, 1.15, 1.2];
    if (value is! num || !allowed.contains(value.toDouble())) {
      throw const FormatException(
        'Program settings uiScale must be one of 1.0, 1.05, 1.1, 1.15, 1.2.',
      );
    }
    return value.toDouble();
  }
}
