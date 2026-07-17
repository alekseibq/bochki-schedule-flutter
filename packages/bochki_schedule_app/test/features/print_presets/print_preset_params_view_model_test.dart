import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('print preset params view model', () {
    late _InMemoryPrintPresetParamsRepository repository;
    late _InMemoryWorkdaysRepository workdaysRepository;
    late PrintPresetParamsViewModel viewModel;

    setUp(() {
      repository = _InMemoryPrintPresetParamsRepository(
        const PrintPresetParams(
          workdayId: 'missing',
          textBefore: 'Начало',
          textAfter: 'Конец',
        ),
      );
      workdaysRepository = _InMemoryWorkdaysRepository([
        Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
      ]);
      viewModel = PrintPresetParamsViewModel(
        getPrintPresetParamsUseCase: GetPrintPresetParamsUseCase(repository),
        updatePrintPresetParamsUseCase: UpdatePrintPresetParamsUseCase(
          repository,
        ),
        listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
      );
    });

    test('loads params and falls back to first available workday', () async {
      await viewModel.load();

      expect(viewModel.params.textBefore, 'Начало');
      expect(viewModel.initialWorkdayId, '1');
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('returns null initialWorkdayId when no workdays exist', () async {
      workdaysRepository = _InMemoryWorkdaysRepository(const []);
      viewModel = PrintPresetParamsViewModel(
        getPrintPresetParamsUseCase: GetPrintPresetParamsUseCase(repository),
        updatePrintPresetParamsUseCase: UpdatePrintPresetParamsUseCase(
          repository,
        ),
        listWorkdaysUseCase: ListWorkdaysUseCase(workdaysRepository),
      );

      await viewModel.load();

      expect(viewModel.initialWorkdayId, isNull);
      expect(viewModel.hasAvailableWorkdays, isFalse);
    });

    test('saves params', () async {
      final isSuccess = await viewModel.save(
        workdayId: '1',
        textBefore: 'A',
        textAfter: 'B',
      );

      expect(isSuccess, isTrue);
      expect(
        repository.params.toJson(),
        const PrintPresetParams(
          workdayId: '1',
          textBefore: 'A',
          textAfter: 'B',
        ).toJson(),
      );
    });
  });
}

final class _InMemoryPrintPresetParamsRepository
    implements PrintPresetParamsRepository {
  _InMemoryPrintPresetParamsRepository(this._params);

  PrintPresetParams _params;

  PrintPresetParams get params => _params;

  @override
  Future<PrintPresetParams> get() async => _params;

  @override
  Future<PrintPresetParams> update(PrintPresetParams params) async {
    _params = params;
    return _params;
  }
}

final class _InMemoryWorkdaysRepository implements WorkdaysRepository {
  _InMemoryWorkdaysRepository(this._workdays);

  final List<Workday> _workdays;

  @override
  Future<Workday> create(Workday workday) {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String workdayId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Workday>> list() async => _workdays;

  @override
  Future<Workday> update(Workday workday) {
    throw UnimplementedError();
  }
}
