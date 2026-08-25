import '../humans/human.dart';
import '../humans/list_humans_use_case.dart';
import '../procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../procedure_sessions/procedure_session_rich.dart';
import '../workdays/list_workdays_use_case.dart';
import '../workdays/workday.dart';
import 'procedure_statistics_document.dart';

final class BuildProcedureStatisticsDocumentUseCase {
  BuildProcedureStatisticsDocumentUseCase({
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required ListHumansUseCase listHumansUseCase,
    required ListRichProcedureSessionsUseCase listRichProcedureSessionsUseCase,
  })  : _listWorkdaysUseCase = listWorkdaysUseCase,
        _listHumansUseCase = listHumansUseCase,
        _listRichProcedureSessionsUseCase = listRichProcedureSessionsUseCase;

  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final ListHumansUseCase _listHumansUseCase;
  final ListRichProcedureSessionsUseCase _listRichProcedureSessionsUseCase;

  Future<ProcedureStatisticsDocument> execute() async {
    final workdays = await _listWorkdaysUseCase.execute();
    final humans = await _listHumansUseCase.execute();
    final sessions = await _listRichProcedureSessionsUseCase.execute();
    final ordered = List<ProcedureSessionRich>.of(sessions)..sort(_compare);
    final participantCounts = <String, int>{};
    final groupedCounts = <String, int>{};
    final cells = <String, List<ProcedureStatisticsLine>>{};
    for (final session in ordered) {
      final kind = session.procedureKind;
      final participantId = session.participantId;
      final key = '$participantId/${session.dayId}';
      final procedureName = kind?.shortName ?? 'Не найден';
      final assistantName = session.assistant?.shortName ?? 'Не найден';
      final pattern = kind?.patternId;
      if (participantId != null && pattern == 'single') {
        final countKey = '$participantId/${session.procedureKindId}';
        final next = (participantCounts[countKey] ?? 0) + 1;
        participantCounts[countKey] = next;
        _add(cells, key, ProcedureStatisticsTextLine('$next $procedureName'),
            section: _Section.participantSingle);
      } else if (participantId != null && pattern == 'curated') {
        _add(cells, key,
            ProcedureStatisticsTextLine('$procedureName - $assistantName'),
            section: _Section.participantCurated);
      }
      final assistantId = session.assistantId;
      if (assistantId != null && pattern == 'curated') {
        _add(cells, '$assistantId/${session.dayId}',
            ProcedureStatisticsTextLine(procedureName),
            section: _Section.assistedCurated);
      }
      if (participantId != null && pattern == 'grouped') {
        final countKey = '$participantId/${session.procedureKindId}';
        final next = (groupedCounts[countKey] ?? 0) + 1;
        groupedCounts[countKey] = next;
        _add(cells, key, ProcedureStatisticsTextLine('$procedureName $next+'),
            section: _Section.grouped);
      }
    }
    final participants = humans.where((item) => item.isParticipant).toList()
      ..sort(_compareHumans);
    final assistants = humans.where((item) => item.isAssistant).toList()
      ..sort(_compareHumans);
    return ProcedureStatisticsDocument(
      fileName: _fileName(workdays),
      pages: [
        for (var offset = 0;
            offset < workdays.length || (offset == 0 && workdays.isEmpty);
            offset += 4)
          () {
            final pageWorkdays = <Workday?>[
              for (var index = 0; index < 4; index++)
                offset + index < workdays.length
                    ? workdays[offset + index]
                    : null
            ];
            return ProcedureStatisticsPage(
              workdays: pageWorkdays,
              rows: [
                for (final human in participants)
                  _row(human, pageWorkdays, cells, isAssistant: false),
                const ProcedureStatisticsRow(name: 'Ассистенты', cells: []),
                for (final human in assistants)
                  _row(human, pageWorkdays, cells, isAssistant: true),
              ],
            );
          }(),
      ],
    );
  }

  String _fileName(List<Workday> workdays) {
    if (workdays.isEmpty) return 'statistika-po-soprovozhdeniyam.docx';
    String format(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return 'statistika-po-soprovozhdeniyam-${format(workdays.first.calendarDate)}-${format(workdays.last.calendarDate)}.docx';
  }

  ProcedureStatisticsRow _row(Human human, List<Workday?> workdays,
          Map<String, List<ProcedureStatisticsLine>> cells,
          {required bool isAssistant}) =>
      ProcedureStatisticsRow(
        name: human.shortName,
        cells: [
          for (final day in workdays)
            _cell(
                day == null
                    ? const []
                    : cells['${human.id}/${day.id}'] ?? const [],
                isAssistant)
        ],
      );

  ProcedureStatisticsCell _cell(
      List<ProcedureStatisticsLine> lines, bool isAssistant) {
    if (!isAssistant) {
      return ProcedureStatisticsCell([
        for (final line in lines)
          if (line is _SectionLine &&
              (line.section == _Section.participantCurated ||
                  line.section == _Section.participantSingle))
            ProcedureStatisticsTextLine(line.text),
      ]);
    }
    final ownCurated = <ProcedureStatisticsLine>[];
    final ownSingle = <ProcedureStatisticsLine>[];
    final assisted = <ProcedureStatisticsLine>[];
    final grouped = <ProcedureStatisticsLine>[];
    for (final line in lines) {
      if (line is _SectionLine) {
        switch (line.section) {
          case _Section.assistedCurated:
            assisted.add(ProcedureStatisticsTextLine(line.text));
          case _Section.grouped:
            grouped.add(ProcedureStatisticsTextLine(line.text));
          case _Section.participantCurated:
            ownCurated.add(ProcedureStatisticsTextLine(line.text));
          case _Section.participantSingle:
            ownSingle.add(ProcedureStatisticsTextLine(line.text));
        }
      }
    }
    final own = [...ownCurated, ...ownSingle];
    final result = <ProcedureStatisticsLine>[...own];
    if (own.isNotEmpty && assisted.isNotEmpty) {
      result.add(const ProcedureStatisticsDividerLine());
    }
    if (assisted.isNotEmpty) {
      result.add(ProcedureStatisticsTextLine(assisted
          .whereType<ProcedureStatisticsTextLine>()
          .map((e) => e.text)
          .join(', ')));
    }
    if ((own.isNotEmpty || assisted.isNotEmpty) && grouped.isNotEmpty) {
      result.add(const ProcedureStatisticsDividerLine());
    }
    result.addAll(grouped);
    return ProcedureStatisticsCell(result);
  }

  void _add(Map<String, List<ProcedureStatisticsLine>> target, String key,
          ProcedureStatisticsTextLine line, {_Section? section}) =>
      target
          .putIfAbsent(key, () => [])
          .add(section == null ? line : _SectionLine(line.text, section));
  int _compare(ProcedureSessionRich left, ProcedureSessionRich right) {
    final date = (left.day?.calendarDate ?? DateTime(9999))
        .compareTo(right.day?.calendarDate ?? DateTime(9999));
    if (date != 0) return date;
    final time = left.startTime.compareTo(right.startTime);
    return time != 0 ? time : left.id.compareTo(right.id);
  }

  int _compareHumans(Human left, Human right) =>
      left.name.toLowerCase().compareTo(right.name.toLowerCase());
}

enum _Section {
  participantCurated,
  participantSingle,
  assistedCurated,
  grouped,
}

final class _SectionLine extends ProcedureStatisticsLine {
  const _SectionLine(this.text, this.section);
  final String text;
  final _Section section;
}
