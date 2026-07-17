import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'print_preset_params_repository.dart';

final class UpdatePrintPresetParamsUseCase {
  const UpdatePrintPresetParamsUseCase(this._repository);

  final PrintPresetParamsRepository _repository;

  Future<PrintPresetParams> execute(PrintPresetParams params) {
    return _repository.update(params);
  }
}
