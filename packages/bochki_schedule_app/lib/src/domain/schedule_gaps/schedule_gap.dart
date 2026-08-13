import '../humans/human.dart';
import '../workdays/workday.dart';

final class ScheduleGap {
  const ScheduleGap({
    required this.workday,
    required this.human,
    required this.startMinutes,
    required this.endMinutes,
  });

  final Workday workday;
  final Human human;
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;
  String get startTime => _formatTime(startMinutes);
  String get endTime => _formatTime(endMinutes);
  String get durationLabel =>
      '${durationMinutes ~/ 60}ч ${(durationMinutes % 60).toString().padLeft(2, '0')}мин';

  static String _formatTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
