import 'dart:io';

import 'print_schedule_document.dart';

abstract interface class PrintScheduleExporter {
  Future<File> export({
    required PrintScheduleDocument document,
    required Directory outputDirectory,
  });
}
