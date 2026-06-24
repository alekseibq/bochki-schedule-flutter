import 'package:flutter/material.dart';

import 'app_services.dart';
import 'presentation/shell/bochki_shell.dart';

class BochkiScheduleApp extends StatelessWidget {
  const BochkiScheduleApp({
    required this.services,
    super.key,
  });

  final AppServices services;

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
      home: BochkiShell(services: services),
    );
  }
}
