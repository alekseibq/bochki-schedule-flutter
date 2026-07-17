import '../workdays/workday.dart';

import 'print_schedule_group_by.dart';
import 'print_schedule_row.dart';

final class PrintScheduleDocument {
  const PrintScheduleDocument({
    required this.workday,
    required this.groupBy,
    required this.title,
    required this.textBefore,
    required this.rows,
    required this.textAfter,
  });

  final Workday workday;
  final PrintScheduleGroupBy groupBy;
  final String title;
  final String textBefore;
  final List<PrintScheduleRow> rows;
  final String textAfter;
}
