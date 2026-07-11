import 'program_settings_time.dart';

final class ProgramSettings {
  const ProgramSettings({
    required this.lunchStart,
    required this.lunchEnd,
    required this.minimumHour,
    required this.maximumHour,
  })  : assert(
          minimumHour >= 0 && minimumHour <= 23,
          'minimumHour must be between 0 and 23',
        ),
        assert(
          maximumHour >= 0 && maximumHour <= 23,
          'maximumHour must be between 0 and 23',
        );

  static const ProgramSettings defaults = ProgramSettings(
    lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
    lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
    minimumHour: 8,
    maximumHour: 20,
  );

  final ProgramSettingsTime lunchStart;
  final ProgramSettingsTime lunchEnd;
  final int minimumHour;
  final int maximumHour;

  factory ProgramSettings.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Program settings must be an object.');
    }

    return ProgramSettings(
      lunchStart: ProgramSettingsTime.fromJson(json['lunchStart']),
      lunchEnd: ProgramSettingsTime.fromJson(json['lunchEnd']),
      minimumHour: _readHour(json['minimumHour'], fieldName: 'minimumHour'),
      maximumHour: _readHour(json['maximumHour'], fieldName: 'maximumHour'),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'lunchStart': lunchStart.toJson(),
      'lunchEnd': lunchEnd.toJson(),
      'minimumHour': minimumHour,
      'maximumHour': maximumHour,
    };
  }

  ProgramSettings copyWith({
    ProgramSettingsTime? lunchStart,
    ProgramSettingsTime? lunchEnd,
    int? minimumHour,
    int? maximumHour,
  }) {
    return ProgramSettings(
      lunchStart: lunchStart ?? this.lunchStart,
      lunchEnd: lunchEnd ?? this.lunchEnd,
      minimumHour: minimumHour ?? this.minimumHour,
      maximumHour: maximumHour ?? this.maximumHour,
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
