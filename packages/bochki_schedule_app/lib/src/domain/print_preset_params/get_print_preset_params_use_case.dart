import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'print_preset_params_repository.dart';

final class GetPrintPresetParamsUseCase {
  const GetPrintPresetParamsUseCase(this._repository);

  final PrintPresetParamsRepository _repository;

  Future<PrintPresetParams> execute() {
    return _repository.get();
  }
}
