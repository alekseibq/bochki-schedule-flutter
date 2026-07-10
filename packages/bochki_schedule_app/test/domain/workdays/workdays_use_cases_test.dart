import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('workdays use cases', () {
    test('list loads sorted workdays by date then name', () async {
      final repository = _InMemoryWorkdaysRepository(
        workdays: [
          Workday(
            id: '2',
            name: 'День 2',
            calendarDate: DateTime(2026, 7, 12),
          ),
          Workday(
            id: '3',
            name: 'Альфа',
            calendarDate: DateTime(2026, 7, 11),
          ),
          Workday(
            id: '1',
            name: 'День 1',
            calendarDate: DateTime(2026, 7, 11),
          ),
        ],
      );

      final workdays = await ListWorkdaysUseCase(repository).execute();

      expect(
        workdays.map((workday) => workday.name),
        ['Альфа', 'День 1', 'День 2'],
      );
    });

    test('duplicate name does not pass validation', () async {
      final repository = _InMemoryWorkdaysRepository(
        workdays: [
          Workday(
            id: '1',
            name: 'День 1',
            calendarDate: DateTime(2026, 7, 11),
          ),
        ],
      );

      expect(
        () => CreateWorkdayUseCase(repository).execute(
          Workday(
            id: 'draft',
            name: '  День   1 ',
            calendarDate: DateTime(2026, 7, 12),
          ),
        ),
        throwsA(
          isA<WorkdaysValidationException>().having(
            (error) => error.message,
            'message',
            'День с таким названием уже есть.',
          ),
        ),
      );
    });

    test('default draft uses next calendar date after max existing', () {
      final draft = const WorkdayDefaults(
        nowProvider: _fixedNow,
      ).createDraft([
        Workday(
          id: '1',
          name: 'День 1',
          calendarDate: DateTime(2026, 7, 12),
        ),
        Workday(
          id: '2',
          name: 'День 2',
          calendarDate: DateTime(2026, 7, 15),
        ),
      ]);

      expect(draft.name, 'День 3');
      expect(draft.calendarDate, DateTime(2026, 7, 16));
    });

    test('default draft uses tomorrow when list is empty', () {
      final draft = const WorkdayDefaults(
        nowProvider: _fixedNow,
      ).createDraft(const []);

      expect(draft.name, 'День 1');
      expect(draft.calendarDate, DateTime(2026, 7, 11));
    });
  });
}

DateTime _fixedNow() => DateTime(2026, 7, 10, 13, 45);

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository({
    List<Workday>? workdays,
  }) : _workdays = [...?workdays] {
    if (_workdays.isNotEmpty) {
      final maxId = _workdays
          .map((workday) => int.parse(workday.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Workday> _workdays;
  int _nextId = 1;

  @override
  Future<Workday> create(Workday workday) async {
    final createdWorkday = workday.copyWith(
      id: (_nextId++).toString(),
    );
    _workdays.add(createdWorkday);
    return createdWorkday;
  }

  @override
  Future<void> delete(String workdayId) async {
    _workdays.removeWhere((workday) => workday.id == workdayId);
  }

  @override
  Future<List<Workday>> list() async {
    return [..._workdays];
  }

  @override
  Future<Workday> update(Workday workday) async {
    final index = _workdays.indexWhere(
      (candidate) => candidate.id == workday.id,
    );
    if (index != -1) {
      _workdays[index] = workday;
    }
    return workday;
  }
}
