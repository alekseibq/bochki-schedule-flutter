final class ProcedureSessionTime {
  const ProcedureSessionTime._();

  static final RegExp _timePattern = RegExp(r'^\d{2}:\d{2}$');

  static bool isValid(String value) {
    if (!_timePattern.hasMatch(value)) {
      return false;
    }

    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(3, 5));
    if (hour == null || minute == null) {
      return false;
    }

    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  static int toMinutes(String value) {
    if (!isValid(value)) {
      throw ArgumentError.value(value, 'value', 'Time must be in hh:mm format');
    }

    final hour = int.parse(value.substring(0, 2));
    final minute = int.parse(value.substring(3, 5));
    return hour * 60 + minute;
  }

  static String fromMinutes(int value) {
    final normalized = value % (24 * 60);
    final safeValue = normalized < 0 ? normalized + (24 * 60) : normalized;
    final hour = (safeValue ~/ 60).toString().padLeft(2, '0');
    final minute = (safeValue % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
