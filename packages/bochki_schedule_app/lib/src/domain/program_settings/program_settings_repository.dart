import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

abstract interface class ProgramSettingsRepository {
  Future<ProgramSettings> get();

  Future<ProgramSettings> update(ProgramSettings settings);
}
