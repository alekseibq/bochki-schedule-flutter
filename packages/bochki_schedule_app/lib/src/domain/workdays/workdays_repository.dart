import 'workday.dart';

abstract interface class WorkdaysRepository {
  Future<List<Workday>> list();

  Future<Workday> create(Workday workday);

  Future<Workday> update(Workday workday);

  Future<void> delete(String workdayId);
}
