import 'workday.dart';
import 'workdays_validation_exception.dart';

abstract final class WorkdayValidator {
  static Workday validateForSave(
    Workday workday, {
    required Iterable<Workday> existingWorkdays,
  }) {
    final normalizedName = Workday.normalizeName(workday.name);
    if (normalizedName.isEmpty) {
      throw const WorkdaysValidationException(
        'Введите название дня.',
      );
    }
    if (normalizedName.length > 20) {
      throw const WorkdaysValidationException(
        'Название дня должно быть не длиннее 20 символов.',
      );
    }

    final normalizedCandidate = Workday.sortKeyForName(normalizedName);
    final hasDuplicate = existingWorkdays.any(
      (existingWorkday) =>
          existingWorkday.id != workday.id &&
          Workday.sortKeyForName(existingWorkday.name) == normalizedCandidate,
    );
    if (hasDuplicate) {
      throw const WorkdaysValidationException(
        'День с таким названием уже есть.',
      );
    }

    return workday.copyWith(name: normalizedName);
  }

  static void validateId(String workdayId) {
    if (workdayId.trim().isEmpty) {
      throw const WorkdaysValidationException(
        'Идентификатор дня не должен быть пустым.',
      );
    }
  }
}
