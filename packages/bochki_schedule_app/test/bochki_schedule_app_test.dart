import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

void main() {
  test('package exports compile', () {
    expect(BochkiScheduleApp, isNotNull);
  });

  testWidgets('shell shows top menu and default placeholder', (tester) async {
    final services = AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      projectDocumentStore: const _NoopProjectDocumentStore(),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);
    expect(find.text('В разработке'), findsOneWidget);
  });

  testWidgets('shell switches between directory placeholders', (tester) async {
    final services = AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      projectDocumentStore: const _NoopProjectDocumentStore(),
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));

    await tester.tap(find.byKey(const Key('directories_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тренеры').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder_trainers')), findsOneWidget);
    expect(find.text('Тренеры'), findsWidgets);

    await tester.tap(find.byKey(const Key('directories_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Участники').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder_participants')), findsOneWidget);
    expect(find.text('Участники'), findsWidgets);
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
