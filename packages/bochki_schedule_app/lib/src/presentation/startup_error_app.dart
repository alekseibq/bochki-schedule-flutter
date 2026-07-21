import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'startup_diagnostics.dart';

enum StartupStatus { starting, ready, failed, continued }

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.diagnostics,
    required this.status,
    this.onContinue,
    super.key,
  });

  final StartupDiagnostics diagnostics;
  final StartupStatus status;
  final VoidCallback? onContinue;

  bool get _hasFailed => status == StartupStatus.failed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ПО Расписание Бочки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF406882)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: 720,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                ),
                child: AnimatedBuilder(
                  animation: diagnostics,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _hasFailed
                            ? Icons.error_outline
                            : Icons.play_circle_outline,
                        size: 48,
                        color: _hasFailed
                            ? const Color(0xFFB00020)
                            : const Color(0xFF406882),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasFailed
                            ? 'Не удалось запустить приложение'
                            : 'Проверка запуска приложения',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hasFailed
                            ? 'Перезапустите приложение. Если ошибка повторится, скопируйте информацию и отправьте её в поддержку.'
                            : status == StartupStatus.ready
                                ? 'Проверка запуска завершена успешно. Проверьте журнал и продолжите работу.'
                                : 'Выполняется подготовка приложения. Журнал обновляется по мере запуска.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        key: const Key('startup_diagnostics_log'),
                        constraints: const BoxConstraints(maxHeight: 280),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasFailed
                              ? const Color(0xFFFFF4F4)
                              : const Color(0xFFF4F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hasFailed
                                ? const Color(0xFFF0BBBB)
                                : const Color(0xFFB9D2DF),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            diagnostics.buildReport(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (status == StartupStatus.starting)
                        const Center(child: CircularProgressIndicator())
                      else if (_hasFailed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            key: const Key('copy_startup_diagnostics_button'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: diagnostics.buildReport()),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Информация скопирована.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Копировать информацию'),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            key: const Key('continue_after_startup_button'),
                            onPressed: onContinue,
                            child: const Text('Всё ок. Продолжить'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
