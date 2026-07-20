import 'dart:io';

import 'package:flutter/material.dart';

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

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.error,
    super.key,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ПО Расписание Бочки',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: Center(
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD0D7DE)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFB00020),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось запустить приложение',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Произошла критическая ошибка во время запуска.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF0BBBB)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      describeStartupError(error),
                      style: const TextStyle(
                        color: Color(0xFF7A1C1C),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
