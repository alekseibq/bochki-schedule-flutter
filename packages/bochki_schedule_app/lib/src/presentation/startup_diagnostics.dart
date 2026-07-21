import 'dart:io';

import 'package:flutter/foundation.dart';

enum StartupDiagnosticLevel { info, error }

final class StartupDiagnosticEntry {
  const StartupDiagnosticEntry({
    required this.timestamp,
    required this.level,
    required this.stage,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final StartupDiagnosticLevel level;
  final String stage;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Keeps launch diagnostics in memory so an unavailable data directory cannot
/// prevent the user from seeing the cause of a failed startup.
final class StartupDiagnostics extends ChangeNotifier {
  StartupDiagnostics({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<StartupDiagnosticEntry> _entries = <StartupDiagnosticEntry>[];

  List<StartupDiagnosticEntry> get entries => List.unmodifiable(_entries);

  void info(String stage, String message) {
    _add(
      StartupDiagnosticEntry(
        timestamp: _clock().toUtc(),
        level: StartupDiagnosticLevel.info,
        stage: stage,
        message: message,
      ),
    );
  }

  void error(String stage, Object error, StackTrace stackTrace) {
    _add(
      StartupDiagnosticEntry(
        timestamp: _clock().toUtc(),
        level: StartupDiagnosticLevel.error,
        stage: stage,
        message: describeStartupError(error),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  String buildReport() {
    final buffer = StringBuffer('Диагностика запуска ПО Расписание Бочки\n');
    for (final entry in _entries) {
      final level =
          entry.level == StartupDiagnosticLevel.info ? 'INFO' : 'ERROR';
      buffer.writeln(
        '[${entry.timestamp.toIso8601String()}] $level [${entry.stage}] ${entry.message}',
      );
      if (entry.error != null) {
        buffer.writeln('Ошибка: ${entry.error.runtimeType}: ${entry.error}');
      }
      if (entry.stackTrace != null) {
        buffer.writeln('Stack trace:\n${entry.stackTrace}');
      }
    }
    return buffer.toString().trimRight();
  }

  void _add(StartupDiagnosticEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }
}

String describeStartupError(Object error) {
  if (error is FileSystemException) {
    final path = error.path;
    final fileDescription = path == null || path.isEmpty
        ? 'файлу или папке приложения'
        : 'пути:\n$path';
    return 'Не удалось получить доступ к $fileDescription.\n${error.message}';
  }

  if (error is FormatException) {
    return 'Не удалось прочитать файл данных приложения. '
        'Возможно, project.json повреждён или имеет неподдерживаемый формат.\n'
        '${error.message}';
  }

  return error.toString();
}
