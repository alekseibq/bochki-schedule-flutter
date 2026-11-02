import 'package:bochki_schedule_app/src/domain/assistants/assistant.dart';
import 'package:bochki_schedule_app/src/domain/assistants/assistants_validation_exception.dart';
import 'package:bochki_schedule_app/src/features/assistants/assistants_content.dart';
import 'package:bochki_schedule_app/src/features/assistants/assistants_dialog.dart';
import 'package:bochki_schedule_app/src/features/assistants/assistants_operations.dart';
import 'package:bochki_schedule_app/src/features/assistants/assistants_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Operations implements AssistantsOperations {
  Assistant value = Assistant(id: '1', name: 'Анна');
  bool fail = false;
  int creates = 0;
  @override
  Future<List<Assistant>> list() async => [value];
  @override
  Future<Assistant> create(String name) async {
    creates++;
    return Assistant(id: '2', name: name);
  }

  @override
  Future<Assistant> update(String id, String name) async {
    if (fail)
      throw const AssistantsValidationException('Ошибка сопровождающего');
    return value = Assistant(id: id, name: name);
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
    final viewModel = AssistantsViewModel.fromOperations(operations);
    await viewModel.loadAssistants();
    final key = GlobalKey<AssistantsContentState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AssistantsContent(
      key: key,
      viewModel: viewModel,
      config: AssistantsDialog.assistantConfig,
      windowMode: true,
      onClose: () async {},
    ))));
    Future<void> edit(String name) async {
      final row = find.byKey(const Key('assistant_row_1'));
      await tester.tap(row);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('assistant_name_field')), name);
    }

    await edit('Анна Новая');
    expect(await key.currentState!.requestClose(), isTrue);
    await tester.pumpAndSettle();
    expect(operations.value.name, 'Анна Новая');
    operations.fail = true;
    await edit('Анна Ошибка');
    expect(await key.currentState!.requestClose(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Ошибка сопровождающего'), findsOneWidget);
    operations.fail = false;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assistant_add_row')));
    await tester.pumpAndSettle();
    expect(await key.currentState!.requestClose(), isTrue);
    expect(operations.creates, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.dispose();
  });
}
