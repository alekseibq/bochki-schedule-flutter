import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:test/test.dart';

void main() {
  test('package exports compile', () {
    expect(bochkiScheduleInfraPackageName, 'bochki_schedule_infra');
  });

  test('platform app data provider uses linux fallback path', () async {
    final provider = PlatformAppDataDirectoryProvider(
      appDirectoryName: 'bochki_schedule',
      environment: const <String, String>{'HOME': '/tmp/test-home'},
      operatingSystem: 'linux',
    );

    final directory = await provider.getAppDataDirectory();

    expect(directory.path, '/tmp/test-home/.local/share/bochki_schedule');
  });

  test('platform app data provider uses APPDATA on windows', () async {
    final provider = PlatformAppDataDirectoryProvider(
      appDirectoryName: 'bochki_schedule',
      environment: const <String, String>{
        'APPDATA': r'C:\Users\Test\AppData\Roaming'
      },
      operatingSystem: 'windows',
    );

    final directory = await provider.getAppDataDirectory();

    expect(directory.path, r'C:\Users\Test\AppData\Roaming/bochki_schedule');
  });

  test('file logger appends log lines to file', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_logger_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final logFile = File('${tempDirectory.path}/app.log');
    final logger = FileAppLogger(
      logFile: logFile,
      clock: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
    );

    await logger.info('hello');
    await logger.error('failed', error: 'boom');

    final contents = await logFile.readAsString();

    expect(contents, contains('[2026-01-02T03:04:05.000Z] INFO hello'));
    expect(contents, contains('ERROR failed | error=boom'));
  });

  test('atomic file writer replaces existing file contents', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_writer_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final destination = File('${tempDirectory.path}/project.json');
    final writer = AtomicFileWriter();

    await writer.writeString(destination, 'first');
    await writer.writeString(destination, 'second');

    expect(await destination.readAsString(), 'second');

    final tempFiles = tempDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.tmp'))
        .toList(growable: false);
    expect(tempFiles, isEmpty);
  });

  test('json project document store reads and writes document', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_store_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/project.json');
    final store = JsonProjectDocumentStore(
      safeFileWriter: const AtomicFileWriter(),
    );
    const document = ProjectDocument(
      schemaVersion: 1,
      nextId: 4,
      trainers: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Trainer One'},
      ],
      participants: <Map<String, Object?>>[
        <String, Object?>{'id': 2, 'name': 'Participant One'},
      ],
    );

    await store.write(file, document);
    final restored = await store.read(file);

    expect(restored, isNotNull);
    expect(restored!.schemaVersion, 1);
    expect(restored.nextId, 4);
    expect(restored.trainers.single['name'], 'Trainer One');
    expect(restored.participants.single['name'], 'Participant One');
  });

  test('json project document store returns null for missing file', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_store_missing');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/missing.json');
    final store = JsonProjectDocumentStore(
      safeFileWriter: const AtomicFileWriter(),
    );

    final restored = await store.read(file);

    expect(restored, isNull);
  });
}
