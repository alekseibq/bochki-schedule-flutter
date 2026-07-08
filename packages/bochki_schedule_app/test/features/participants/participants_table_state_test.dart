import 'package:bochki_schedule_app/src/features/directory/directory_table_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reducer = DirectoryTableReducer();
  const rows = [
    DirectoryTableRowData(id: '1', editValue: 'Анна'),
    DirectoryTableRowData(id: '2', editValue: 'Борис'),
  ];

  test('no selection click on data row selects row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableNoSelection(),
      event: const DirectoryTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '2'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('no selection click on new row opens edit new row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableNoSelection(),
      event: const DirectoryTableEvent.clickNewRow(),
      rows: rows,
    );

    expect(transition.state, isA<DirectoryTableEditNewRow>());
    expect(transition.submitRequest, isNull);
  });

  test('right click on data row opens context menu', () {
    final transition = reducer.reduce(
      state: const DirectoryTableNoSelection(),
      event: const DirectoryTableEvent.rightClickRow(
        entryId: '1',
        position: Offset(24, 40),
      ),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableSelectedRow>()
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
      state: const DirectoryTableSelectedRow(
        entryId: '1',
        contextMenuPosition: Offset(24, 40),
      ),
      event: const DirectoryTableEvent.pressEscape(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having(
              (state) => state.isContextMenuOpen, 'isContextMenuOpen', false),
    );
  });

  test('enter on selected row opens edit for that row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableSelectedRow(entryId: '1'),
      event: const DirectoryTableEvent.pressEnter(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableEditRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having((state) => state.currentValue, 'currentValue', 'Анна'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit data row click another row requires submit', () {
    final transition = reducer.reduce(
      state: const DirectoryTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна Петрова',
      ),
      event: const DirectoryTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(transition.state, isA<DirectoryTableEditRow>());
    expect(
      transition.submitRequest,
      isA<DirectoryTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              DirectoryTableSubmitMode.update)
          .having((request) => request.entryId, 'entryId', '1')
          .having((request) => request.rawValue, 'rawValue', 'Анна Петрова')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<DirectoryTableSuccessSelectRow>().having(
              (target) => target.entryId,
              'entryId',
              '2',
            ),
          ),
    );
  });

  test('clean edit data row arrow down moves edit to next row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна',
      ),
      event: const DirectoryTableEvent.pressArrowDown(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit new row enter submits and selects created row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableEditNewRow(currentValue: 'Глеб'),
      event: const DirectoryTableEvent.pressEnter(),
      rows: rows,
    );

    expect(transition.state, isA<DirectoryTableEditNewRow>());
    expect(
      transition.submitRequest,
      isA<DirectoryTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              DirectoryTableSubmitMode.create)
          .having((request) => request.rawValue, 'rawValue', 'Глеб')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<DirectoryTableSuccessSelectCreatedRow>(),
          ),
    );
  });

  test('clean edit new row arrow up moves edit to last data row', () {
    final transition = reducer.reduce(
      state: const DirectoryTableEditNewRow(currentValue: ''),
      event: const DirectoryTableEvent.pressArrowUp(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<DirectoryTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
  });
}
