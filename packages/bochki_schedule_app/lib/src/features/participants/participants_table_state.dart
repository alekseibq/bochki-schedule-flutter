import 'dart:ui';

sealed class ParticipantsTableState {
  const ParticipantsTableState();

  String? get selectedEntryId => null;
  bool get isEditing => false;
}

final class ParticipantsTableNoSelection extends ParticipantsTableState {
  const ParticipantsTableNoSelection();
}

final class ParticipantsTableSelectedRow extends ParticipantsTableState {
  const ParticipantsTableSelectedRow({
    required this.entryId,
    this.contextMenuPosition,
  });

  final String entryId;
  final Offset? contextMenuPosition;

  bool get isContextMenuOpen => contextMenuPosition != null;

  @override
  String? get selectedEntryId => entryId;
}

final class ParticipantsTableEditRow extends ParticipantsTableState {
  const ParticipantsTableEditRow({
    required this.entryId,
    required this.initialValue,
    required this.currentValue,
  });

  final String entryId;
  final String initialValue;
  final String currentValue;

  bool get isDirty => currentValue != initialValue;

  @override
  bool get isEditing => true;

  @override
  String? get selectedEntryId => entryId;

  ParticipantsTableEditRow copyWith({
    String? currentValue,
  }) {
    return ParticipantsTableEditRow(
      entryId: entryId,
      initialValue: initialValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

final class ParticipantsTableEditNewRow extends ParticipantsTableState {
  const ParticipantsTableEditNewRow({
    required this.currentValue,
  });

  final String currentValue;

  bool get isDirty => currentValue.isNotEmpty;

  @override
  bool get isEditing => true;
}

final class ParticipantsTableRowData {
  const ParticipantsTableRowData({
    required this.id,
    required this.editValue,
  });

  final String id;
  final String editValue;
}

sealed class ParticipantsTableEvent {
  const ParticipantsTableEvent();

  const factory ParticipantsTableEvent.clickRow(String entryId) =
      ParticipantsTableClickRow;
  const factory ParticipantsTableEvent.clickNewRow() =
      ParticipantsTableClickNewRow;
  const factory ParticipantsTableEvent.clickOutside() =
      ParticipantsTableClickOutside;
  const factory ParticipantsTableEvent.doubleClickRow(String entryId) =
      ParticipantsTableDoubleClickRow;
  const factory ParticipantsTableEvent.doubleClickNewRow() =
      ParticipantsTableDoubleClickNewRow;
  const factory ParticipantsTableEvent.rightClickRow({
    required String entryId,
    required Offset position,
  }) = ParticipantsTableRightClickRow;
  const factory ParticipantsTableEvent.rightClickNewRow() =
      ParticipantsTableRightClickNewRow;
  const factory ParticipantsTableEvent.pressEnter() =
      ParticipantsTablePressEnter;
  const factory ParticipantsTableEvent.pressEscape() =
      ParticipantsTablePressEscape;
  const factory ParticipantsTableEvent.pressArrowUp() =
      ParticipantsTablePressArrowUp;
  const factory ParticipantsTableEvent.pressArrowDown() =
      ParticipantsTablePressArrowDown;
  const factory ParticipantsTableEvent.textChanged(String value) =
      ParticipantsTableTextChanged;
}

final class ParticipantsTableClickRow extends ParticipantsTableEvent {
  const ParticipantsTableClickRow(this.entryId);

  final String entryId;
}

final class ParticipantsTableClickNewRow extends ParticipantsTableEvent {
  const ParticipantsTableClickNewRow();
}

final class ParticipantsTableClickOutside extends ParticipantsTableEvent {
  const ParticipantsTableClickOutside();
}

final class ParticipantsTableDoubleClickRow extends ParticipantsTableEvent {
  const ParticipantsTableDoubleClickRow(this.entryId);

  final String entryId;
}

final class ParticipantsTableDoubleClickNewRow extends ParticipantsTableEvent {
  const ParticipantsTableDoubleClickNewRow();
}

final class ParticipantsTableRightClickRow extends ParticipantsTableEvent {
  const ParticipantsTableRightClickRow({
    required this.entryId,
    required this.position,
  });

  final String entryId;
  final Offset position;
}

final class ParticipantsTableRightClickNewRow extends ParticipantsTableEvent {
  const ParticipantsTableRightClickNewRow();
}

final class ParticipantsTablePressEnter extends ParticipantsTableEvent {
  const ParticipantsTablePressEnter();
}

final class ParticipantsTablePressEscape extends ParticipantsTableEvent {
  const ParticipantsTablePressEscape();
}

final class ParticipantsTablePressArrowUp extends ParticipantsTableEvent {
  const ParticipantsTablePressArrowUp();
}

final class ParticipantsTablePressArrowDown extends ParticipantsTableEvent {
  const ParticipantsTablePressArrowDown();
}

final class ParticipantsTableTextChanged extends ParticipantsTableEvent {
  const ParticipantsTableTextChanged(this.value);

  final String value;
}

final class ParticipantsTableTransition {
  const ParticipantsTableTransition({
    required this.state,
    this.submitRequest,
  });

  final ParticipantsTableState state;
  final ParticipantsTableSubmitRequest? submitRequest;
}

enum ParticipantsTableSubmitMode {
  create,
  update,
}

sealed class ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessTarget();

  const factory ParticipantsTableSuccessTarget.noSelection() =
      ParticipantsTableSuccessNoSelection;
  const factory ParticipantsTableSuccessTarget.selectRow(String entryId) =
      ParticipantsTableSuccessSelectRow;
  const factory ParticipantsTableSuccessTarget.editRow(String entryId) =
      ParticipantsTableSuccessEditRow;
  const factory ParticipantsTableSuccessTarget.editNewRow() =
      ParticipantsTableSuccessEditNewRow;
  const factory ParticipantsTableSuccessTarget.selectCreatedRow() =
      ParticipantsTableSuccessSelectCreatedRow;
}

final class ParticipantsTableSuccessNoSelection
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessNoSelection();
}

final class ParticipantsTableSuccessSelectRow
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessSelectRow(this.entryId);

  final String entryId;
}

final class ParticipantsTableSuccessEditRow
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessEditRow(this.entryId);

  final String entryId;
}

final class ParticipantsTableSuccessEditNewRow
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessEditNewRow();
}

final class ParticipantsTableSuccessSelectCreatedRow
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessSelectCreatedRow();
}

final class ParticipantsTableSubmitRequest {
  const ParticipantsTableSubmitRequest({
    required this.mode,
    required this.rawValue,
    required this.successTarget,
    this.entryId,
  });

  final ParticipantsTableSubmitMode mode;
  final String rawValue;
  final String? entryId;
  final ParticipantsTableSuccessTarget successTarget;
}

final class ParticipantsTableReducer {
  const ParticipantsTableReducer();

  ParticipantsTableTransition reduce({
    required ParticipantsTableState state,
    required ParticipantsTableEvent event,
    required List<ParticipantsTableRowData> rows,
  }) {
    return switch (event) {
      ParticipantsTableClickRow(:final entryId) => _onClickRow(
          state: state,
          targetEntryId: entryId,
        ),
      ParticipantsTableClickNewRow() => _onClickNewRow(state),
      ParticipantsTableClickOutside() => _onClickOutside(state),
      ParticipantsTableDoubleClickRow(:final entryId) => _onDoubleClickRow(
          state: state,
          targetEntryId: entryId,
          rows: rows,
        ),
      ParticipantsTableDoubleClickNewRow() => _onDoubleClickNewRow(state),
      ParticipantsTableRightClickRow(:final entryId, :final position) =>
        _onRightClickRow(
          state: state,
          targetEntryId: entryId,
          position: position,
        ),
      ParticipantsTableRightClickNewRow() => _onRightClickNewRow(state),
      ParticipantsTablePressEnter() => _onPressEnter(
          state: state,
          rows: rows,
        ),
      ParticipantsTablePressEscape() => _onPressEscape(state),
      ParticipantsTablePressArrowUp() => _onPressArrow(
          state: state,
          rows: rows,
          offset: -1,
        ),
      ParticipantsTablePressArrowDown() => _onPressArrow(
          state: state,
          rows: rows,
          offset: 1,
        ),
      ParticipantsTableTextChanged(:final value) => _onTextChanged(
          state: state,
          value: value,
        ),
    };
  }

  ParticipantsTableState resolveSubmitSuccess({
    required ParticipantsTableSuccessTarget target,
    required List<ParticipantsTableRowData> rows,
    String? createdEntryId,
  }) {
    return switch (target) {
      ParticipantsTableSuccessNoSelection() =>
        const ParticipantsTableNoSelection(),
      ParticipantsTableSuccessSelectRow(:final entryId) =>
        ParticipantsTableSelectedRow(entryId: entryId),
      ParticipantsTableSuccessEditRow(:final entryId) =>
        _editStateForRow(rows, entryId) ?? const ParticipantsTableNoSelection(),
      ParticipantsTableSuccessEditNewRow() =>
        const ParticipantsTableEditNewRow(currentValue: ''),
      ParticipantsTableSuccessSelectCreatedRow() => createdEntryId == null
          ? const ParticipantsTableNoSelection()
          : ParticipantsTableSelectedRow(entryId: createdEntryId),
    };
  }

  ParticipantsTableEditRow? _editStateForRow(
    List<ParticipantsTableRowData> rows,
    String entryId,
  ) {
    for (final row in rows) {
      if (row.id == entryId) {
        return ParticipantsTableEditRow(
          entryId: entryId,
          initialValue: row.editValue,
          currentValue: row.editValue,
        );
      }
    }
    return null;
  }

  ParticipantsTableTransition _onClickRow({
    required ParticipantsTableState state,
    required String targetEntryId,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedRow() =>
        ParticipantsTableTransition(
          state: ParticipantsTableSelectedRow(entryId: targetEntryId),
        ),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedRow(entryId: targetEntryId),
              ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedRow(entryId: targetEntryId),
              ),
    };
  }

  ParticipantsTableTransition _onClickNewRow(ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedRow() =>
        const ParticipantsTableTransition(
          state: ParticipantsTableEditNewRow(currentValue: ''),
        ),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.editNewRow(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableEditNewRow(currentValue: ''),
              ),
      ParticipantsTableEditNewRow() =>
        ParticipantsTableTransition(state: state),
    };
  }

  ParticipantsTableTransition _onClickOutside(ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedRow() =>
        const ParticipantsTableTransition(
            state: ParticipantsTableNoSelection()),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.noSelection(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableNoSelection()),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.noSelection(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableNoSelection()),
    };
  }

  ParticipantsTableTransition _onDoubleClickRow({
    required ParticipantsTableState state,
    required String targetEntryId,
    required List<ParticipantsTableRowData> rows,
  }) {
    final targetEditState = _editStateForRow(rows, targetEntryId);
    if (targetEditState == null) {
      return ParticipantsTableTransition(state: state);
    }

    return switch (state) {
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.editRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(state: targetEditState),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.editRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(state: targetEditState),
      _ => ParticipantsTableTransition(state: targetEditState),
    };
  }

  ParticipantsTableTransition _onDoubleClickNewRow(
      ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.editNewRow(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableEditNewRow(currentValue: ''),
              ),
      ParticipantsTableEditNewRow() =>
        ParticipantsTableTransition(state: state),
      _ => const ParticipantsTableTransition(
          state: ParticipantsTableEditNewRow(currentValue: ''),
        ),
    };
  }

  ParticipantsTableTransition _onRightClickRow({
    required ParticipantsTableState state,
    required String targetEntryId,
    required Offset position,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedRow() =>
        ParticipantsTableTransition(
          state: ParticipantsTableSelectedRow(
            entryId: targetEntryId,
            contextMenuPosition: position,
          ),
        ),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedRow(entryId: targetEntryId),
              ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedRow(entryId: targetEntryId),
              ),
    };
  }

  ParticipantsTableTransition _onRightClickNewRow(
      ParticipantsTableState state) {
    if (state is ParticipantsTableSelectedRow) {
      return ParticipantsTableTransition(
        state: state.isContextMenuOpen
            ? ParticipantsTableSelectedRow(entryId: state.entryId)
            : state,
      );
    }
    if (state is ParticipantsTableNoSelection) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }
    if (state is ParticipantsTableEditRow) {
      if (state.isDirty) {
        return ParticipantsTableTransition(
          state: state,
          submitRequest: ParticipantsTableSubmitRequest(
            mode: ParticipantsTableSubmitMode.update,
            entryId: state.entryId,
            rawValue: state.currentValue,
            successTarget:
                ParticipantsTableSuccessTarget.selectRow(state.entryId),
          ),
        );
      }
      return ParticipantsTableTransition(
        state: ParticipantsTableSelectedRow(entryId: state.entryId),
      );
    }
    return ParticipantsTableTransition(state: state);
  }

  ParticipantsTableTransition _onPressEnter({
    required ParticipantsTableState state,
    required List<ParticipantsTableRowData> rows,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
      ParticipantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        ParticipantsTableTransition(
          state: isContextMenuOpen
              ? ParticipantsTableSelectedRow(entryId: entryId)
              : _editStateForRow(rows, entryId) ??
                  ParticipantsTableSelectedRow(entryId: entryId),
        ),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      ParticipantsTableSuccessTarget.selectRow(entryId),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedRow(entryId: entryId),
              ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.selectCreatedRow(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableNoSelection()),
    };
  }

  ParticipantsTableTransition _onPressEscape(ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableNoSelection() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
      ParticipantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        ParticipantsTableTransition(
          state: isContextMenuOpen
              ? ParticipantsTableSelectedRow(entryId: entryId)
              : const ParticipantsTableNoSelection(),
        ),
      ParticipantsTableEditRow(:final entryId) => ParticipantsTableTransition(
          state: ParticipantsTableSelectedRow(entryId: entryId),
        ),
      ParticipantsTableEditNewRow() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
    };
  }

  ParticipantsTableTransition _onPressArrow({
    required ParticipantsTableState state,
    required List<ParticipantsTableRowData> rows,
    required int offset,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() => _selectEdgeRow(rows, offset),
      ParticipantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        isContextMenuOpen
            ? ParticipantsTableTransition(state: state)
            : _moveSelectedRow(
                rows: rows,
                entryId: entryId,
                offset: offset,
              ),
      ParticipantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        _moveEditRow(
          rows: rows,
          entryId: entryId,
          currentValue: currentValue,
          isDirty: isDirty,
          offset: offset,
        ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        _moveFromNewRow(
          rows: rows,
          currentValue: currentValue,
          isDirty: isDirty,
          offset: offset,
        ),
    };
  }

  ParticipantsTableTransition _onTextChanged({
    required ParticipantsTableState state,
    required String value,
  }) {
    return switch (state) {
      ParticipantsTableEditRow(:final entryId, :final initialValue) =>
        ParticipantsTableTransition(
          state: ParticipantsTableEditRow(
            entryId: entryId,
            initialValue: initialValue,
            currentValue: value,
          ),
        ),
      ParticipantsTableEditNewRow() => ParticipantsTableTransition(
          state: ParticipantsTableEditNewRow(currentValue: value),
        ),
      _ => ParticipantsTableTransition(state: state),
    };
  }

  ParticipantsTableTransition _selectEdgeRow(
    List<ParticipantsTableRowData> rows,
    int offset,
  ) {
    if (rows.isEmpty) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableSelectedRow(
        entryId: offset > 0 ? rows.first.id : rows.last.id,
      ),
    );
  }

  ParticipantsTableTransition _moveSelectedRow({
    required List<ParticipantsTableRowData> rows,
    required String entryId,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return ParticipantsTableTransition(
        state: ParticipantsTableSelectedRow(entryId: entryId),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableSelectedRow(entryId: rows[targetIndex].id),
    );
  }

  ParticipantsTableTransition _moveEditRow({
    required List<ParticipantsTableRowData> rows,
    required String entryId,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, entryId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    final targetEntryId = rows[targetIndex].id;
    if (!isDirty) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableEditRow(
        entryId: entryId,
        initialValue: _editStateForRow(rows, entryId)!.initialValue,
        currentValue: currentValue,
      ),
      submitRequest: ParticipantsTableSubmitRequest(
        mode: ParticipantsTableSubmitMode.update,
        entryId: entryId,
        rawValue: currentValue,
        successTarget: ParticipantsTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }

  ParticipantsTableTransition _moveFromNewRow({
    required List<ParticipantsTableRowData> rows,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    if (offset > 0 || rows.isEmpty) {
      return ParticipantsTableTransition(
        state: ParticipantsTableEditNewRow(currentValue: currentValue),
      );
    }

    final targetEntryId = rows.last.id;
    if (!isDirty) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableEditNewRow(currentValue: currentValue),
      submitRequest: ParticipantsTableSubmitRequest(
        mode: ParticipantsTableSubmitMode.create,
        rawValue: currentValue,
        successTarget: ParticipantsTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }
}
