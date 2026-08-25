import 'workday_validator.dart';
import 'workdays_repository.dart';
import '../procedure_sessions/procedure_sessions_repository.dart';
import 'workday_in_use_exception.dart';

final class DeleteWorkdayUseCase {
  const DeleteWorkdayUseCase(
    this._repository, {
    required ProcedureSessionsRepository procedureSessionsRepository,
  }) : _procedureSessionsRepository = procedureSessionsRepository;

  final WorkdaysRepository _repository;
  final ProcedureSessionsRepository _procedureSessionsRepository;

  Future<int> countReferences(String workdayId) async {
    WorkdayValidator.validateId(workdayId);
    final normalizedId = workdayId.trim();
    return (await _procedureSessionsRepository.list())
        .where((session) => session.dayId == normalizedId)
        .length;
  }

  Future<void> execute(String workdayId) async {
    WorkdayValidator.validateId(workdayId);
    final normalizedId = workdayId.trim();
    final referencesCount = await countReferences(normalizedId);
    if (referencesCount > 0) {
      throw WorkdayInUseException(referencesCount);
    }
    await _repository.delete(normalizedId);
  }
}
