import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app_launch_arguments.dart';
import 'src/presentation/startup_diagnostics.dart';
import 'src/presentation/startup_launcher.dart';
import 'src/presentation/desktop_windows.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await currentDesktopWindowController();
  final kind = windowKindFromArguments(controller.arguments);
  if (kind != DesktopWindowKind.main) {
    await configureChildWindow(kind);
    runApp(kind == DesktopWindowKind.procedureStatistics
        ? const ProcedureStatisticsWindow()
        : kind == DesktopWindowKind.freeTime
            ? const FreeTimeWindow()
            : kind == DesktopWindowKind.procedureSession
                ? const ProcedureSessionWindow()
                : const DirectoryChildWindow());
    return;
  }
  final diagnostics = StartupDiagnostics();
  final errorReporter = _ApplicationErrorReporter(diagnostics);
  FlutterError.onError = errorReporter.recordFlutterError;
  PlatformDispatcher.instance.onError = errorReporter.recordPlatformError;

  runApp(
    StartupLauncher(
      diagnostics: diagnostics,
      configureWindow: _configureWindow,
      bootstrap: (diagnostics) => AppBootstrap.initialize(
        appDataDirectory: resolveAppDataDirectoryOverride(args),
        diagnostics: diagnostics,
      ),
      onServicesReady: errorReporter.attachServices,
    ),
  );
}

final class _ApplicationErrorReporter {
  _ApplicationErrorReporter(this._diagnostics);

  final StartupDiagnostics _diagnostics;
  AppServices? _services;

  void attachServices(AppServices services) {
    _services = services;
  }

  void recordFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _diagnostics.error(
      'Flutter framework',
      details.exception,
      details.stack ?? StackTrace.current,
    );
    unawaited(
      _services?.logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      ),
    );
  }

  bool recordPlatformError(Object error, StackTrace stackTrace) {
    _diagnostics.error('Платформа', error, stackTrace);
    unawaited(
      _services?.logger.error(
        'Unhandled platform error',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    return true;
  }
}

Future<void> _configureWindow() async {
  if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    return;
  }

  await windowManager.ensureInitialized();
  await initializeDesktopWindowLifecycle();
  const windowOptions = WindowOptions(
    title: 'ПО Расписание Бочки',
    size: Size(1200, 800),
    minimumSize: Size(1000, 700),
    center: true,
  );

  unawaited(windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  }));
}
