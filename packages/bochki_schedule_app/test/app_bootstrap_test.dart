import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('bootstrap uses the provided app data directory override', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'bochki_bootstrap_test',
    );
    final services = await AppBootstrap.initialize(
      appDataDirectory: tempRoot,
    );
    addTearDown(() async {
      await services.shutdown();
      await tempRoot.delete(recursive: true);
    });

    await services.logger.info('bootstrap smoke');
    await services.createParticipantUseCase.execute('Иван');
    await services.createProcedureKindUseCase.execute(
      ProcedureKind(
        id: 'draft',
        patternId: ProcedureKindPatterns.curated.patternId,
        name: 'Основная баня',
        capacity: 6,
        participantBusyTime: 30,
        assistantBusyTime: 20,
        resourceBusyTime: 15,
      ),
    );
    await services.updatePrintPresetParamsUseCase.execute(
      const PrintPresetParams(
        workdayId: '1',
        textBefore: 'Текст в начале',
        textAfter: 'Текст в конце',
      ),
    );
    await services.flushPending();

    final logFile = File(p.join(tempRoot.path, 'logs', 'app.log'));
    final projectFile = File(p.join(tempRoot.path, 'project.json'));

    expect(await logFile.exists(), isTrue);
    expect(await projectFile.exists(), isTrue);
    expect(services.appDataDirectory.path, tempRoot.path);
    final projectContents = await projectFile.readAsString();
    expect(projectContents, contains('"procedureKinds"'));
    expect(projectContents, contains('"printPresetParams"'));
  });

  test('bootstrap normalizes legacy procedure kind values', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'bochki_bootstrap_legacy_test',
    );
    final projectFile = File(p.join(tempRoot.path, 'project.json'));
    await projectFile.create(recursive: true);
    await projectFile.writeAsString('''
{
  "nextId": 3,
  "procedureKinds": [
    {
      "id": 1,
      "patternId": "single",
      "name": "Бег",
      "capacity": 2,
      "participantBusyTime": 20,
      "deleted": false
    }
  ]
}
''');

    final services = await AppBootstrap.initialize(
      appDataDirectory: tempRoot,
    );
    addTearDown(() async {
      await services.shutdown();
      await tempRoot.delete(recursive: true);
    });

    final projectContents = await projectFile.readAsString();
    expect(projectContents, contains('"resourceBusyTime": 20'));
    expect(projectContents, contains('"shortName": "Бег"'));
  });

  test('loading a template replaces every project data source after restart',
      () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'bochki_bootstrap_template_load_test',
    );
    final services = await AppBootstrap.initialize(appDataDirectory: tempRoot);
    addTearDown(() => tempRoot.delete(recursive: true));

    const templateDocument = ProjectDocument(
      nextId: 50,
      humans: [
        <String, Object?>{
          'id': 10,
          'name': 'Новый участник',
          'shortName': 'Новый',
          'isParticipant': true,
          'isAssistant': false,
          'deleted': false,
        },
        <String, Object?>{
          'id': 11,
          'name': 'Новый ассистент',
          'shortName': 'Ассистент',
          'isParticipant': false,
          'isAssistant': true,
          'deleted': false,
        },
      ],
      procedureKinds: [
        <String, Object?>{
          'id': 12,
          'patternId': 'single',
          'name': 'Новая процедура',
          'shortName': 'Новая',
          'capacity': 1,
          'participantBusyTime': 30,
          'resourceBusyTime': 30,
          'deleted': false,
        },
      ],
      workdays: [
        <String, Object?>{
          'id': 13,
          'name': 'Новый день',
          'calendarDate': '2026-08-20',
          'deleted': false,
        },
      ],
      procedureSessions: [
        <String, Object?>{
          'id': 14,
          'dayId': 13,
          'participantId': 10,
          'startTime': '10:00',
          'procedureKindId': 12,
          'assistantId': 11,
          'deleted': false,
        },
      ],
      programSettings: ProgramSettings(
        lunchStart: ProgramSettingsTime(hour: 12, minute: 0),
        lunchEnd: ProgramSettingsTime(hour: 13, minute: 0),
        minimumTime: ProgramSettingsTime(hour: 7, minute: 0),
        maximumTime: ProgramSettingsTime(hour: 22, minute: 0),
      ),
      printPresetParams: PrintPresetParams(
        workdayId: '13',
        textBefore: 'Начало шаблона',
        textAfter: 'Конец шаблона',
      ),
    );
    final store = TemplateFileStore(
      appDataDirectory: tempRoot,
      safeFileWriter: const AtomicFileWriter(),
    );
    final template = await store.save(
      title: 'Полная замена',
      document: templateDocument,
    );

    await services.createParticipantUseCase.execute('Старый участник');
    await services.flushPending();
    await services.templateService!.load(template);
    await services.shutdown();

    final reloaded = await AppBootstrap.initialize(appDataDirectory: tempRoot);
    addTearDown(reloaded.shutdown);

    expect(
      (await reloaded.listParticipantsUseCase.execute()).single.name,
      'Новый участник',
    );
    expect(
      (await reloaded.listAssistantsUseCase.execute()).single.name,
      'Новый ассистент',
    );
    expect((await reloaded.listWorkdaysUseCase.execute()).single.name,
        'Новый день');
    expect((await reloaded.listProcedureKindsUseCase.execute()).single.name,
        'Новая процедура');
    expect(
      (await reloaded.listProcedureSessionsUseCase.execute()).single.id,
      '14',
    );
    final reloadedProgramSettings =
        await reloaded.getProgramSettingsUseCase.execute();
    expect(reloadedProgramSettings.lunchStart.hour,
        templateDocument.programSettings.lunchStart.hour);
    expect(reloadedProgramSettings.lunchStart.minute,
        templateDocument.programSettings.lunchStart.minute);
    expect(reloadedProgramSettings.lunchEnd.hour,
        templateDocument.programSettings.lunchEnd.hour);
    expect(reloadedProgramSettings.lunchEnd.minute,
        templateDocument.programSettings.lunchEnd.minute);
    expect(reloadedProgramSettings.minimumTime.hour,
        templateDocument.programSettings.minimumTime.hour);
    expect(reloadedProgramSettings.minimumTime.minute,
        templateDocument.programSettings.minimumTime.minute);
    expect(reloadedProgramSettings.maximumTime.hour,
        templateDocument.programSettings.maximumTime.hour);
    expect(reloadedProgramSettings.maximumTime.minute,
        templateDocument.programSettings.maximumTime.minute);
    final reloadedPrintPresetParams =
        await reloaded.getPrintPresetParamsUseCase.execute();
    expect(
      reloadedPrintPresetParams.workdayId,
      templateDocument.printPresetParams.workdayId,
    );
    expect(
      reloadedPrintPresetParams.textBefore,
      templateDocument.printPresetParams.textBefore,
    );
    expect(
      reloadedPrintPresetParams.textAfter,
      templateDocument.printPresetParams.textAfter,
    );
    expect(
      (await reloaded.createParticipantUseCase.execute('Следующий')).id,
      '50',
    );
  });

  test('an unreadable template leaves the current project unchanged', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'bochki_bootstrap_bad_template_test',
    );
    final services = await AppBootstrap.initialize(appDataDirectory: tempRoot);
    addTearDown(() async {
      await services.shutdown();
      await tempRoot.delete(recursive: true);
    });
    await services.createParticipantUseCase.execute('Текущий участник');
    await services.flushPending();
    final projectFile = File(p.join(tempRoot.path, 'project.json'));
    final beforeLoad = await projectFile.readAsString();
    final invalidTemplate = TemplateFile(
      file: File(
          p.join(tempRoot.path, 'saved-patterns', 'Повреждён -- 0-0-0.json')),
      title: 'Повреждён',
      workdays: 0,
      participants: 0,
      assistants: 0,
    );
    await invalidTemplate.file.parent.create(recursive: true);
    await invalidTemplate.file.writeAsString('{"schemaVersion": 999}');

    await expectLater(
      services.templateService!.load(invalidTemplate),
      throwsFormatException,
    );

    expect(await projectFile.readAsString(), beforeLoad);
    expect(
      (await services.listParticipantsUseCase.execute()).single.name,
      'Текущий участник',
    );
  });
}
