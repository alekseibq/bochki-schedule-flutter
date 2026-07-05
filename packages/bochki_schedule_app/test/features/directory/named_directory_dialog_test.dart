import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_app/src/features/directory/named_directory_dialog.dart';
import 'package:bochki_schedule_app/src/features/directory/named_directory_dialog_config.dart';
import 'package:bochki_schedule_app/src/features/directory/named_directory_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared dialog renders column headers and row action buttons',
      (tester) async {
    var rowActionInvocations = 0;
    final repository = _InMemoryParticipantsRepository(
      participants: [
        Participant(id: '1', name: 'Анна'),
      ],
    );
    final viewModel = NamedDirectoryViewModel<Participant>(
      loadEntries: repository.list,
      createEntry: (rawName) async => repository.create(name: rawName),
      updateEntry: ({
        required String entryId,
        required String rawName,
      }) async {
        return repository.update(
          Participant(id: entryId, name: rawName),
        );
      },
      deleteEntry: repository.delete,
      loadErrorMessageText: 'load failed',
      saveErrorMessageText: 'save failed',
      deleteErrorMessageText: 'delete failed',
    );
    await viewModel.loadEntries();

    await tester.pumpWidget(
      MaterialApp(
        home: NamedDirectoryDialog<Participant>(
          viewModel: viewModel,
          config: NamedDirectoryDialogConfig<Participant>(
            dialogKey: 'generic_directory_dialog',
            tableDividerKey: 'generic_directory_divider',
            entryKeyPrefix: 'generic_entry',
            dialogTitle: 'Generic',
            sectionTitleBuilder: (count) => 'Generic ($count)',
            inlineFieldHintText: 'Введите имя',
            addRowLabel: 'Добавить новую запись',
            deleteConfirmationTitle: 'Удалить запись?',
            deleteConfirmationMessage: (entry) => entry.name,
            showColumnHeaders: true,
            columns: [
              DirectoryColumnSpec<Participant>(
                id: 'name',
                label: 'Имя',
                cellText: (participant) => participant.name,
              ),
              DirectoryColumnSpec<Participant>(
                id: 'upper',
                label: 'Верхний регистр',
                cellText: (participant) => participant.name.toUpperCase(),
              ),
            ],
            rowActions: [
              DirectoryRowActionSpec<Participant>(
                id: 'inspect',
                label: 'Inspect',
                placement: DirectoryRowActionPlacement.rowButton,
                icon: Icons.search,
                onInvoke: (controller, entry) async {
                  rowActionInvocations += 1;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Имя'), findsOneWidget);
    expect(find.text('Верхний регистр'), findsOneWidget);
    expect(find.byTooltip('Inspect'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('АННА'), findsOneWidget);

    final row = find.byKey(const Key('generic_entry_row_1'));
    final iconButton = tester.widget<IconButton>(
      find.descendant(of: row, matching: find.byType(IconButton)),
    );
    iconButton.onPressed!.call();
    await tester.pump();

    expect(rowActionInvocations, 1);
  });
}

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  _InMemoryParticipantsRepository({
    List<Participant>? participants,
  }) : _participants = [...?participants];

  final List<Participant> _participants;

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final participant = Participant(
      id: (_participants.length + 1).toString(),
      name: name,
    );
    _participants.add(participant);
    return participant;
  }

  @override
  Future<void> delete(String entryId) async {
    _participants.removeWhere((participant) => participant.id == entryId);
  }

  @override
  Future<List<Participant>> list() async {
    return [..._participants];
  }

  @override
  Future<Participant> update(Participant entry) async {
    final index = _participants.indexWhere(
      (candidate) => candidate.id == entry.id,
    );
    if (index != -1) {
      _participants[index] = entry;
    }
    return entry;
  }
}
