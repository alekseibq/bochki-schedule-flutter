import 'workday_validator.dart';
import 'workdays_repository.dart';

final class DeleteWorkdayUseCase {
  const DeleteWorkdayUseCase(this._repository);

  final WorkdaysRepository _repository;

  Future<void> execute(String workdayId) async {
    WorkdayValidator.validateId(workdayId);
    await _repository.delete(workdayId.trim());
  }
}
