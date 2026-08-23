import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'program_settings_validation_exception.dart';

abstract final class ProgramSettingsValidator {
  static ProgramSettings validateForSave(ProgramSettings settings) {
    if (settings.lunchEnd.compareTo(settings.lunchStart) <= 0) {
      throw const ProgramSettingsValidationException(
        'Конец обеда должен быть позже начала обеда.',
      );
    }
    if (settings.maximumTime.compareTo(settings.minimumTime) <= 0) {
      throw const ProgramSettingsValidationException(
        'Максимальное время должно быть больше минимального.',
      );
    }

    if (settings.lunchStart.compareTo(settings.minimumTime) < 0 ||
        settings.lunchStart.compareTo(settings.maximumTime) > 0) {
      throw const ProgramSettingsValidationException(
        'Начало обеда должно быть внутри диапазона времени.',
      );
    }
    if (settings.lunchEnd.compareTo(settings.minimumTime) < 0 ||
        settings.lunchEnd.compareTo(settings.maximumTime) > 0) {
      throw const ProgramSettingsValidationException(
        'Конец обеда должен быть внутри диапазона времени.',
      );
    }

    return settings;
  }
}
