import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import 'domain/participants/create_participant_use_case.dart';
import 'domain/participants/delete_participant_use_case.dart';
import 'domain/participants/list_participants_use_case.dart';
import 'domain/participants/update_participant_use_case.dart';
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

final class AppServices {
  const AppServices({
    required this.appDataDirectory,
    required this.logger,
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
    required this.flushPending,
    required this.shutdown,
  });

  final Directory appDataDirectory;
  final AppLogger logger;
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
  final Future<void> Function() flushPending;
  final Future<void> Function() shutdown;
}
