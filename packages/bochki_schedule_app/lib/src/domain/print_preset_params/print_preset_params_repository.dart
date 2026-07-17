import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

abstract interface class PrintPresetParamsRepository {
  Future<PrintPresetParams> get();

  Future<PrintPresetParams> update(PrintPresetParams params);
}
