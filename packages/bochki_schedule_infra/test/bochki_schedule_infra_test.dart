import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:test/test.dart';

void main() {
  test('package exports compile', () {
    expect(bochkiScheduleInfraPackageName, 'bochki_schedule_infra');
  });

  test('launch data directory resolves linux executable parent', () {
    final directoryPath = resolveLaunchAppDataDirectoryPath(
      resolvedExecutable: '/tmp/test-home/bin/bochki_schedule_app',
      operatingSystem: 'linux',
    );

    expect(directoryPath, '/tmp/test-home/bin');
  });

  test('launch data directory resolves windows executable parent', () {
    final directoryPath = resolveLaunchAppDataDirectoryPath(
      resolvedExecutable: r'C:\Users\Test\Desktop\bochki_schedule_app.exe',
      operatingSystem: 'windows',
    );

    expect(directoryPath, r'C:\Users\Test\Desktop');
  });

  test('launch data directory resolves macos app bundle sibling', () {
    final directoryPath = resolveLaunchAppDataDirectoryPath(
      resolvedExecutable:
          '/Applications/bochki_schedule_app.app/Contents/MacOS/bochki_schedule_app',
      operatingSystem: 'macos',
    );

    expect(directoryPath, '/Applications');
  });

  test('launch app data provider creates directory under launch root',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_launch_root_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final provider = LaunchAppDataDirectoryProvider(
      resolvedExecutable:
          '${tempDirectory.path}/bochki_schedule_app.app/Contents/MacOS/bochki_schedule_app',
      operatingSystem: 'macos',
    );

    final directory = await provider.getAppDataDirectory();

    expect(directory.path, tempDirectory.path);
    expect(await directory.exists(), isTrue);
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

  test('json project document repository reads and writes document', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_store_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/project.json');
    final repository = JsonProjectDocumentRepository(
      projectFile: file,
      safeFileWriter: const AtomicFileWriter(),
    );
    const document = ProjectDocument(
      schemaVersion: 1,
      nextId: 4,
      trainers: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Trainer One'},
      ],
      participants: <Map<String, Object?>>[
        <String, Object?>{
          'id': 2,
          'name': 'Participant One',
          'deleted': true,
        },
      ],
    );

    await repository.save(document);
    final restored = await repository.load();

    expect(restored, isNotNull);
    expect(restored.schemaVersion, 1);
    expect(restored.nextId, 4);
    expect(restored.trainers.single['name'], 'Trainer One');
    expect(restored.participants.single['name'], 'Participant One');
    expect(restored.participants.single['deleted'], isTrue);
  });

  test(
      'json project document repository returns initial document for missing file',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_store_missing');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/missing.json');
    final repository = JsonProjectDocumentRepository(
      projectFile: file,
      safeFileWriter: const AtomicFileWriter(),
    );

    final restored = await repository.load();

    expect(restored, ProjectDocument.initial());
  });
}
