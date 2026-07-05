import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app_launch_arguments.dart';
import 'src/presentation/startup_error_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();

  AppServices? services;

  try {
    services = await AppBootstrap.initialize(
      appDataDirectory: resolveAppDataDirectoryOverride(args),
    );
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        services?.logger.error(
          'Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        services?.logger.error(
          'Unhandled platform error',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return true;
    };

    runApp(BochkiScheduleApp(services: services));
  } catch (error, stackTrace) {
    await services?.logger.error(
      'Application bootstrap failed',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(const StartupErrorApp());
  }
}

Future<void> _configureWindow() async {
  if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    return;
  }

  await windowManager.ensureInitialized();
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
