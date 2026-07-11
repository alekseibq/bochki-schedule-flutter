import 'package:bochki_schedule_app/src/data/program_settings/project_document_program_settings_repository.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads defaults from initial document', () async {
    final repository = ProjectDocumentProgramSettingsRepository(
      initialDocument: ProjectDocument.initial(),
      onChanged: () {},
    );

    final settings = await repository.get();

    expect(settings, ProgramSettings.defaults);
  });

  test('applies updated settings back into project document', () async {
    var changed = false;
    final repository = ProjectDocumentProgramSettingsRepository(
      initialDocument: ProjectDocument.initial(),
      onChanged: () {
        changed = true;
      },
    );

    const updated = ProgramSettings(
      lunchStart: ProgramSettingsTime(hour: 13, minute: 0),
      lunchEnd: ProgramSettingsTime(hour: 14, minute: 0),
      minimumHour: 7,
      maximumHour: 19,
    );

    await repository.update(updated);
    final document = repository.applyToDocument(ProjectDocument.initial());

    expect(changed, isTrue);
    expect(document.programSettings, updated);
    expect(document.toJson()['programSettings'], updated.toJson());
  });
}
