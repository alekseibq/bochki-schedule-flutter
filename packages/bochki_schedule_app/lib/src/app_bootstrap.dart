import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:path/path.dart' as p;

import 'app_services.dart';
import 'application/participants_directory_use_case.dart';

final class AppBootstrap {
  static const String appDirectoryName = 'bochki_schedule';

  static Future<AppServices> initialize() async {
    final appDataProvider = PlatformAppDataDirectoryProvider(
      appDirectoryName: appDirectoryName,
    );
    final appDataDirectory = await appDataProvider.getAppDataDirectory();
    final logger = FileAppLogger(
      logFile: File(p.join(appDataDirectory.path, 'logs', 'app.log')),
    );
    final projectDocumentRepository = JsonProjectDocumentRepository(
      projectFile: File(p.join(appDataDirectory.path, 'project.json')),
      safeFileWriter: const AtomicFileWriter(),
    );
    final participantsDirectoryUseCase = ParticipantsDirectoryUseCase(
      repository: projectDocumentRepository,
    );

    await logger.info(
      'Bootstrap completed. appDataDirectory=${appDataDirectory.path}',
    );

    return AppServices(
      appDataDirectory: appDataDirectory,
      logger: logger,
      participantsDirectoryUseCase: participantsDirectoryUseCase,
    );
  }
}
