import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:path/path.dart' as p;

import 'app_services.dart';
import 'data/participants/project_document_participants_repository.dart';
import 'data/project_document/project_document_id_allocator.dart';
import 'data/project_document/project_document_sync_coordinator.dart';
import 'domain/participants/create_participant_use_case.dart';
import 'domain/participants/delete_participant_use_case.dart';
import 'domain/participants/list_participants_use_case.dart';
import 'domain/participants/update_participant_use_case.dart';

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
    final initialDocument = await projectDocumentRepository.load();
    final syncCoordinator = ProjectDocumentSyncCoordinator(
      repository: projectDocumentRepository,
      initialDocument: initialDocument,
      logger: logger,
    );
    final idAllocator = ProjectDocumentIdAllocator(
      nextId: initialDocument.nextId,
      onChanged: syncCoordinator.markChanged,
    );
    final participantsRepository = ProjectDocumentParticipantsRepository(
      initialDocument: initialDocument,
      idAllocator: idAllocator,
      onChanged: syncCoordinator.markChanged,
    );
    syncCoordinator.registerPart(idAllocator);
    syncCoordinator.registerPart(participantsRepository);
    final listParticipantsUseCase = ListParticipantsUseCase(
      participantsRepository,
    );
    final createParticipantUseCase = CreateParticipantUseCase(
      participantsRepository,
    );
    final updateParticipantUseCase = UpdateParticipantUseCase(
      participantsRepository,
    );
    final deleteParticipantUseCase = DeleteParticipantUseCase(
      participantsRepository,
    );

    await logger.info(
      'Bootstrap completed. appDataDirectory=${appDataDirectory.path}',
    );

    return AppServices(
      appDataDirectory: appDataDirectory,
      logger: logger,
      listParticipantsUseCase: listParticipantsUseCase,
      createParticipantUseCase: createParticipantUseCase,
      updateParticipantUseCase: updateParticipantUseCase,
      deleteParticipantUseCase: deleteParticipantUseCase,
      flushPending: syncCoordinator.flushPending,
      shutdown: syncCoordinator.shutdown,
    );
  }
}
