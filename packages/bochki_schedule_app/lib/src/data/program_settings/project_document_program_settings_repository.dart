import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/program_settings/program_settings_repository.dart';
import '../project_document/project_document_sync_part.dart';

final class ProjectDocumentProgramSettingsRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements ProgramSettingsRepository, ProjectDocumentSyncPart {
  ProjectDocumentProgramSettingsRepository({
    required ProjectDocument initialDocument,
    required void Function() onChanged,
  })  : _settings = initialDocument.programSettings,
        _onChanged = onChanged;

  ProgramSettings _settings;
  final void Function() _onChanged;

  @override
  Future<ProgramSettings> get() async {
    return _settings;
  }

  @override
  Future<ProgramSettings> update(ProgramSettings settings) async {
    if (_settings.toJson().toString() == settings.toJson().toString()) {
      return _settings;
    }

    _settings = settings;
    markChanged();
    _onChanged();
    return _settings;
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return document.copyWith(programSettings: _settings);
  }
}
