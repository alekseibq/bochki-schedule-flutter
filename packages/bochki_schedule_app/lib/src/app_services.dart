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
import 'domain/trainers/create_trainer_use_case.dart';
import 'domain/trainers/delete_trainer_use_case.dart';
import 'domain/trainers/list_trainers_use_case.dart';
import 'domain/trainers/update_trainer_use_case.dart';
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
    required this.listTrainersUseCase,
    required this.createTrainerUseCase,
    required this.updateTrainerUseCase,
    required this.deleteTrainerUseCase,
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
  final ListTrainersUseCase listTrainersUseCase;
  final CreateTrainerUseCase createTrainerUseCase;
  final UpdateTrainerUseCase updateTrainerUseCase;
  final DeleteTrainerUseCase deleteTrainerUseCase;
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
