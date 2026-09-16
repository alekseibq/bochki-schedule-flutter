import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('program settings use cases', () {
    test('get returns stored singleton object', () async {
      const settings = ProgramSettings(
        minimumTime: ProgramSettingsTime(hour: 8, minute: 0),
        maximumTime: ProgramSettingsTime(hour: 20, minute: 0),
      );
      final repository = _InMemoryProgramSettingsRepository(settings);

      final loaded = await GetProgramSettingsUseCase(repository).execute();

      expect(loaded, settings);
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
