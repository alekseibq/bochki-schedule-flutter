import '../assistants/assistants_repository.dart';
import '../humans/humans_repository.dart';
import '../procedure_kinds/procedure_kinds_repository.dart';
import '../workdays/workdays_repository.dart';
import 'procedure_session_raw.dart';
import 'procedure_sessions_repository.dart';

/// Applies one or two already validated quick reassignment changes atomically.
final class QuickReassignmentsUseCase {
  const QuickReassignmentsUseCase({
    required ProcedureSessionsRepository repository,
    required WorkdaysRepository workdaysRepository,
    required HumansRepository humansRepository,
    required ProcedureKindsRepository procedureKindsRepository,
    required AssistantsRepository assistantsRepository,
  })  : _repository = repository,
        _workdaysRepository = workdaysRepository,
        _humansRepository = humansRepository,
        _procedureKindsRepository = procedureKindsRepository,
        _assistantsRepository = assistantsRepository;

  final ProcedureSessionsRepository _repository;
  final WorkdaysRepository _workdaysRepository;
  final HumansRepository _humansRepository;
  final ProcedureKindsRepository _procedureKindsRepository;
  final AssistantsRepository _assistantsRepository;

  Future<void> execute(List<ProcedureSessionRaw> replacements) async {
    if (replacements.isEmpty || replacements.length > 2) {
      throw ArgumentError.value(replacements, 'replacements');
    }
    final ids = replacements.map((item) => item.id).toSet();
    if (ids.length != replacements.length) {
      throw ArgumentError('Duplicate ids.');
    }
    final existing = await _repository.list();
    if (ids.any((id) => !existing.any((item) => item.id == id))) {
      throw StateError('Назначенная процедура не найдена.');
    }
    // Referenced dictionaries are read before committing so deleted entities
    // cannot be introduced by a quick reassignment.
    final humans = await _humansRepository.list();
    final kinds = await _procedureKindsRepository.list();
    final assistants = await _assistantsRepository.list();
    await _workdaysRepository.list();
    for (final item in replacements) {
      if (!humans.any((human) => human.id == item.participantId) ||
          !kinds.any((kind) => kind.id == item.procedureKindId) ||
          (item.assistantId != null &&
              !assistants
                  .any((assistant) => assistant.id == item.assistantId))) {
        throw StateError(
            'Нельзя применить перестановку: изменились справочники.');
      }
    }
    await _repository.updateMany(replacements);
  }
}
