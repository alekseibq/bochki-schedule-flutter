import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
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
    await services.flushPending();

    final logFile = File(p.join(tempRoot.path, 'logs', 'app.log'));
    final projectFile = File(p.join(tempRoot.path, 'project.json'));

    expect(await logFile.exists(), isTrue);
    expect(await projectFile.exists(), isTrue);
    expect(services.appDataDirectory.path, tempRoot.path);
    final projectContents = await projectFile.readAsString();
    expect(projectContents, contains('"procedureKinds"'));
  });

  test('bootstrap normalizes legacy resourceBusyTime for non-curated kinds',
      () async {
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
  });
}
