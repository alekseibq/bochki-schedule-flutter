import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../procedure_sessions/procedure_session_rich.dart';
import '../workdays/list_workdays_use_case.dart';
import '../workdays/workday.dart';
import 'print_schedule_document.dart';
import 'print_schedule_group_by.dart';
import 'print_schedule_row.dart';

final class BuildPrintScheduleDocumentUseCase {
  BuildPrintScheduleDocumentUseCase({
    required ListRichProcedureSessionsUseCase listRichProcedureSessionsUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
  })  : _listRichProcedureSessionsUseCase = listRichProcedureSessionsUseCase,
        _listWorkdaysUseCase = listWorkdaysUseCase;

  final ListRichProcedureSessionsUseCase _listRichProcedureSessionsUseCase;
  final ListWorkdaysUseCase _listWorkdaysUseCase;

  Future<PrintScheduleDocument> execute({
    required PrintPresetParams params,
    required PrintScheduleGroupBy groupBy,
  }) async {
    final workdays = await _listWorkdaysUseCase.execute();
    final workday = workdays.firstWhere(
      (entry) => entry.id == params.workdayId,
      orElse: () => throw StateError('Workday ${params.workdayId} not found.'),
    );
    final sessions = await _listRichProcedureSessionsUseCase.execute();
    final rows = _buildRows(
      sessions: sessions,
      workday: workday,
      groupBy: groupBy,
    );

    return PrintScheduleDocument(
      workday: workday,
      groupBy: groupBy,
      title: 'Дата расписания ${_formatDate(workday.calendarDate)}',
      textBefore: params.textBefore,
      rows: rows,
      textAfter: params.textAfter,
    );
  }

  List<PrintScheduleRow> _buildRows({
    required List<ProcedureSessionRich> sessions,
    required Workday workday,
    required PrintScheduleGroupBy groupBy,
  }) {
    final rows = [
      for (final session in sessions)
        if (session.dayId == workday.id)
          _PrintScheduleRowWithSortData(
            id: session.id,
            participantSortKey: _sortKey(session.participant?.name),
            procedureSortKey: _sortKey(session.procedureKind?.name),
            row: PrintScheduleRow(
              participantName: session.participant?.name ?? 'Не найден',
              startTime: session.startTime,
              procedureName: session.procedureKind?.name ?? 'Не найдено',
              assistantName: session.assistant?.name ?? '',
            ),
          ),
    ];

    rows.sort((left, right) {
      switch (groupBy) {
        case PrintScheduleGroupBy.byNames:
          final byParticipant =
              left.participantSortKey.compareTo(right.participantSortKey);
          if (byParticipant != 0) {
            return byParticipant;
          }
          break;
        case PrintScheduleGroupBy.byTime:
          final byTime = left.row.startTime.compareTo(right.row.startTime);
          if (byTime != 0) {
            return byTime;
          }
          break;
      }

      final byFallbackTime = left.row.startTime.compareTo(right.row.startTime);
      if (byFallbackTime != 0) {
        return byFallbackTime;
      }

      final byFallbackParticipant =
          left.participantSortKey.compareTo(right.participantSortKey);
      if (byFallbackParticipant != 0) {
        return byFallbackParticipant;
      }

      final byProcedure =
          left.procedureSortKey.compareTo(right.procedureSortKey);
      if (byProcedure != 0) {
        return byProcedure;
      }

      return left.id.compareTo(right.id);
    });

    return List<PrintScheduleRow>.unmodifiable([
      for (final row in rows) row.row,
    ]);
  }

  String _sortKey(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }
}

final class _PrintScheduleRowWithSortData {
  const _PrintScheduleRowWithSortData({
    required this.id,
    required this.participantSortKey,
    required this.procedureSortKey,
    required this.row,
  });

  final String id;
  final String participantSortKey;
  final String procedureSortKey;
  final PrintScheduleRow row;
}
