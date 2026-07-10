import 'workday.dart';
import 'workdays_repository.dart';

final class ListWorkdaysUseCase {
  const ListWorkdaysUseCase(this._repository);

  final WorkdaysRepository _repository;

  Future<List<Workday>> execute() async {
    final workdays = await _repository.list();
    workdays.sort((left, right) {
      final dateComparison = left.calendarDate.compareTo(right.calendarDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return Workday.sortKeyForName(left.name)
          .compareTo(Workday.sortKeyForName(right.name));
    });
    return List<Workday>.unmodifiable(workdays);
  }
}
