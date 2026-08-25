import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late TemplateFileStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bochki_templates_test');
    store = TemplateFileStore(
      appDataDirectory: directory,
      safeFileWriter: const AtomicFileWriter(),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test('saves a full document with active entity counts in its filename',
      () async {
    final template = await store.save(
      title: 'Бочки июль 26',
      document: const ProjectDocument(
        humans: [
          {
            'id': 1,
            'name': 'Ученик',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': false
          },
          {
            'id': 2,
            'name': 'Ассистент',
            'isParticipant': false,
            'isAssistant': true,
            'deleted': false
          },
          {
            'id': 3,
            'name': 'Удалён',
            'isParticipant': true,
            'isAssistant': true,
            'deleted': true
          },
        ],
        workdays: [
          {'id': 1, 'name': 'День 1', 'deleted': false},
          {'id': 2, 'name': 'День 2', 'deleted': true},
        ],
      ),
    );

    expect(template.displayName, 'Бочки июль 26 -- 1-1-1');
    expect(await store.list(), hasLength(1));
  });

  test('lists only files with a template filename and rejects future schemas',
      () async {
    final templatesDirectory = Directory('${directory.path}/saved-patterns');
    await templatesDirectory.create(recursive: true);
    await File('${templatesDirectory.path}/other.json').writeAsString('{}');
    final future = File('${templatesDirectory.path}/Новый -- 1-2-3.json');
    await future.writeAsString(
      '{"schemaVersion": ${SchemaVersion.current + 1}}',
    );

    final templates = await store.list();
    expect(templates, hasLength(1));
    expect(() => store.read(templates.single), throwsFormatException);
  });

  test('rejects unsafe and empty titles', () {
    expect(store.validateTitle(''), isNotEmpty);
    expect(store.validateTitle('foo -- bar'), isNotEmpty);
    expect(store.validateTitle('foo/name'), isNotEmpty);
    expect(store.validateTitle('Хорошее имя'), isEmpty);
  });
}
