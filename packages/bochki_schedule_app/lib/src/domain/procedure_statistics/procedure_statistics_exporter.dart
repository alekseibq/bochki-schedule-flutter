import 'dart:io';
import 'procedure_statistics_document.dart';

abstract interface class ProcedureStatisticsExporter {
  Future<File> export(
      {required ProcedureStatisticsDocument document,
      required Directory outputDirectory});
}
