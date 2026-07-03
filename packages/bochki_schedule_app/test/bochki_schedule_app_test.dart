import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('package exports compile', () {
    expect(BochkiScheduleApp, isNotNull);
  });

  testWidgets('shell shows top menu and default placeholder', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    expect(find.text('ПО Расписание Бочки'), findsOneWidget);
    expect(find.text('Справочники'), findsOneWidget);
    expect(find.text('В разработке'), findsOneWidget);
  });

  testWidgets('shell opens participants dialog from menu', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

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
    expect(find.text('Ok'), findsOneWidget);
  });

  testWidgets('participants dialog supports inline add edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('directories_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Участники').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      '  Иван   Иванов  ',
    );
    await tester.tap(find.text('Участники (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Иван Иванов'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Иван Иванов');
    expect(find.text('Участники (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Борис',
    );
    await tester.tap(find.text('Участники (1)'));
    await tester.pumpAndSettle();

    expect(
      context.repository.participants.map((participant) => participant.name),
      ['Иван Иванов', 'Борис'],
    );

    final firstRow = find.byKey(const Key('participant_row_1'));
    await _mouseClick(tester, firstRow);
    await tester.pump(const Duration(milliseconds: 50));
    await _mouseClick(tester, firstRow);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Иван Петров',
    );

    await _mouseClick(tester, find.byKey(const Key('participant_row_2')));
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(find.text('Иван Иванов'), findsNothing);
    expect(context.repository.participants.first.name, 'Иван Петров');

    final borisRow = find.byKey(const Key('participant_row_2'));
    await _mouseClick(
      tester,
      borisRow,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
        context.repository.participants.map((participant) => participant.name),
        [
          'Иван Петров',
        ]);
    expect(find.text('Участники (1)'), findsOneWidget);
  });
}

Future<void> _mouseClick(
  WidgetTester tester,
  Finder finder, {
  int buttons = kPrimaryMouseButton,
}) async {
  final gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: buttons,
  );
  final center = tester.getCenter(finder);
  await gesture.addPointer(location: center);
  await gesture.moveTo(center);
  await tester.pump();
  await gesture.down(center);
  await gesture.up();
  await gesture.removePointer();
}

_TestContext _buildTestContext() {
  final repository = _InMemoryParticipantsRepository();

  return _TestContext(
    services: AppServices(
      appDataDirectory: Directory('/tmp/bochki_schedule_test'),
      logger: const _NoopLogger(),
      listParticipantsUseCase: ListParticipantsUseCase(repository),
      createParticipantUseCase: CreateParticipantUseCase(repository),
      updateParticipantUseCase: UpdateParticipantUseCase(repository),
      deleteParticipantUseCase: DeleteParticipantUseCase(repository),
    ),
    repository: repository,
  );
}

final class _TestContext {
  const _TestContext({
    required this.services,
    required this.repository,
  });

  final AppServices services;
  final _InMemoryParticipantsRepository repository;
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

  List<Participant> get participants =>
      List<Participant>.unmodifiable(_participants);

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
