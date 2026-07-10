import 'workday.dart';
import 'workday_validator.dart';
import 'workdays_repository.dart';

final class CreateWorkdayUseCase {
  const CreateWorkdayUseCase(this._repository);

  final WorkdaysRepository _repository;

  Future<Workday> execute(Workday workday) async {
    final validatedWorkday = WorkdayValidator.validateForSave(
      workday,
      existingWorkdays: await _repository.list(),
    );
    return _repository.create(validatedWorkday);
  }
}
