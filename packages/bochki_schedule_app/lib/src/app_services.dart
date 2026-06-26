import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import 'application/participants_directory_use_case.dart';

final class AppServices {
  const AppServices({
    required this.appDataDirectory,
    required this.logger,
    required this.participantsDirectoryUseCase,
  });

  final Directory appDataDirectory;
  final AppLogger logger;
  final ParticipantsDirectoryUseCase participantsDirectoryUseCase;
}
