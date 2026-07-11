import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

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
import 'domain/program_settings/get_program_settings_use_case.dart';
import 'domain/program_settings/update_program_settings_use_case.dart';
import 'domain/assistants/create_assistant_use_case.dart';
import 'domain/assistants/delete_assistant_use_case.dart';
import 'domain/assistants/list_assistants_use_case.dart';
import 'domain/assistants/update_assistant_use_case.dart';
import 'domain/workdays/create_workday_use_case.dart';
import 'domain/workdays/delete_workday_use_case.dart';
import 'domain/workdays/list_workdays_use_case.dart';
import 'domain/workdays/update_workday_use_case.dart';

final class AppServices {
  const AppServices({
    required this.appDataDirectory,
    required this.logger,
    required this.listHumansUseCase,
    required this.listParticipantsUseCase,
    required this.createParticipantUseCase,
    required this.updateParticipantUseCase,
    required this.deleteParticipantUseCase,
    required this.listAssistantsUseCase,
    required this.createAssistantUseCase,
    required this.updateAssistantUseCase,
    required this.deleteAssistantUseCase,
    required this.listProcedureKindsUseCase,
    required this.createProcedureKindUseCase,
    required this.updateProcedureKindUseCase,
    required this.deleteProcedureKindUseCase,
    required this.listWorkdaysUseCase,
    required this.createWorkdayUseCase,
    required this.updateWorkdayUseCase,
    required this.deleteWorkdayUseCase,
    required this.getProgramSettingsUseCase,
    required this.updateProgramSettingsUseCase,
    required this.listProcedureSessionsUseCase,
    required this.listRichProcedureSessionsUseCase,
    required this.createProcedureSessionUseCase,
    required this.updateProcedureSessionUseCase,
    required this.deleteProcedureSessionUseCase,
    required this.flushPending,
    required this.shutdown,
  });

  final Directory appDataDirectory;
  final AppLogger logger;
  final ListHumansUseCase listHumansUseCase;
  final ListParticipantsUseCase listParticipantsUseCase;
  final CreateParticipantUseCase createParticipantUseCase;
  final UpdateParticipantUseCase updateParticipantUseCase;
  final DeleteParticipantUseCase deleteParticipantUseCase;
  final ListAssistantsUseCase listAssistantsUseCase;
  final CreateAssistantUseCase createAssistantUseCase;
  final UpdateAssistantUseCase updateAssistantUseCase;
  final DeleteAssistantUseCase deleteAssistantUseCase;
  final ListProcedureKindsUseCase listProcedureKindsUseCase;
  final CreateProcedureKindUseCase createProcedureKindUseCase;
  final UpdateProcedureKindUseCase updateProcedureKindUseCase;
  final DeleteProcedureKindUseCase deleteProcedureKindUseCase;
  final ListWorkdaysUseCase listWorkdaysUseCase;
  final CreateWorkdayUseCase createWorkdayUseCase;
  final UpdateWorkdayUseCase updateWorkdayUseCase;
  final DeleteWorkdayUseCase deleteWorkdayUseCase;
  final GetProgramSettingsUseCase getProgramSettingsUseCase;
  final UpdateProgramSettingsUseCase updateProgramSettingsUseCase;
  final ListProcedureSessionsUseCase listProcedureSessionsUseCase;
  final ListRichProcedureSessionsUseCase listRichProcedureSessionsUseCase;
  final CreateProcedureSessionUseCase createProcedureSessionUseCase;
  final UpdateProcedureSessionUseCase updateProcedureSessionUseCase;
  final DeleteProcedureSessionUseCase deleteProcedureSessionUseCase;
  final Future<void> Function() flushPending;
  final Future<void> Function() shutdown;
}
