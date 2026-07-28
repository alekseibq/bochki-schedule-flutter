import 'dart:io';
import '../print_schedule/document_opener.dart';
import 'save_procedure_statistics_file_use_case.dart';

final class OpenProcedureStatisticsFileUseCase {
  OpenProcedureStatisticsFileUseCase(
      {required SaveProcedureStatisticsFileUseCase saveUseCase,
      required DocumentOpener documentOpener})
      : _saveUseCase = saveUseCase,
        _documentOpener = documentOpener;
  final SaveProcedureStatisticsFileUseCase _saveUseCase;
  final DocumentOpener _documentOpener;
  Future<File> execute() async {
    final file = await _saveUseCase.execute();
    await _documentOpener.open(file);
    return file;
  }
}
