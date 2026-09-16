import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'program_settings_validation_exception.dart';

abstract final class ProgramSettingsValidator {
  static ProgramSettings validateForSave(ProgramSettings settings) {
    if (settings.maximumTime.compareTo(settings.minimumTime) <= 0) {
      throw const ProgramSettingsValidationException(
        'Максимальное время должно быть больше минимального.',
      );
    }
    return settings;
  }
}
