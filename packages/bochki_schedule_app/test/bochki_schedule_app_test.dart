import 'dart:io';

import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
    await _openParticipantsDialog(tester);

    expect(
      find.byKey(const Key('participants_directory_dialog')),
      findsOneWidget,
    );
    expect(find.text('Список участников'), findsOneWidget);
    expect(find.text('Участники (0)'), findsOneWidget);
    expect(find.text('Добавить новую запись'), findsOneWidget);
    expect(find.byKey(const Key('participants_table_divider')), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
  });

  testWidgets('participants dialog supports create edit and delete', (
    tester,
  ) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

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

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Борис',
    );
    await tester.tap(find.text('Участники (1)'));
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('participant_row_1'));
    await _doubleMouseClick(tester, firstRow);
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Иван Петров',
    );
    await _mouseClick(tester, find.byKey(const Key('participant_row_2')));
    await tester.pumpAndSettle();

    expect(find.text('Иван Петров'), findsOneWidget);
    expect(context.repository.participants.first.name, 'Иван Петров');

    final secondRow = find.byKey(const Key('participant_row_2'));
    await _mouseClick(tester, secondRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(
      context.repository.participants.map((participant) => participant.name),
      ['Иван Петров'],
    );
    expect(find.text('Участники (1)'), findsOneWidget);
  });

  testWidgets('single click selects row without opening inline edit', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _mouseClick(tester, row);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
  });

  testWidgets('row becomes selected on mouse down before tap completes', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    final center = tester.getCenter(row);

    await gesture.addPointer(location: center);
    await gesture.moveTo(center);
    await tester.pump();
    await gesture.down(center);
    await tester.pump();

    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
    expect(find.byKey(const Key('participant_name_field')), findsNothing);

    await gesture.up();
    await gesture.removePointer();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('enter commits edited row after inline edit starts',
      (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _doubleMouseClick(tester, row);

    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Анна Петрова',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(find.text('Анна Петрова'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Анна Петрова');
    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
  });

  testWidgets('empty add row is cancelled on click outside', (tester) async {
    final context = _buildTestContext();

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);

    await tester.tap(find.text('Участники (0)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(context.repository.participants, isEmpty);
    expect(find.text('Введите имя участника.'), findsNothing);
  });

  testWidgets('double click opens inline edit for row', (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('participant_row_1')),
    );

    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);
  });

  testWidgets('escape rolls back dirty existing row', (tester) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await _doubleMouseClick(
      tester,
      find.byKey(const Key('participant_row_1')),
    );
    await tester.enterText(
      find.byKey(const Key('participant_name_field')),
      'Анна Петрова',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_name_field')), findsNothing);
    expect(find.text('Анна'), findsOneWidget);
    expect(context.repository.participants.single.name, 'Анна');
  });

  testWidgets('arrow navigation selects edge rows from no selection', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
        Participant(id: '2', name: 'Борис'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    final firstRow = find.byKey(const Key('participant_row_1'));
    expect(find.descendant(of: firstRow, matching: find.text('▶')),
        findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    final secondRow = find.byKey(const Key('participant_row_2'));
    expect(find.descendant(of: secondRow, matching: find.text('▶')),
        findsOneWidget);
  });

  testWidgets('context menu closes on escape without animation wait', (
    tester,
  ) async {
    final context = _buildTestContext(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );

    await tester.pumpWidget(BochkiScheduleApp(services: context.services));
    await tester.pumpAndSettle();
    await _openParticipantsDialog(tester);

    final row = find.byKey(const Key('participant_row_1'));
    await _mouseClick(tester, row, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.descendant(of: row, matching: find.text('▶')), findsOneWidget);
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

Future<void> _doubleMouseClick(
  WidgetTester tester,
  Finder finder,
) async {
  await _mouseClick(tester, finder);
  await tester.pump(const Duration(milliseconds: 50));
  await _mouseClick(tester, finder);
  await tester.pumpAndSettle();
}

Future<void> _openParticipantsDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('directories_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Участники').last);
  await tester.pumpAndSettle();
}

_TestContext _buildTestContext({
  List<Participant>? participants,
}) {
  final repository = _InMemoryParticipantsRepository(
    participants: participants,
  );

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
  _InMemoryParticipantsRepository({
    List<Participant>? participants,
  }) : _participants = [...?participants] {
    if (_participants.isNotEmpty) {
      final maxId = _participants
          .map((participant) => int.parse(participant.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Participant> _participants;
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
