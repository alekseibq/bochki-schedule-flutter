import 'package:bochki_schedule_app/src/features/assistants/assistants_table_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reducer = AssistantsTableReducer();
  const rows = [
    AssistantsTableRowData(id: '1', editValue: 'Анна'),
    AssistantsTableRowData(id: '2', editValue: 'Борис'),
  ];

  test('no selection click on data row selects row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableNoSelection(),
      event: const AssistantsTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '2'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('no selection click on new row opens edit new row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableNoSelection(),
      event: const AssistantsTableEvent.clickNewRow(),
      rows: rows,
    );

    expect(transition.state, isA<AssistantsTableEditNewRow>());
    expect(transition.submitRequest, isNull);
  });

  test('right click on data row opens context menu', () {
    final transition = reducer.reduce(
      state: const AssistantsTableNoSelection(),
      event: const AssistantsTableEvent.rightClickRow(
        entryId: '1',
        position: Offset(24, 40),
      ),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having(
            (state) => state.contextMenuPosition,
            'contextMenuPosition',
            const Offset(24, 40),
          ),
    );
  });

  test('escape closes open context menu and keeps selection', () {
    final transition = reducer.reduce(
      state: const AssistantsTableSelectedRow(
        entryId: '1',
        contextMenuPosition: Offset(24, 40),
      ),
      event: const AssistantsTableEvent.pressEscape(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having(
              (state) => state.isContextMenuOpen, 'isContextMenuOpen', false),
    );
  });

  test('enter on selected row opens edit for that row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableSelectedRow(entryId: '1'),
      event: const AssistantsTableEvent.pressEnter(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having((state) => state.currentValue, 'currentValue', 'Анна'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit data row click another row requires submit', () {
    final transition = reducer.reduce(
      state: const AssistantsTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна Петрова',
      ),
      event: const AssistantsTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(transition.state, isA<AssistantsTableEditRow>());
    expect(
      transition.submitRequest,
      isA<AssistantsTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              AssistantsTableSubmitMode.update)
          .having((request) => request.entryId, 'entryId', '1')
          .having((request) => request.rawValue, 'rawValue', 'Анна Петрова')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<AssistantsTableSuccessSelectRow>().having(
              (target) => target.entryId,
              'entryId',
              '2',
            ),
          ),
    );
  });

  test('clean edit data row arrow down moves edit to next row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна',
      ),
      event: const AssistantsTableEvent.pressArrowDown(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit new row enter submits and selects created row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableEditNewRow(currentValue: 'Глеб'),
      event: const AssistantsTableEvent.pressEnter(),
      rows: rows,
    );

    expect(transition.state, isA<AssistantsTableEditNewRow>());
    expect(
      transition.submitRequest,
      isA<AssistantsTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              AssistantsTableSubmitMode.create)
          .having((request) => request.rawValue, 'rawValue', 'Глеб')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<AssistantsTableSuccessSelectCreatedRow>(),
          ),
    );
  });

  test('clean edit new row arrow up moves edit to last data row', () {
    final transition = reducer.reduce(
      state: const AssistantsTableEditNewRow(currentValue: ''),
      event: const AssistantsTableEvent.pressArrowUp(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<AssistantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
  });
}
