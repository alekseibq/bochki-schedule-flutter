import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop shell opens menu and participant dialog',
      (tester) async {
    final repository = _InMemoryParticipantsRepository();
    final services = AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      listParticipantsUseCase: ListParticipantsUseCase(repository),
      createParticipantUseCase: CreateParticipantUseCase(repository),
      updateParticipantUseCase: UpdateParticipantUseCase(repository),
      deleteParticipantUseCase: DeleteParticipantUseCase(repository),
      flushPending: _noopAsync,
      shutdown: _noopAsync,
    );

    await tester.pumpWidget(BochkiScheduleApp(services: services));
    await tester.pumpAndSettle();

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

    expect(
      find.byKey(const Key('participants_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список участников'), findsOneWidget);
    expect(find.text('Участники (0)'), findsOneWidget);
    expect(find.text('Добавить новую запись'), findsOneWidget);
  });
}

Future<void> _noopAsync() async {}

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

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  final List<Participant> _participants = <Participant>[];
  int _nextId = 1;

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final participant = Participant(
      id: (_nextId++).toString(),
      name: name,
    );
    _participants.add(participant);
    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    _participants.removeWhere((participant) => participant.id == participantId);
  }

  @override
  Future<List<Participant>> list() async {
    return [..._participants];
  }

  @override
  Future<Participant> update(Participant participant) async {
    final index = _participants.indexWhere(
      (candidate) => candidate.id == participant.id,
    );
    if (index != -1) {
      _participants[index] = participant;
    }
    return participant;
  }
}
