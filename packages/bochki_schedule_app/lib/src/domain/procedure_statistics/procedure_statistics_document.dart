import '../workdays/workday.dart';

final class ProcedureStatisticsDocument {
  const ProcedureStatisticsDocument({
    required this.pages,
    required this.fileName,
  });

  final List<ProcedureStatisticsPage> pages;
  final String fileName;
}

final class ProcedureStatisticsPage {
  const ProcedureStatisticsPage({required this.workdays, required this.rows});

  final List<Workday?> workdays;
  final List<ProcedureStatisticsRow> rows;
}

final class ProcedureStatisticsRow {
  const ProcedureStatisticsRow({required this.name, required this.cells});

  final String name;
  final List<ProcedureStatisticsCell> cells;
}

final class ProcedureStatisticsCell {
  const ProcedureStatisticsCell(this.lines);

  final List<ProcedureStatisticsLine> lines;
}

abstract class ProcedureStatisticsLine {
  const ProcedureStatisticsLine();
}

final class ProcedureStatisticsTextLine extends ProcedureStatisticsLine {
  const ProcedureStatisticsTextLine(this.text);

  final String text;
}

final class ProcedureStatisticsDividerLine extends ProcedureStatisticsLine {
  const ProcedureStatisticsDividerLine();
}
