import 'package:bochki_schedule_app/src/features/directory/people_directory_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('assistant table edits and creates rows inline', (tester) async {
    final mutations = <String>[];
    await tester.pumpWidget(_table(
      type: PeopleDirectoryType.assistants,
      onMutate: (action, {id, name, shortName}) async {
        mutations.add('$action:$id:$name:$shortName');
        return null;
      },
    ));

    expect(find.text('Имя'), findsOneWidget);
    expect(find.text('Краткое имя'), findsOneWidget);
    expect(find.text('изм.'), findsOneWidget);
    expect(find.text('удл.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('people_directory_row_1')));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'Анна Петрова');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(mutations, ['update:1:Анна Петрова:Анна']);

    await tester.tap(find.byKey(const Key('people_directory_add_row')));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Борис');
    await tester.enterText(find.byType(TextField).last, 'Б');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(mutations.last, 'create:null:Борис:Б');
  });

  testWidgets('escape cancels an inline edit and errors preserve it',
      (tester) async {
    await tester.pumpWidget(_table(
      type: PeopleDirectoryType.participants,
      onMutate: (action, {id, name, shortName}) async =>
          'Введите имя участника.',
    ));

    await tester.tap(find.byKey(const Key('people_directory_row_1')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Введите имя участника.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Анна'), findsOneWidget);
  });
}

Widget _table({
  required PeopleDirectoryType type,
  required PeopleDirectoryMutation onMutate,
}) =>
    MaterialApp(
      home: Scaffold(
        body: PeopleDirectoryTable(
          type: type,
          entries: const [
            PeopleDirectoryEntry(id: '1', name: 'Анна', shortName: 'Анна'),
          ],
          onMutate: onMutate,
          onCountReferences: (_) async => 0,
          onChanged: () async {},
        ),
      ),
    );
