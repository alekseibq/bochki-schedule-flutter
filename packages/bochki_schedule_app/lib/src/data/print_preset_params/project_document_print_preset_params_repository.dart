import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/print_preset_params/print_preset_params_repository.dart';
import '../project_document/project_document_sync_part.dart';

final class ProjectDocumentPrintPresetParamsRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements PrintPresetParamsRepository, ProjectDocumentSyncPart {
  ProjectDocumentPrintPresetParamsRepository({
    required ProjectDocument initialDocument,
    required void Function() onChanged,
  })  : _params = initialDocument.printPresetParams,
        _onChanged = onChanged;

  PrintPresetParams _params;
  final void Function() _onChanged;

  @override
  Future<PrintPresetParams> get() async {
    return _params;
  }

  @override
  Future<PrintPresetParams> update(PrintPresetParams params) async {
    if (_params.toJson().toString() == params.toJson().toString()) {
      return _params;
    }

    _params = params;
    markChanged();
    _onChanged();
    return _params;
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return document.copyWith(printPresetParams: _params);
  }
}
