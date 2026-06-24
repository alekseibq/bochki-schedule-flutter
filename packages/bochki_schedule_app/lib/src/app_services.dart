import 'dart:io';

import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

final class AppServices {
  const AppServices({
    required this.appDataDirectory,
    required this.logger,
    required this.projectDocumentStore,
  });

  final Directory appDataDirectory;
  final AppLogger logger;
  final ProjectDocumentStore projectDocumentStore;
}
