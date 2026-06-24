import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop shell opens menu and switches sections', (tester) async {
    final services = AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      projectDocumentStore: const _NoopProjectDocumentStore(),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);

    await tester.tap(find.byKey(const Key('directories_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тренеры').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder_trainers')), findsOneWidget);

    await tester.tap(find.byKey(const Key('directories_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Участники').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder_participants')), findsOneWidget);
  });
}

final class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {}

  @override
  Future<void> info(String message) async {}
}

final class _NoopProjectDocumentStore implements ProjectDocumentStore {
  const _NoopProjectDocumentStore();

  @override
  Future<ProjectDocument?> read(File file) async => null;

  @override
  Future<void> write(File file, ProjectDocument document) async {}
}
