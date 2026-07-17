import 'dart:io';

import 'document_opener.dart';
import 'print_schedule_group_by.dart';
import 'save_print_schedule_file_use_case.dart';

final class OpenPrintScheduleFileUseCase {
  OpenPrintScheduleFileUseCase({
    required SavePrintScheduleFileUseCase savePrintScheduleFileUseCase,
    required DocumentOpener documentOpener,
  })  : _savePrintScheduleFileUseCase = savePrintScheduleFileUseCase,
        _documentOpener = documentOpener;

  final SavePrintScheduleFileUseCase _savePrintScheduleFileUseCase;
  final DocumentOpener _documentOpener;

  Future<File> execute({
    required String workdayId,
    required String textBefore,
    required String textAfter,
    required PrintScheduleGroupBy groupBy,
  }) async {
    final file = await _savePrintScheduleFileUseCase.execute(
      workdayId: workdayId,
      textBefore: textBefore,
      textAfter: textAfter,
      groupBy: groupBy,
    );
    await _documentOpener.open(file);
    return file;
  }
}
