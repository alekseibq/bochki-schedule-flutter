import 'package:bochki_schedule_app/src/domain/participants/participant.dart';
import 'package:bochki_schedule_app/src/domain/participants/participants_validation_exception.dart';
import 'package:bochki_schedule_app/src/features/participants/participants_content.dart';
import 'package:bochki_schedule_app/src/features/participants/participants_dialog.dart';
import 'package:bochki_schedule_app/src/features/participants/participants_operations.dart';
import 'package:bochki_schedule_app/src/features/participants/participants_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Operations implements ParticipantsOperations {
  Participant value = Participant(id: '1', name: 'Анна');
  bool fail = false;
  int creates = 0;
  @override
  Future<List<Participant>> list() async => [value];
  @override
  Future<Participant> create(String name) async {
    creates++;
    return Participant(id: '2', name: name);
  }

  @override
  Future<Participant> update(String id, String name) async {
    if (fail) throw const ParticipantsValidationException('Ошибка участника');
    return value = Participant(id: id, name: name);
  }

  @override
  Future<int> countReferences(String id) async => 0;
  @override
  Future<void> delete(String id) async {}
}

void main() {
  testWidgets(
      'native close saves, rejects validation errors and discards blank new rows',
      (tester) async {
    final operations = _Operations();
    final viewModel = ParticipantsViewModel.fromOperations(operations);
    await viewModel.loadParticipants();
    final key = GlobalKey<ParticipantsContentState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ParticipantsContent(
      key: key,
      viewModel: viewModel,
      config: ParticipantsDialog.participantConfig,
      windowMode: true,
      onClose: () async {},
    ))));
    await tester.tap(find.byKey(const Key('participant_row_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('participant_name_field')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    Future<void> edit(String name) async {
      await tester.tap(find.byKey(const Key('participant_edit_1')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('participant_name_field')), name);
    }

    await tester.tap(find.byKey(const Key('participant_delete_1')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Удалить участника?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    await edit('Анна Новая');
    expect(await key.currentState!.requestClose(), isTrue);
    await tester.pumpAndSettle();
    expect(operations.value.name, 'Анна Новая');
    operations.fail = true;
    await edit('Анна Ошибка');
    expect(await key.currentState!.requestClose(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Ошибка участника'), findsOneWidget);
    operations.fail = false;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('participant_add_row')));
    await tester.pumpAndSettle();
    expect(await key.currentState!.requestClose(), isTrue);
    expect(operations.creates, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });
}
