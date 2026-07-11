import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'program_settings_repository.dart';

final class GetProgramSettingsUseCase {
  const GetProgramSettingsUseCase(this._repository);

  final ProgramSettingsRepository _repository;

  Future<ProgramSettings> execute() {
    return _repository.get();
  }
}
