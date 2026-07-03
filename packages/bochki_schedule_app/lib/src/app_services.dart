import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import 'domain/participants/create_participant_use_case.dart';
import 'domain/participants/delete_participant_use_case.dart';
import 'domain/participants/list_participants_use_case.dart';
import 'domain/participants/update_participant_use_case.dart';

final class AppServices {
  const AppServices({
    required this.appDataDirectory,
    required this.logger,
    required this.listParticipantsUseCase,
    required this.createParticipantUseCase,
    required this.updateParticipantUseCase,
    required this.deleteParticipantUseCase,
  });

  final Directory appDataDirectory;
  final AppLogger logger;
  final ListParticipantsUseCase listParticipantsUseCase;
  final CreateParticipantUseCase createParticipantUseCase;
  final UpdateParticipantUseCase updateParticipantUseCase;
  final DeleteParticipantUseCase deleteParticipantUseCase;
}
