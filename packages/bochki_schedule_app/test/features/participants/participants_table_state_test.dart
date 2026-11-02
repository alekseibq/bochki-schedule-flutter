import 'package:bochki_schedule_app/src/features/participants/participants_table_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reducer = ParticipantsTableReducer();
  const rows = [
    ParticipantsTableRowData(id: '1', editValue: 'Анна'),
    ParticipantsTableRowData(id: '2', editValue: 'Борис'),
  ];

  test('no selection click on data row selects row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableNoSelection(),
      event: const ParticipantsTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '2'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('no selection click on new row opens edit new row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableNoSelection(),
      event: const ParticipantsTableEvent.clickNewRow(),
      rows: rows,
    );

    expect(transition.state, isA<ParticipantsTableEditNewRow>());
    expect(transition.submitRequest, isNull);
  });

  test('right click on data row opens context menu', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableNoSelection(),
      event: const ParticipantsTableEvent.rightClickRow(
        entryId: '1',
        position: Offset(24, 40),
      ),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableSelectedRow>()
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
      state: const ParticipantsTableSelectedRow(
        entryId: '1',
        contextMenuPosition: Offset(24, 40),
      ),
      event: const ParticipantsTableEvent.pressEscape(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableSelectedRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having(
              (state) => state.isContextMenuOpen, 'isContextMenuOpen', false),
    );
  });

  test('enter on selected row opens edit for that row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableSelectedRow(entryId: '1'),
      event: const ParticipantsTableEvent.pressEnter(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '1')
          .having((state) => state.currentValue, 'currentValue', 'Анна'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit data row click another row requires submit', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна Петрова',
      ),
      event: const ParticipantsTableEvent.clickRow('2'),
      rows: rows,
    );

    expect(transition.state, isA<ParticipantsTableEditRow>());
    expect(
      transition.submitRequest,
      isA<ParticipantsTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              ParticipantsTableSubmitMode.update)
          .having((request) => request.entryId, 'entryId', '1')
          .having((request) => request.rawValue, 'rawValue', 'Анна Петрова')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<ParticipantsTableSuccessSelectRow>().having(
              (target) => target.entryId,
              'entryId',
              '2',
            ),
          ),
    );
  });

  test('clean edit data row arrow down moves edit to next row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableEditRow(
        entryId: '1',
        initialValue: 'Анна',
        currentValue: 'Анна',
      ),
      event: const ParticipantsTableEvent.pressArrowDown(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
    expect(transition.submitRequest, isNull);
  });

  test('dirty edit new row enter submits and selects created row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableEditNewRow(currentValue: 'Глеб'),
      event: const ParticipantsTableEvent.pressEnter(),
      rows: rows,
    );

    expect(transition.state, isA<ParticipantsTableEditNewRow>());
    expect(
      transition.submitRequest,
      isA<ParticipantsTableSubmitRequest>()
          .having((request) => request.mode, 'mode',
              ParticipantsTableSubmitMode.create)
          .having((request) => request.rawValue, 'rawValue', 'Глеб')
          .having(
            (request) => request.successTarget,
            'successTarget',
            isA<ParticipantsTableSuccessSelectCreatedRow>(),
          ),
    );
  });

  test('clean edit new row arrow up moves edit to last data row', () {
    final transition = reducer.reduce(
      state: const ParticipantsTableEditNewRow(currentValue: ''),
      event: const ParticipantsTableEvent.pressArrowUp(),
      rows: rows,
    );

    expect(
      transition.state,
      isA<ParticipantsTableEditRow>()
          .having((state) => state.entryId, 'entryId', '2')
          .having((state) => state.currentValue, 'currentValue', 'Борис'),
    );
  });
}
