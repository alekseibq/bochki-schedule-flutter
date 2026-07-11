import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:path/path.dart' as p;

import 'app_services.dart';
import 'data/humans/project_document_humans_repository.dart';
import 'data/participants/project_document_participants_repository.dart';
import 'data/project_document/project_document_id_allocator.dart';
import 'data/project_document/project_document_sync_coordinator.dart';
import 'data/procedure_sessions/project_document_procedure_sessions_repository.dart';
import 'data/procedure_kinds/project_document_procedure_kinds_repository.dart';
import 'data/assistants/project_document_assistants_repository.dart';
import 'data/workdays/project_document_workdays_repository.dart';
import 'domain/humans/list_humans_use_case.dart';
import 'domain/participants/create_participant_use_case.dart';
import 'domain/participants/delete_participant_use_case.dart';
import 'domain/participants/list_participants_use_case.dart';
import 'domain/participants/update_participant_use_case.dart';
import 'domain/procedure_sessions/create_procedure_session_use_case.dart';
import 'domain/procedure_sessions/delete_procedure_session_use_case.dart';
import 'domain/procedure_sessions/list_procedure_sessions_use_case.dart';
import 'domain/procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import 'domain/procedure_sessions/update_procedure_session_use_case.dart';
import 'domain/procedure_kinds/create_procedure_kind_use_case.dart';
import 'domain/procedure_kinds/delete_procedure_kind_use_case.dart';
import 'domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import 'domain/procedure_kinds/update_procedure_kind_use_case.dart';
import 'domain/assistants/create_assistant_use_case.dart';
import 'domain/assistants/delete_assistant_use_case.dart';
import 'domain/assistants/list_assistants_use_case.dart';
import 'domain/assistants/update_assistant_use_case.dart';
import 'domain/workdays/create_workday_use_case.dart';
import 'domain/workdays/delete_workday_use_case.dart';
import 'domain/workdays/list_workdays_use_case.dart';
import 'domain/workdays/update_workday_use_case.dart';

final class AppBootstrap {
  static Future<AppServices> initialize({
    Directory? appDataDirectory,
  }) async {
    final resolvedAppDataDirectory = appDataDirectory ??
        await LaunchAppDataDirectoryProvider().getAppDataDirectory();
    final logger = FileAppLogger(
      logFile: File(p.join(resolvedAppDataDirectory.path, 'logs', 'app.log')),
    );
    final projectDocumentRepository = JsonProjectDocumentRepository(
      projectFile: File(p.join(resolvedAppDataDirectory.path, 'project.json')),
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
    final humansRepository = ProjectDocumentHumansRepository(
      initialDocument: initialDocument,
      idAllocator: idAllocator,
      onChanged: syncCoordinator.markChanged,
    );
    final participantsRepository = ProjectDocumentParticipantsRepository(
      humansRepository: humansRepository,
    );
    final assistantsRepository = ProjectDocumentAssistantsRepository(
      humansRepository: humansRepository,
    );
    final procedureKindsRepository = ProjectDocumentProcedureKindsRepository(
      initialDocument: initialDocument,
      idAllocator: idAllocator,
      onChanged: syncCoordinator.markChanged,
    );
    final workdaysRepository = ProjectDocumentWorkdaysRepository(
      initialDocument: initialDocument,
      idAllocator: idAllocator,
      onChanged: syncCoordinator.markChanged,
    );
    final procedureSessionsRepository =
        ProjectDocumentProcedureSessionsRepository(
      initialDocument: initialDocument,
      idAllocator: idAllocator,
      onChanged: syncCoordinator.markChanged,
    );
    syncCoordinator.registerPart(idAllocator);
    syncCoordinator.registerPart(humansRepository);
    syncCoordinator.registerPart(procedureKindsRepository);
    syncCoordinator.registerPart(workdaysRepository);
    syncCoordinator.registerPart(procedureSessionsRepository);
    final listHumansUseCase = ListHumansUseCase(humansRepository);
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
    final listAssistantsUseCase = ListAssistantsUseCase(
      assistantsRepository,
    );
    final createAssistantUseCase = CreateAssistantUseCase(
      assistantsRepository,
    );
    final updateAssistantUseCase = UpdateAssistantUseCase(
      assistantsRepository,
    );
    final deleteAssistantUseCase = DeleteAssistantUseCase(
      assistantsRepository,
    );
    final listProcedureKindsUseCase = ListProcedureKindsUseCase(
      procedureKindsRepository,
    );
    final createProcedureKindUseCase = CreateProcedureKindUseCase(
      procedureKindsRepository,
    );
    final updateProcedureKindUseCase = UpdateProcedureKindUseCase(
      procedureKindsRepository,
    );
    final deleteProcedureKindUseCase = DeleteProcedureKindUseCase(
      procedureKindsRepository,
    );
    final listWorkdaysUseCase = ListWorkdaysUseCase(
      workdaysRepository,
    );
    final createWorkdayUseCase = CreateWorkdayUseCase(
      workdaysRepository,
    );
    final updateWorkdayUseCase = UpdateWorkdayUseCase(
      workdaysRepository,
    );
    final deleteWorkdayUseCase = DeleteWorkdayUseCase(
      workdaysRepository,
    );
    final listProcedureSessionsUseCase = ListProcedureSessionsUseCase(
      procedureSessionsRepository,
    );
    final listRichProcedureSessionsUseCase = ListRichProcedureSessionsUseCase(
      listProcedureSessionsUseCase: listProcedureSessionsUseCase,
      listWorkdaysUseCase: listWorkdaysUseCase,
      listHumansUseCase: listHumansUseCase,
      listProcedureKindsUseCase: listProcedureKindsUseCase,
      listAssistantsUseCase: listAssistantsUseCase,
    );
    final createProcedureSessionUseCase = CreateProcedureSessionUseCase(
      procedureSessionsRepository,
      workdaysRepository: workdaysRepository,
      humansRepository: humansRepository,
      procedureKindsRepository: procedureKindsRepository,
      assistantsRepository: assistantsRepository,
    );
    final updateProcedureSessionUseCase = UpdateProcedureSessionUseCase(
      procedureSessionsRepository,
      workdaysRepository: workdaysRepository,
      humansRepository: humansRepository,
      procedureKindsRepository: procedureKindsRepository,
      assistantsRepository: assistantsRepository,
    );
    final deleteProcedureSessionUseCase = DeleteProcedureSessionUseCase(
      procedureSessionsRepository,
    );

    await logger.info(
      'Bootstrap completed. appDataDirectory=${resolvedAppDataDirectory.path}',
    );

    return AppServices(
      appDataDirectory: resolvedAppDataDirectory,
      logger: logger,
      listHumansUseCase: listHumansUseCase,
      listParticipantsUseCase: listParticipantsUseCase,
      createParticipantUseCase: createParticipantUseCase,
      updateParticipantUseCase: updateParticipantUseCase,
      deleteParticipantUseCase: deleteParticipantUseCase,
      listAssistantsUseCase: listAssistantsUseCase,
      createAssistantUseCase: createAssistantUseCase,
      updateAssistantUseCase: updateAssistantUseCase,
      deleteAssistantUseCase: deleteAssistantUseCase,
      listProcedureKindsUseCase: listProcedureKindsUseCase,
      createProcedureKindUseCase: createProcedureKindUseCase,
      updateProcedureKindUseCase: updateProcedureKindUseCase,
      deleteProcedureKindUseCase: deleteProcedureKindUseCase,
      listWorkdaysUseCase: listWorkdaysUseCase,
      createWorkdayUseCase: createWorkdayUseCase,
      updateWorkdayUseCase: updateWorkdayUseCase,
      deleteWorkdayUseCase: deleteWorkdayUseCase,
      listProcedureSessionsUseCase: listProcedureSessionsUseCase,
      listRichProcedureSessionsUseCase: listRichProcedureSessionsUseCase,
      createProcedureSessionUseCase: createProcedureSessionUseCase,
      updateProcedureSessionUseCase: updateProcedureSessionUseCase,
      deleteProcedureSessionUseCase: deleteProcedureSessionUseCase,
      flushPending: syncCoordinator.flushPending,
      shutdown: syncCoordinator.shutdown,
    );
  }
}
