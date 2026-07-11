import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'program_settings_repository.dart';
import 'program_settings_validator.dart';

final class UpdateProgramSettingsUseCase {
  const UpdateProgramSettingsUseCase(this._repository);

  final ProgramSettingsRepository _repository;

  Future<ProgramSettings> execute(ProgramSettings settings) async {
    final validatedSettings =
        ProgramSettingsValidator.validateForSave(settings);
    return _repository.update(validatedSettings);
  }
}
