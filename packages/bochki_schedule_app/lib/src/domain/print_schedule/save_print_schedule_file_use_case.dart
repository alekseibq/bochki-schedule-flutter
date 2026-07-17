import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../print_preset_params/update_print_preset_params_use_case.dart';
import 'build_print_schedule_document_use_case.dart';
import 'print_schedule_exporter.dart';
import 'print_schedule_group_by.dart';

final class SavePrintScheduleFileUseCase {
  SavePrintScheduleFileUseCase({
    required UpdatePrintPresetParamsUseCase updatePrintPresetParamsUseCase,
    required BuildPrintScheduleDocumentUseCase
        buildPrintScheduleDocumentUseCase,
    required PrintScheduleExporter printScheduleExporter,
    required Directory appDataDirectory,
  })  : _updatePrintPresetParamsUseCase = updatePrintPresetParamsUseCase,
        _buildPrintScheduleDocumentUseCase = buildPrintScheduleDocumentUseCase,
        _printScheduleExporter = printScheduleExporter,
        _outputDirectory = Directory('${appDataDirectory.path}/exports');

  final UpdatePrintPresetParamsUseCase _updatePrintPresetParamsUseCase;
  final BuildPrintScheduleDocumentUseCase _buildPrintScheduleDocumentUseCase;
  final PrintScheduleExporter _printScheduleExporter;
  final Directory _outputDirectory;

  Future<File> execute({
    required String workdayId,
    required String textBefore,
    required String textAfter,
    required PrintScheduleGroupBy groupBy,
  }) async {
    final params = await _updatePrintPresetParamsUseCase.execute(
      PrintPresetParams(
        workdayId: workdayId,
        textBefore: textBefore,
        textAfter: textAfter,
      ),
    );
    final document = await _buildPrintScheduleDocumentUseCase.execute(
      params: params,
      groupBy: groupBy,
    );

    return _printScheduleExporter.export(
      document: document,
      outputDirectory: _outputDirectory,
    );
  }
}
