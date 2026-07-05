import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_services.dart';
import 'presentation/shell/bochki_shell.dart';

class BochkiScheduleApp extends StatefulWidget {
  const BochkiScheduleApp({
    required this.services,
    super.key,
  });

  final AppServices services;

  @override
  State<BochkiScheduleApp> createState() => _BochkiScheduleAppState();
}

class _BochkiScheduleAppState extends State<BochkiScheduleApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _handleExitRequested,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(widget.services.shutdown());
    super.dispose();
  }

  Future<AppExitResponse> _handleExitRequested() async {
    try {
      await widget.services.shutdown();
      return AppExitResponse.exit;
    } catch (error, stackTrace) {
      await widget.services.logger.error(
        'Application shutdown failed',
        error: error,
        stackTrace: stackTrace,
      );
      return AppExitResponse.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ПО Расписание Бочки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF406882),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: BochkiShell(services: widget.services),
    );
  }
}
