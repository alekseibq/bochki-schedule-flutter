import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('program settings view model', () {
    late _InMemoryProgramSettingsRepository repository;
    late ProgramSettingsViewModel viewModel;

    setUp(() {
      repository = _InMemoryProgramSettingsRepository(
        ProgramSettings.defaults,
      );
      viewModel = ProgramSettingsViewModel(
        getProgramSettingsUseCase: GetProgramSettingsUseCase(repository),
        updateProgramSettingsUseCase: UpdateProgramSettingsUseCase(repository),
      );
    });

    test('loads settings', () async {
      await viewModel.loadProgramSettings();

      expect(viewModel.settings, ProgramSettings.defaults);
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('surfaces validation error on save', () async {
      await viewModel.loadProgramSettings();

      final isSuccess = await viewModel.saveProgramSettings(
        const ProgramSettings(
          lunchStart: ProgramSettingsTime(hour: 15, minute: 0),
          lunchEnd: ProgramSettingsTime(hour: 14, minute: 0),
          minimumHour: 8,
          maximumHour: 20,
        ),
      );

      expect(isSuccess, isFalse);
      expect(
        viewModel.formErrorMessage,
        'Конец обеда должен быть позже начала обеда.',
      );
    });
  });
}

final class _InMemoryProgramSettingsRepository
    implements ProgramSettingsRepository {
  _InMemoryProgramSettingsRepository(this._settings);

  ProgramSettings _settings;

  @override
  Future<ProgramSettings> get() async => _settings;

  @override
  Future<ProgramSettings> update(ProgramSettings settings) async {
    _settings = settings;
    return _settings;
  }
}
