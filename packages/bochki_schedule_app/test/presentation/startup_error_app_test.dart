import 'dart:io';

import 'package:bochki_schedule_app/src/presentation/startup_diagnostics.dart';
import 'package:bochki_schedule_app/src/presentation/startup_error_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('describes a file system startup error with its path', () {
    final description = describeStartupError(
      const FileSystemException('Operation not permitted', '/Applications'),
    );

    expect(description, contains('Не удалось получить доступ'));
    expect(description, contains('/Applications'));
    expect(description, contains('Operation not permitted'));
  });

  test('describes a malformed project document', () {
    final description = describeStartupError(
      const FormatException('Unexpected character'),
    );

    expect(description, contains('project.json'));
    expect(description, contains('Unexpected character'));
  });

  test('builds a copyable report with the error and its stack trace', () {
    final diagnostics = StartupDiagnostics(
      clock: () => DateTime.utc(2026, 7, 21),
    );
    diagnostics.info('Каталог данных', 'Каталог данных: /tmp/bochki');
    diagnostics.error(
      'Данные проекта',
      const FileSystemException('Operation not permitted', '/tmp/bochki'),
      StackTrace.fromString('trace line'),
    );

    final report = diagnostics.buildReport();

    expect(report, contains('Каталог данных: /tmp/bochki'));
    expect(report, contains('Operation not permitted'));
    expect(report, contains('trace line'));
  });

  testWidgets('shows continue button only after a successful startup',
      (tester) async {
    final diagnostics = StartupDiagnostics();
    diagnostics.info(
        'Bootstrap', 'Инициализация приложения завершена успешно.');

    await tester.pumpWidget(
      StartupErrorApp(
        diagnostics: diagnostics,
        status: StartupStatus.ready,
        onContinue: () {},
      ),
    );

    expect(find.byKey(const Key('startup_diagnostics_log')), findsOneWidget);
    expect(
        find.byKey(const Key('continue_after_startup_button')), findsOneWidget);
    expect(
        find.byKey(const Key('copy_startup_diagnostics_button')), findsNothing);
  });

  testWidgets('shows copy button and no continue button after a failed startup',
      (tester) async {
    final diagnostics = StartupDiagnostics();
    diagnostics.error(
      'Данные проекта',
      const FormatException('Unexpected character'),
      StackTrace.fromString('trace line'),
    );

    await tester.pumpWidget(
      StartupErrorApp(
        diagnostics: diagnostics,
        status: StartupStatus.failed,
      ),
    );

    expect(find.byKey(const Key('copy_startup_diagnostics_button')),
        findsOneWidget);
    expect(
        find.byKey(const Key('continue_after_startup_button')), findsNothing);
    expect(find.textContaining('Перезапустите приложение'), findsOneWidget);
  });
}
