import '../assistants/assistants_repository.dart';
import '../humans/humans_repository.dart';
import '../procedure_kinds/procedure_kinds_repository.dart';
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
  })  : _workdaysRepository = workdaysRepository,
        _humansRepository = humansRepository,
        _procedureKindsRepository = procedureKindsRepository,
        _assistantsRepository = assistantsRepository;

  final ProcedureSessionsRepository _repository;
  final WorkdaysRepository _workdaysRepository;
  final HumansRepository _humansRepository;
  final ProcedureKindsRepository _procedureKindsRepository;
  final AssistantsRepository _assistantsRepository;

  Future<ProcedureSessionRaw> execute(
      ProcedureSessionRaw procedureSession) async {
    final validatedProcedureSession = ProcedureSessionValidator.validateForSave(
      procedureSession,
      existingWorkdays: await _workdaysRepository.list(),
      existingHumans: await _humansRepository.list(),
      existingProcedureKinds: await _procedureKindsRepository.list(),
      existingAssistants: await _assistantsRepository.list(),
    );
    return _repository.create(validatedProcedureSession);
  }
}
