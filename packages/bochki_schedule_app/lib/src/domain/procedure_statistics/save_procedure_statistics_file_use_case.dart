import 'dart:io';
import 'build_procedure_statistics_document_use_case.dart';
import 'procedure_statistics_exporter.dart';

final class SaveProcedureStatisticsFileUseCase {
  SaveProcedureStatisticsFileUseCase(
      {required BuildProcedureStatisticsDocumentUseCase buildUseCase,
      required ProcedureStatisticsExporter exporter,
      required Directory appDataDirectory})
      : _buildUseCase = buildUseCase,
        _exporter = exporter,
        _outputDirectory = Directory('${appDataDirectory.path}/exports');
  final BuildProcedureStatisticsDocumentUseCase _buildUseCase;
  final ProcedureStatisticsExporter _exporter;
  final Directory _outputDirectory;
  Future<File> execute() async => _exporter.export(
      document: await _buildUseCase.execute(),
      outputDirectory: _outputDirectory);
}
