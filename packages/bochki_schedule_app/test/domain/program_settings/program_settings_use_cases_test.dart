import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('program settings use cases', () {
    test('get returns stored singleton object', () async {
      const settings = ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
        minimumHour: 8,
        maximumHour: 20,
      );
      final repository = _InMemoryProgramSettingsRepository(settings);

      final loaded = await GetProgramSettingsUseCase(repository).execute();

      expect(loaded, settings);
    });

    test('update rejects lunch end before lunch start', () {
      final repository = _InMemoryProgramSettingsRepository(
        ProgramSettings.defaults,
      );

      expect(
        () => UpdateProgramSettingsUseCase(repository).execute(
          const ProgramSettings(
            lunchStart: ProgramSettingsTime(hour: 14, minute: 0),
            lunchEnd: ProgramSettingsTime(hour: 13, minute: 50),
            minimumHour: 8,
            maximumHour: 20,
          ),
        ),
        throwsA(
          isA<ProgramSettingsValidationException>().having(
            (error) => error.message,
            'message',
            'Конец обеда должен быть позже начала обеда.',
          ),
        ),
      );
    });

    test('update rejects lunch time outside min max range', () {
      final repository = _InMemoryProgramSettingsRepository(
        ProgramSettings.defaults,
      );

      expect(
        () => UpdateProgramSettingsUseCase(repository).execute(
          const ProgramSettings(
            lunchStart: ProgramSettingsTime(hour: 7, minute: 50),
            lunchEnd: ProgramSettingsTime(hour: 15, minute: 0),
            minimumHour: 8,
            maximumHour: 20,
          ),
        ),
        throwsA(
          isA<ProgramSettingsValidationException>().having(
            (error) => error.message,
            'message',
            'Начало обеда должно быть внутри диапазона времени.',
          ),
        ),
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
