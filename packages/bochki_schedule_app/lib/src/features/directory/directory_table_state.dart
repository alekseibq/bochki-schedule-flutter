import 'dart:ui';

sealed class DirectoryTableState {
  const DirectoryTableState();

  String? get selectedEntryId => null;
  bool get isEditing => false;
}

final class DirectoryTableNoSelection extends DirectoryTableState {
  const DirectoryTableNoSelection();
}

final class DirectoryTableSelectedRow extends DirectoryTableState {
  const DirectoryTableSelectedRow({
    required this.entryId,
    this.contextMenuPosition,
  });

  final String entryId;
  final Offset? contextMenuPosition;

  bool get isContextMenuOpen => contextMenuPosition != null;

  @override
  String? get selectedEntryId => entryId;
}

final class DirectoryTableEditRow extends DirectoryTableState {
  const DirectoryTableEditRow({
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

  DirectoryTableEditRow copyWith({
    String? currentValue,
  }) {
    return DirectoryTableEditRow(
      entryId: entryId,
      initialValue: initialValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

final class DirectoryTableEditNewRow extends DirectoryTableState {
  const DirectoryTableEditNewRow({
    required this.currentValue,
  });

  final String currentValue;

  bool get isDirty => currentValue.isNotEmpty;

  @override
  bool get isEditing => true;
}

final class DirectoryTableRowData {
  const DirectoryTableRowData({
    required this.id,
    required this.editValue,
  });

  final String id;
  final String editValue;
}

sealed class DirectoryTableEvent {
  const DirectoryTableEvent();

  const factory DirectoryTableEvent.clickRow(String entryId) =
      DirectoryTableClickRow;
  const factory DirectoryTableEvent.clickNewRow() =
      DirectoryTableClickNewRow;
  const factory DirectoryTableEvent.clickOutside() =
      DirectoryTableClickOutside;
  const factory DirectoryTableEvent.doubleClickRow(String entryId) =
      DirectoryTableDoubleClickRow;
  const factory DirectoryTableEvent.doubleClickNewRow() =
      DirectoryTableDoubleClickNewRow;
  const factory DirectoryTableEvent.rightClickRow({
    required String entryId,
    required Offset position,
  }) = DirectoryTableRightClickRow;
  const factory DirectoryTableEvent.rightClickNewRow() =
      DirectoryTableRightClickNewRow;
  const factory DirectoryTableEvent.pressEnter() =
      DirectoryTablePressEnter;
  const factory DirectoryTableEvent.pressEscape() =
      DirectoryTablePressEscape;
  const factory DirectoryTableEvent.pressArrowUp() =
      DirectoryTablePressArrowUp;
  const factory DirectoryTableEvent.pressArrowDown() =
      DirectoryTablePressArrowDown;
  const factory DirectoryTableEvent.textChanged(String value) =
      DirectoryTableTextChanged;
}

final class DirectoryTableClickRow extends DirectoryTableEvent {
  const DirectoryTableClickRow(this.entryId);

  final String entryId;
}

final class DirectoryTableClickNewRow extends DirectoryTableEvent {
  const DirectoryTableClickNewRow();
}

final class DirectoryTableClickOutside extends DirectoryTableEvent {
  const DirectoryTableClickOutside();
}

final class DirectoryTableDoubleClickRow extends DirectoryTableEvent {
  const DirectoryTableDoubleClickRow(this.entryId);

  final String entryId;
}

final class DirectoryTableDoubleClickNewRow extends DirectoryTableEvent {
  const DirectoryTableDoubleClickNewRow();
}

final class DirectoryTableRightClickRow extends DirectoryTableEvent {
  const DirectoryTableRightClickRow({
    required this.entryId,
    required this.position,
  });

  final String entryId;
  final Offset position;
}

final class DirectoryTableRightClickNewRow extends DirectoryTableEvent {
  const DirectoryTableRightClickNewRow();
}

final class DirectoryTablePressEnter extends DirectoryTableEvent {
  const DirectoryTablePressEnter();
}

final class DirectoryTablePressEscape extends DirectoryTableEvent {
  const DirectoryTablePressEscape();
}

final class DirectoryTablePressArrowUp extends DirectoryTableEvent {
  const DirectoryTablePressArrowUp();
}

final class DirectoryTablePressArrowDown extends DirectoryTableEvent {
  const DirectoryTablePressArrowDown();
}

final class DirectoryTableTextChanged extends DirectoryTableEvent {
  const DirectoryTableTextChanged(this.value);

  final String value;
}

final class DirectoryTableTransition {
  const DirectoryTableTransition({
    required this.state,
    this.submitRequest,
  });

  final DirectoryTableState state;
  final DirectoryTableSubmitRequest? submitRequest;
}

enum DirectoryTableSubmitMode {
  create,
  update,
}

sealed class DirectoryTableSuccessTarget {
  const DirectoryTableSuccessTarget();

  const factory DirectoryTableSuccessTarget.noSelection() =
      DirectoryTableSuccessNoSelection;
  const factory DirectoryTableSuccessTarget.selectRow(String entryId) =
      DirectoryTableSuccessSelectRow;
  const factory DirectoryTableSuccessTarget.editRow(String entryId) =
      DirectoryTableSuccessEditRow;
  const factory DirectoryTableSuccessTarget.editNewRow() =
      DirectoryTableSuccessEditNewRow;
  const factory DirectoryTableSuccessTarget.selectCreatedRow() =
      DirectoryTableSuccessSelectCreatedRow;
}

final class DirectoryTableSuccessNoSelection
    extends DirectoryTableSuccessTarget {
  const DirectoryTableSuccessNoSelection();
}

final class DirectoryTableSuccessSelectRow extends DirectoryTableSuccessTarget {
  const DirectoryTableSuccessSelectRow(this.entryId);

  final String entryId;
}

final class DirectoryTableSuccessEditRow extends DirectoryTableSuccessTarget {
  const DirectoryTableSuccessEditRow(this.entryId);

  final String entryId;
}

final class DirectoryTableSuccessEditNewRow extends DirectoryTableSuccessTarget {
  const DirectoryTableSuccessEditNewRow();
}

final class DirectoryTableSuccessSelectCreatedRow
    extends DirectoryTableSuccessTarget {
  const DirectoryTableSuccessSelectCreatedRow();
}

final class DirectoryTableSubmitRequest {
  const DirectoryTableSubmitRequest({
    required this.mode,
    required this.rawValue,
    required this.successTarget,
    this.entryId,
  });

  final DirectoryTableSubmitMode mode;
  final String rawValue;
  final String? entryId;
  final DirectoryTableSuccessTarget successTarget;
}

final class DirectoryTableReducer {
  const DirectoryTableReducer();

  DirectoryTableTransition reduce({
    required DirectoryTableState state,
    required DirectoryTableEvent event,
    required List<DirectoryTableRowData> rows,
  }) {
    return switch (event) {
      DirectoryTableClickRow(:final entryId) => _onClickRow(
          state: state,
          targetEntryId: entryId,
        ),
      DirectoryTableClickNewRow() => _onClickNewRow(state),
      DirectoryTableClickOutside() => _onClickOutside(state),
      DirectoryTableDoubleClickRow(:final entryId) => _onDoubleClickRow(
          state: state,
          targetEntryId: entryId,
          rows: rows,
        ),
      DirectoryTableDoubleClickNewRow() => _onDoubleClickNewRow(state),
      DirectoryTableRightClickRow(:final entryId, :final position) =>
        _onRightClickRow(
          state: state,
          targetEntryId: entryId,
          position: position,
        ),
      DirectoryTableRightClickNewRow() => _onRightClickNewRow(state),
      DirectoryTablePressEnter() => _onPressEnter(
          state: state,
          rows: rows,
        ),
      DirectoryTablePressEscape() => _onPressEscape(state),
      DirectoryTablePressArrowUp() => _onPressArrow(
          state: state,
          rows: rows,
          offset: -1,
        ),
      DirectoryTablePressArrowDown() => _onPressArrow(
          state: state,
          rows: rows,
          offset: 1,
        ),
      DirectoryTableTextChanged(:final value) => _onTextChanged(
          state: state,
          value: value,
        ),
    };
  }

  DirectoryTableState resolveSubmitSuccess({
    required DirectoryTableSuccessTarget target,
    required List<DirectoryTableRowData> rows,
    String? createdEntryId,
  }) {
    return switch (target) {
      DirectoryTableSuccessNoSelection() => const DirectoryTableNoSelection(),
      DirectoryTableSuccessSelectRow(:final entryId) =>
        DirectoryTableSelectedRow(entryId: entryId),
      DirectoryTableSuccessEditRow(:final entryId) =>
        _editStateForRow(rows, entryId) ?? const DirectoryTableNoSelection(),
      DirectoryTableSuccessEditNewRow() =>
        const DirectoryTableEditNewRow(currentValue: ''),
      DirectoryTableSuccessSelectCreatedRow() => createdEntryId == null
          ? const DirectoryTableNoSelection()
          : DirectoryTableSelectedRow(entryId: createdEntryId),
    };
  }

  DirectoryTableEditRow? _editStateForRow(
    List<DirectoryTableRowData> rows,
    String entryId,
  ) {
    for (final row in rows) {
      if (row.id == entryId) {
        return DirectoryTableEditRow(
          entryId: entryId,
          initialValue: row.editValue,
          currentValue: row.editValue,
        );
      }
    }
    return null;
  }

  DirectoryTableTransition _onClickRow({
    required DirectoryTableState state,
    required String targetEntryId,
  }) {
    return switch (state) {
      DirectoryTableNoSelection() || DirectoryTableSelectedRow() =>
        DirectoryTableTransition(
          state: DirectoryTableSelectedRow(entryId: targetEntryId),
        ),
      DirectoryTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: DirectoryTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : DirectoryTableTransition(
                state: DirectoryTableSelectedRow(entryId: targetEntryId),
              ),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? DirectoryTableTransition(
              state: state,
              submitRequest: DirectoryTableSubmitRequest(
                mode: DirectoryTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: DirectoryTableSuccessTarget.selectRow(
                  targetEntryId,
                ),
              ),
            )
          : DirectoryTableTransition(
              state: DirectoryTableSelectedRow(entryId: targetEntryId),
            ),
    };
  }

  DirectoryTableTransition _onClickNewRow(DirectoryTableState state) {
    return switch (state) {
      DirectoryTableNoSelection() || DirectoryTableSelectedRow() =>
        const DirectoryTableTransition(
          state: DirectoryTableEditNewRow(currentValue: ''),
        ),
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: const DirectoryTableSuccessTarget.editNewRow(),
                ),
              )
            : const DirectoryTableTransition(
                state: DirectoryTableEditNewRow(currentValue: ''),
              ),
      DirectoryTableEditNewRow() => DirectoryTableTransition(state: state),
    };
  }

  DirectoryTableTransition _onClickOutside(DirectoryTableState state) {
    return switch (state) {
      DirectoryTableNoSelection() || DirectoryTableSelectedRow() =>
        const DirectoryTableTransition(state: DirectoryTableNoSelection()),
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const DirectoryTableSuccessTarget.noSelection(),
                ),
              )
            : const DirectoryTableTransition(state: DirectoryTableNoSelection()),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? DirectoryTableTransition(
              state: state,
              submitRequest: DirectoryTableSubmitRequest(
                mode: DirectoryTableSubmitMode.create,
                rawValue: currentValue,
                successTarget:
                    const DirectoryTableSuccessTarget.noSelection(),
              ),
            )
          : const DirectoryTableTransition(state: DirectoryTableNoSelection()),
    };
  }

  DirectoryTableTransition _onDoubleClickRow({
    required DirectoryTableState state,
    required String targetEntryId,
    required List<DirectoryTableRowData> rows,
  }) {
    final targetEditState = _editStateForRow(rows, targetEntryId);
    if (targetEditState == null) {
      return DirectoryTableTransition(state: state);
    }

    return switch (state) {
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: DirectoryTableSuccessTarget.editRow(
                    targetEntryId,
                  ),
                ),
              )
            : DirectoryTableTransition(state: targetEditState),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? DirectoryTableTransition(
              state: state,
              submitRequest: DirectoryTableSubmitRequest(
                mode: DirectoryTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: DirectoryTableSuccessTarget.editRow(
                  targetEntryId,
                ),
              ),
            )
          : DirectoryTableTransition(state: targetEditState),
      _ => DirectoryTableTransition(state: targetEditState),
    };
  }

  DirectoryTableTransition _onDoubleClickNewRow(DirectoryTableState state) {
    return switch (state) {
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: const DirectoryTableSuccessTarget.editNewRow(),
                ),
              )
            : const DirectoryTableTransition(
                state: DirectoryTableEditNewRow(currentValue: ''),
              ),
      DirectoryTableEditNewRow() => DirectoryTableTransition(state: state),
      _ => const DirectoryTableTransition(
          state: DirectoryTableEditNewRow(currentValue: ''),
        ),
    };
  }

  DirectoryTableTransition _onRightClickRow({
    required DirectoryTableState state,
    required String targetEntryId,
    required Offset position,
  }) {
    return switch (state) {
      DirectoryTableNoSelection() || DirectoryTableSelectedRow() =>
        DirectoryTableTransition(
          state: DirectoryTableSelectedRow(
            entryId: targetEntryId,
            contextMenuPosition: position,
          ),
        ),
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: DirectoryTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : DirectoryTableTransition(
                state: DirectoryTableSelectedRow(entryId: targetEntryId),
              ),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? DirectoryTableTransition(
              state: state,
              submitRequest: DirectoryTableSubmitRequest(
                mode: DirectoryTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: DirectoryTableSuccessTarget.selectRow(
                  targetEntryId,
                ),
              ),
            )
          : DirectoryTableTransition(
              state: DirectoryTableSelectedRow(entryId: targetEntryId),
            ),
    };
  }

  DirectoryTableTransition _onRightClickNewRow(DirectoryTableState state) {
    if (state is DirectoryTableSelectedRow) {
      return DirectoryTableTransition(
        state: state.isContextMenuOpen
            ? DirectoryTableSelectedRow(entryId: state.entryId)
            : state,
      );
    }
    if (state is DirectoryTableNoSelection) {
      return const DirectoryTableTransition(
        state: DirectoryTableNoSelection(),
      );
    }
    if (state is DirectoryTableEditRow) {
      if (state.isDirty) {
        return DirectoryTableTransition(
          state: state,
          submitRequest: DirectoryTableSubmitRequest(
            mode: DirectoryTableSubmitMode.update,
            entryId: state.entryId,
            rawValue: state.currentValue,
            successTarget: DirectoryTableSuccessTarget.selectRow(state.entryId),
          ),
        );
      }
      return DirectoryTableTransition(
        state: DirectoryTableSelectedRow(entryId: state.entryId),
      );
    }
    return DirectoryTableTransition(state: state);
  }

  DirectoryTableTransition _onPressEnter({
    required DirectoryTableState state,
    required List<DirectoryTableRowData> rows,
  }) {
    return switch (state) {
      DirectoryTableNoSelection() => const DirectoryTableTransition(
          state: DirectoryTableNoSelection(),
        ),
      DirectoryTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        DirectoryTableTransition(
          state: isContextMenuOpen
              ? DirectoryTableSelectedRow(entryId: entryId)
              : _editStateForRow(rows, entryId) ??
                  DirectoryTableSelectedRow(entryId: entryId),
        ),
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        isDirty
            ? DirectoryTableTransition(
                state: state,
                submitRequest: DirectoryTableSubmitRequest(
                  mode: DirectoryTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      DirectoryTableSuccessTarget.selectRow(entryId),
                ),
              )
            : DirectoryTableTransition(
                state: DirectoryTableSelectedRow(entryId: entryId),
              ),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? DirectoryTableTransition(
              state: state,
              submitRequest: DirectoryTableSubmitRequest(
                mode: DirectoryTableSubmitMode.create,
                rawValue: currentValue,
                successTarget:
                    const DirectoryTableSuccessTarget.selectCreatedRow(),
              ),
            )
          : const DirectoryTableTransition(state: DirectoryTableNoSelection()),
    };
  }

  DirectoryTableTransition _onPressEscape(DirectoryTableState state) {
    return switch (state) {
      DirectoryTableNoSelection() => const DirectoryTableTransition(
          state: DirectoryTableNoSelection(),
        ),
      DirectoryTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        DirectoryTableTransition(
          state: isContextMenuOpen
              ? DirectoryTableSelectedRow(entryId: entryId)
              : const DirectoryTableNoSelection(),
        ),
      DirectoryTableEditRow(:final entryId) =>
        DirectoryTableTransition(
          state: DirectoryTableSelectedRow(entryId: entryId),
        ),
      DirectoryTableEditNewRow() => const DirectoryTableTransition(
          state: DirectoryTableNoSelection(),
        ),
    };
  }

  DirectoryTableTransition _onPressArrow({
    required DirectoryTableState state,
    required List<DirectoryTableRowData> rows,
    required int offset,
  }) {
    return switch (state) {
      DirectoryTableNoSelection() => _selectEdgeRow(rows, offset),
      DirectoryTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        isContextMenuOpen
            ? DirectoryTableTransition(state: state)
            : _moveSelectedRow(
                rows: rows,
                entryId: entryId,
                offset: offset,
              ),
      DirectoryTableEditRow(:final entryId, :final currentValue, :final isDirty) =>
        _moveEditRow(
          rows: rows,
          entryId: entryId,
          currentValue: currentValue,
          isDirty: isDirty,
          offset: offset,
        ),
      DirectoryTableEditNewRow(:final currentValue, :final isDirty) =>
        _moveFromNewRow(
          rows: rows,
          currentValue: currentValue,
          isDirty: isDirty,
          offset: offset,
        ),
    };
  }

  DirectoryTableTransition _onTextChanged({
    required DirectoryTableState state,
    required String value,
  }) {
    return switch (state) {
      DirectoryTableEditRow(:final entryId, :final initialValue) =>
        DirectoryTableTransition(
          state: DirectoryTableEditRow(
            entryId: entryId,
            initialValue: initialValue,
            currentValue: value,
          ),
        ),
      DirectoryTableEditNewRow() => DirectoryTableTransition(
          state: DirectoryTableEditNewRow(currentValue: value),
        ),
      _ => DirectoryTableTransition(state: state),
    };
  }

  DirectoryTableTransition _selectEdgeRow(
    List<DirectoryTableRowData> rows,
    int offset,
  ) {
    if (rows.isEmpty) {
      return const DirectoryTableTransition(
        state: DirectoryTableNoSelection(),
      );
    }

    return DirectoryTableTransition(
      state: DirectoryTableSelectedRow(
        entryId: offset > 0 ? rows.first.id : rows.last.id,
      ),
    );
  }

  DirectoryTableTransition _moveSelectedRow({
    required List<DirectoryTableRowData> rows,
    required String entryId,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const DirectoryTableTransition(
        state: DirectoryTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return DirectoryTableTransition(
        state: DirectoryTableSelectedRow(entryId: entryId),
      );
    }

    return DirectoryTableTransition(
      state: DirectoryTableSelectedRow(entryId: rows[targetIndex].id),
    );
  }

  DirectoryTableTransition _moveEditRow({
    required List<DirectoryTableRowData> rows,
    required String entryId,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const DirectoryTableTransition(
        state: DirectoryTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return DirectoryTableTransition(
        state:
            _editStateForRow(rows, entryId) ?? const DirectoryTableNoSelection(),
      );
    }

    final targetEntryId = rows[targetIndex].id;
    if (!isDirty) {
      return DirectoryTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const DirectoryTableNoSelection(),
      );
    }

    return DirectoryTableTransition(
      state: DirectoryTableEditRow(
        entryId: entryId,
        initialValue: _editStateForRow(rows, entryId)!.initialValue,
        currentValue: currentValue,
      ),
      submitRequest: DirectoryTableSubmitRequest(
        mode: DirectoryTableSubmitMode.update,
        entryId: entryId,
        rawValue: currentValue,
        successTarget: DirectoryTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }

  DirectoryTableTransition _moveFromNewRow({
    required List<DirectoryTableRowData> rows,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    if (offset > 0 || rows.isEmpty) {
      return DirectoryTableTransition(
        state: DirectoryTableEditNewRow(currentValue: currentValue),
      );
    }

    final targetEntryId = rows.last.id;
    if (!isDirty) {
      return DirectoryTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const DirectoryTableNoSelection(),
      );
    }

    return DirectoryTableTransition(
      state: DirectoryTableEditNewRow(currentValue: currentValue),
      submitRequest: DirectoryTableSubmitRequest(
        mode: DirectoryTableSubmitMode.create,
        rawValue: currentValue,
        successTarget: DirectoryTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }
}
