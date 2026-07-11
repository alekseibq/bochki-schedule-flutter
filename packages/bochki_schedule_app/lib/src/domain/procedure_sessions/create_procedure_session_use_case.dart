import '../assistants/assistants_repository.dart';
import '../humans/humans_repository.dart';
import '../procedure_kinds/procedure_kinds_repository.dart';
import '../program_settings/program_settings_repository.dart';
import '../workdays/workdays_repository.dart';

import 'procedure_session_raw.dart';
import 'procedure_session_validator.dart';
import 'procedure_sessions_repository.dart';

final class CreateProcedureSessionUseCase {
  const CreateProcedureSessionUseCase(
    this._repository, {
    required WorkdaysRepository workdaysRepository,
    required HumansRepository humansRepository,
    required ProcedureKindsRepository procedureKindsRepository,
    required AssistantsRepository assistantsRepository,
    required ProgramSettingsRepository programSettingsRepository,
  })  : _workdaysRepository = workdaysRepository,
        _humansRepository = humansRepository,
        _procedureKindsRepository = procedureKindsRepository,
        _assistantsRepository = assistantsRepository,
        _programSettingsRepository = programSettingsRepository;

  final ProcedureSessionsRepository _repository;
  final WorkdaysRepository _workdaysRepository;
  final HumansRepository _humansRepository;
  final ProcedureKindsRepository _procedureKindsRepository;
  final AssistantsRepository _assistantsRepository;
  final ProgramSettingsRepository _programSettingsRepository;

  Future<ProcedureSessionRaw> execute(
      ProcedureSessionRaw procedureSession) async {
    final validatedProcedureSession = ProcedureSessionValidator.validateForSave(
      procedureSession,
      existingWorkdays: await _workdaysRepository.list(),
      existingHumans: await _humansRepository.list(),
      existingProcedureKinds: await _procedureKindsRepository.list(),
      existingAssistants: await _assistantsRepository.list(),
      programSettings: await _programSettingsRepository.get(),
    );
    return _repository.create(validatedProcedureSession);
  }
}
