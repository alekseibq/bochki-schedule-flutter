import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'program_settings_validation_exception.dart';

abstract final class ProgramSettingsValidator {
  static ProgramSettings validateForSave(ProgramSettings settings) {
    if (settings.lunchEnd.compareTo(settings.lunchStart) <= 0) {
      throw const ProgramSettingsValidationException(
        'Конец обеда должен быть позже начала обеда.',
      );
    }
    if (settings.maximumHour <= settings.minimumHour) {
      throw const ProgramSettingsValidationException(
        'Максимальное время должно быть больше минимального.',
      );
    }

    final minimumTime = ProgramSettingsTime(
      hour: settings.minimumHour,
      minute: 0,
    );
    final maximumTime = ProgramSettingsTime(
      hour: settings.maximumHour,
      minute: 0,
    );

    if (settings.lunchStart.compareTo(minimumTime) < 0 ||
        settings.lunchStart.compareTo(maximumTime) > 0) {
      throw const ProgramSettingsValidationException(
        'Начало обеда должно быть внутри диапазона времени.',
      );
    }
    if (settings.lunchEnd.compareTo(minimumTime) < 0 ||
        settings.lunchEnd.compareTo(maximumTime) > 0) {
      throw const ProgramSettingsValidationException(
        'Конец обеда должен быть внутри диапазона времени.',
      );
    }

    return settings;
  }
}
