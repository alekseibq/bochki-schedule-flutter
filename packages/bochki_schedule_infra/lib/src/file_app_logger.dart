import 'dart:io';

abstract interface class AppLogger {
  Future<void> info(String message);

  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

final class FileAppLogger implements AppLogger {
  FileAppLogger({
    required this.logFile,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final File logFile;
  final DateTime Function() _clock;

  @override
  Future<void> info(String message) {
    return _writeLine('INFO', message);
  }

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | error=$error');
    }
    if (stackTrace != null) {
      buffer.write(' | stackTrace=$stackTrace');
    }

    return _writeLine('ERROR', buffer.toString());
  }

  Future<void> _writeLine(String level, String message) async {
    await logFile.parent.create(recursive: true);
    final timestamp = _clock().toUtc().toIso8601String();
    await logFile.writeAsString(
      '[$timestamp] $level $message\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}
