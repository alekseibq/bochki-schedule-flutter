import 'package:bochki_schedule_app/src/data/print_preset_params/project_document_print_preset_params_repository.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads params from initial document', () async {
    const params = PrintPresetParams(
      workdayId: '4',
      textBefore: 'Привет',
      textAfter: 'Пока',
    );
    final repository = ProjectDocumentPrintPresetParamsRepository(
      initialDocument: const ProjectDocument(printPresetParams: params),
      onChanged: () {},
    );

    expect(await repository.get(), params);
  });

  test('applies updated params to document', () async {
    final repository = ProjectDocumentPrintPresetParamsRepository(
      initialDocument: ProjectDocument.initial(),
      onChanged: () {},
    );
    const updated = PrintPresetParams(
      workdayId: '7',
      textBefore: 'Начало дня',
      textAfter: 'Конец дня',
    );

    await repository.update(updated);
    final document = repository.applyToDocument(ProjectDocument.initial());

    expect(document.printPresetParams, updated);
  });
}
