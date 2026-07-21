import 'package:flutter/material.dart';

import '../app.dart';
import '../app_services.dart';
import 'startup_diagnostics.dart';
import 'startup_error_app.dart';

typedef StartupBootstrap = Future<AppServices> Function(
  StartupDiagnostics diagnostics,
);

class StartupLauncher extends StatefulWidget {
  const StartupLauncher({
    required this.diagnostics,
    required this.configureWindow,
    required this.bootstrap,
    this.onServicesReady,
    super.key,
  });

  final StartupDiagnostics diagnostics;
  final Future<void> Function() configureWindow;
  final StartupBootstrap bootstrap;
  final ValueChanged<AppServices>? onServicesReady;

  @override
  State<StartupLauncher> createState() => _StartupLauncherState();
}

class _StartupLauncherState extends State<StartupLauncher> {
  StartupStatus _status = StartupStatus.starting;
  AppServices? _services;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      widget.diagnostics.info('Окно', 'Настройка окна приложения.');
      await widget.configureWindow();
      widget.diagnostics.info('Окно', 'Настройка окна завершена.');
      widget.diagnostics
          .info('Инициализация', 'Запуск инициализации приложения.');
      final services = await widget.bootstrap(widget.diagnostics);
      widget.onServicesReady?.call(services);
      if (!mounted) {
        await services.shutdown();
        return;
      }
      setState(() {
        _services = services;
        _status = StartupStatus.ready;
      });
    } catch (error, stackTrace) {
      widget.diagnostics.error('Инициализация', error, stackTrace);
      if (mounted) {
        setState(() => _status = StartupStatus.failed);
      }
    }
  }

  void _continueToApplication() {
    setState(() => _status = StartupStatus.continued);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (_status == StartupStatus.continued && services != null) {
      return BochkiScheduleApp(services: services);
    }

    return StartupErrorApp(
      diagnostics: widget.diagnostics,
      status: _status,
      onContinue:
          _status == StartupStatus.ready ? _continueToApplication : null,
    );
  }
}
