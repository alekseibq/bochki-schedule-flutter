import 'dart:ui';

sealed class AssistantsTableState {
  const AssistantsTableState();

  String? get selectedEntryId => null;
  bool get isEditing => false;
}

final class AssistantsTableNoSelection extends AssistantsTableState {
  const AssistantsTableNoSelection();
}

final class AssistantsTableSelectedRow extends AssistantsTableState {
  const AssistantsTableSelectedRow({
    required this.entryId,
    this.contextMenuPosition,
  });

  final String entryId;
  final Offset? contextMenuPosition;

  bool get isContextMenuOpen => contextMenuPosition != null;

  @override
  String? get selectedEntryId => entryId;
}

final class AssistantsTableEditRow extends AssistantsTableState {
  const AssistantsTableEditRow({
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

  AssistantsTableEditRow copyWith({
    String? currentValue,
  }) {
    return AssistantsTableEditRow(
      entryId: entryId,
      initialValue: initialValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

final class AssistantsTableEditNewRow extends AssistantsTableState {
  const AssistantsTableEditNewRow({
    required this.currentValue,
  });

  final String currentValue;

  bool get isDirty => currentValue.isNotEmpty;

  @override
  bool get isEditing => true;
}

final class AssistantsTableRowData {
  const AssistantsTableRowData({
    required this.id,
    required this.editValue,
  });

  final String id;
  final String editValue;
}

sealed class AssistantsTableEvent {
  const AssistantsTableEvent();

  const factory AssistantsTableEvent.clickRow(String entryId) =
      AssistantsTableClickRow;
  const factory AssistantsTableEvent.clickNewRow() = AssistantsTableClickNewRow;
  const factory AssistantsTableEvent.clickOutside() =
      AssistantsTableClickOutside;
  const factory AssistantsTableEvent.doubleClickRow(String entryId) =
      AssistantsTableDoubleClickRow;
  const factory AssistantsTableEvent.doubleClickNewRow() =
      AssistantsTableDoubleClickNewRow;
  const factory AssistantsTableEvent.rightClickRow({
    required String entryId,
    required Offset position,
  }) = AssistantsTableRightClickRow;
  const factory AssistantsTableEvent.rightClickNewRow() =
      AssistantsTableRightClickNewRow;
  const factory AssistantsTableEvent.pressEnter() = AssistantsTablePressEnter;
  const factory AssistantsTableEvent.pressEscape() = AssistantsTablePressEscape;
  const factory AssistantsTableEvent.pressArrowUp() =
      AssistantsTablePressArrowUp;
  const factory AssistantsTableEvent.pressArrowDown() =
      AssistantsTablePressArrowDown;
  const factory AssistantsTableEvent.textChanged(String value) =
      AssistantsTableTextChanged;
}

final class AssistantsTableClickRow extends AssistantsTableEvent {
  const AssistantsTableClickRow(this.entryId);

  final String entryId;
}

final class AssistantsTableClickNewRow extends AssistantsTableEvent {
  const AssistantsTableClickNewRow();
}

final class AssistantsTableClickOutside extends AssistantsTableEvent {
  const AssistantsTableClickOutside();
}

final class AssistantsTableDoubleClickRow extends AssistantsTableEvent {
  const AssistantsTableDoubleClickRow(this.entryId);

  final String entryId;
}

final class AssistantsTableDoubleClickNewRow extends AssistantsTableEvent {
  const AssistantsTableDoubleClickNewRow();
}

final class AssistantsTableRightClickRow extends AssistantsTableEvent {
  const AssistantsTableRightClickRow({
    required this.entryId,
    required this.position,
  });

  final String entryId;
  final Offset position;
}

final class AssistantsTableRightClickNewRow extends AssistantsTableEvent {
  const AssistantsTableRightClickNewRow();
}

final class AssistantsTablePressEnter extends AssistantsTableEvent {
  const AssistantsTablePressEnter();
}

final class AssistantsTablePressEscape extends AssistantsTableEvent {
  const AssistantsTablePressEscape();
}

final class AssistantsTablePressArrowUp extends AssistantsTableEvent {
  const AssistantsTablePressArrowUp();
}

final class AssistantsTablePressArrowDown extends AssistantsTableEvent {
  const AssistantsTablePressArrowDown();
}

final class AssistantsTableTextChanged extends AssistantsTableEvent {
  const AssistantsTableTextChanged(this.value);

  final String value;
}

final class AssistantsTableTransition {
  const AssistantsTableTransition({
    required this.state,
    this.submitRequest,
  });

  final AssistantsTableState state;
  final AssistantsTableSubmitRequest? submitRequest;
}

enum AssistantsTableSubmitMode {
  create,
  update,
}

sealed class AssistantsTableSuccessTarget {
  const AssistantsTableSuccessTarget();

  const factory AssistantsTableSuccessTarget.noSelection() =
      AssistantsTableSuccessNoSelection;
  const factory AssistantsTableSuccessTarget.selectRow(String entryId) =
      AssistantsTableSuccessSelectRow;
  const factory AssistantsTableSuccessTarget.editRow(String entryId) =
      AssistantsTableSuccessEditRow;
  const factory AssistantsTableSuccessTarget.editNewRow() =
      AssistantsTableSuccessEditNewRow;
  const factory AssistantsTableSuccessTarget.selectCreatedRow() =
      AssistantsTableSuccessSelectCreatedRow;
}

final class AssistantsTableSuccessNoSelection
    extends AssistantsTableSuccessTarget {
  const AssistantsTableSuccessNoSelection();
}

final class AssistantsTableSuccessSelectRow
    extends AssistantsTableSuccessTarget {
  const AssistantsTableSuccessSelectRow(this.entryId);

  final String entryId;
}

final class AssistantsTableSuccessEditRow extends AssistantsTableSuccessTarget {
  const AssistantsTableSuccessEditRow(this.entryId);

  final String entryId;
}

final class AssistantsTableSuccessEditNewRow
    extends AssistantsTableSuccessTarget {
  const AssistantsTableSuccessEditNewRow();
}

final class AssistantsTableSuccessSelectCreatedRow
    extends AssistantsTableSuccessTarget {
  const AssistantsTableSuccessSelectCreatedRow();
}

final class AssistantsTableSubmitRequest {
  const AssistantsTableSubmitRequest({
    required this.mode,
    required this.rawValue,
    required this.successTarget,
    this.entryId,
  });

  final AssistantsTableSubmitMode mode;
  final String rawValue;
  final String? entryId;
  final AssistantsTableSuccessTarget successTarget;
}

final class AssistantsTableReducer {
  const AssistantsTableReducer();

  AssistantsTableTransition reduce({
    required AssistantsTableState state,
    required AssistantsTableEvent event,
    required List<AssistantsTableRowData> rows,
  }) {
    return switch (event) {
      AssistantsTableClickRow(:final entryId) => _onClickRow(
          state: state,
          targetEntryId: entryId,
        ),
      AssistantsTableClickNewRow() => _onClickNewRow(state),
      AssistantsTableClickOutside() => _onClickOutside(state),
      AssistantsTableDoubleClickRow(:final entryId) => _onDoubleClickRow(
          state: state,
          targetEntryId: entryId,
          rows: rows,
        ),
      AssistantsTableDoubleClickNewRow() => _onDoubleClickNewRow(state),
      AssistantsTableRightClickRow(:final entryId, :final position) =>
        _onRightClickRow(
          state: state,
          targetEntryId: entryId,
          position: position,
        ),
      AssistantsTableRightClickNewRow() => _onRightClickNewRow(state),
      AssistantsTablePressEnter() => _onPressEnter(
          state: state,
          rows: rows,
        ),
      AssistantsTablePressEscape() => _onPressEscape(state),
      AssistantsTablePressArrowUp() => _onPressArrow(
          state: state,
          rows: rows,
          offset: -1,
        ),
      AssistantsTablePressArrowDown() => _onPressArrow(
          state: state,
          rows: rows,
          offset: 1,
        ),
      AssistantsTableTextChanged(:final value) => _onTextChanged(
          state: state,
          value: value,
        ),
    };
  }

  AssistantsTableState resolveSubmitSuccess({
    required AssistantsTableSuccessTarget target,
    required List<AssistantsTableRowData> rows,
    String? createdEntryId,
  }) {
    return switch (target) {
      AssistantsTableSuccessNoSelection() => const AssistantsTableNoSelection(),
      AssistantsTableSuccessSelectRow(:final entryId) =>
        AssistantsTableSelectedRow(entryId: entryId),
      AssistantsTableSuccessEditRow(:final entryId) =>
        _editStateForRow(rows, entryId) ?? const AssistantsTableNoSelection(),
      AssistantsTableSuccessEditNewRow() =>
        const AssistantsTableEditNewRow(currentValue: ''),
      AssistantsTableSuccessSelectCreatedRow() => createdEntryId == null
          ? const AssistantsTableNoSelection()
          : AssistantsTableSelectedRow(entryId: createdEntryId),
    };
  }

  AssistantsTableEditRow? _editStateForRow(
    List<AssistantsTableRowData> rows,
    String entryId,
  ) {
    for (final row in rows) {
      if (row.id == entryId) {
        return AssistantsTableEditRow(
          entryId: entryId,
          initialValue: row.editValue,
          currentValue: row.editValue,
        );
      }
    }
    return null;
  }

  AssistantsTableTransition _onClickRow({
    required AssistantsTableState state,
    required String targetEntryId,
  }) {
    return switch (state) {
      AssistantsTableNoSelection() ||
      AssistantsTableSelectedRow() =>
        AssistantsTableTransition(
          state: AssistantsTableSelectedRow(entryId: targetEntryId),
        ),
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: AssistantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : AssistantsTableTransition(
                state: AssistantsTableSelectedRow(entryId: targetEntryId),
              ),
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? AssistantsTableTransition(
              state: state,
              submitRequest: AssistantsTableSubmitRequest(
                mode: AssistantsTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: AssistantsTableSuccessTarget.selectRow(
                  targetEntryId,
                ),
              ),
            )
          : AssistantsTableTransition(
              state: AssistantsTableSelectedRow(entryId: targetEntryId),
            ),
    };
  }

  AssistantsTableTransition _onClickNewRow(AssistantsTableState state) {
    return switch (state) {
      AssistantsTableNoSelection() ||
      AssistantsTableSelectedRow() =>
        const AssistantsTableTransition(
          state: AssistantsTableEditNewRow(currentValue: ''),
        ),
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const AssistantsTableSuccessTarget.editNewRow(),
                ),
              )
            : const AssistantsTableTransition(
                state: AssistantsTableEditNewRow(currentValue: ''),
              ),
      AssistantsTableEditNewRow() => AssistantsTableTransition(state: state),
    };
  }

  AssistantsTableTransition _onClickOutside(AssistantsTableState state) {
    return switch (state) {
      AssistantsTableNoSelection() ||
      AssistantsTableSelectedRow() =>
        const AssistantsTableTransition(state: AssistantsTableNoSelection()),
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const AssistantsTableSuccessTarget.noSelection(),
                ),
              )
            : const AssistantsTableTransition(
                state: AssistantsTableNoSelection()),
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? AssistantsTableTransition(
              state: state,
              submitRequest: AssistantsTableSubmitRequest(
                mode: AssistantsTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: const AssistantsTableSuccessTarget.noSelection(),
              ),
            )
          : const AssistantsTableTransition(
              state: AssistantsTableNoSelection()),
    };
  }

  AssistantsTableTransition _onDoubleClickRow({
    required AssistantsTableState state,
    required String targetEntryId,
    required List<AssistantsTableRowData> rows,
  }) {
    final targetEditState = _editStateForRow(rows, targetEntryId);
    if (targetEditState == null) {
      return AssistantsTableTransition(state: state);
    }

    return switch (state) {
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: AssistantsTableSuccessTarget.editRow(
                    targetEntryId,
                  ),
                ),
              )
            : AssistantsTableTransition(state: targetEditState),
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? AssistantsTableTransition(
              state: state,
              submitRequest: AssistantsTableSubmitRequest(
                mode: AssistantsTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: AssistantsTableSuccessTarget.editRow(
                  targetEntryId,
                ),
              ),
            )
          : AssistantsTableTransition(state: targetEditState),
      _ => AssistantsTableTransition(state: targetEditState),
    };
  }

  AssistantsTableTransition _onDoubleClickNewRow(AssistantsTableState state) {
    return switch (state) {
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      const AssistantsTableSuccessTarget.editNewRow(),
                ),
              )
            : const AssistantsTableTransition(
                state: AssistantsTableEditNewRow(currentValue: ''),
              ),
      AssistantsTableEditNewRow() => AssistantsTableTransition(state: state),
      _ => const AssistantsTableTransition(
          state: AssistantsTableEditNewRow(currentValue: ''),
        ),
    };
  }

  AssistantsTableTransition _onRightClickRow({
    required AssistantsTableState state,
    required String targetEntryId,
    required Offset position,
  }) {
    return switch (state) {
      AssistantsTableNoSelection() ||
      AssistantsTableSelectedRow() =>
        AssistantsTableTransition(
          state: AssistantsTableSelectedRow(
            entryId: targetEntryId,
            contextMenuPosition: position,
          ),
        ),
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget: AssistantsTableSuccessTarget.selectRow(
                    targetEntryId,
                  ),
                ),
              )
            : AssistantsTableTransition(
                state: AssistantsTableSelectedRow(entryId: targetEntryId),
              ),
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? AssistantsTableTransition(
              state: state,
              submitRequest: AssistantsTableSubmitRequest(
                mode: AssistantsTableSubmitMode.create,
                rawValue: currentValue,
                successTarget: AssistantsTableSuccessTarget.selectRow(
                  targetEntryId,
                ),
              ),
            )
          : AssistantsTableTransition(
              state: AssistantsTableSelectedRow(entryId: targetEntryId),
            ),
    };
  }

  AssistantsTableTransition _onRightClickNewRow(AssistantsTableState state) {
    if (state is AssistantsTableSelectedRow) {
      return AssistantsTableTransition(
        state: state.isContextMenuOpen
            ? AssistantsTableSelectedRow(entryId: state.entryId)
            : state,
      );
    }
    if (state is AssistantsTableNoSelection) {
      return const AssistantsTableTransition(
        state: AssistantsTableNoSelection(),
      );
    }
    if (state is AssistantsTableEditRow) {
      if (state.isDirty) {
        return AssistantsTableTransition(
          state: state,
          submitRequest: AssistantsTableSubmitRequest(
            mode: AssistantsTableSubmitMode.update,
            entryId: state.entryId,
            rawValue: state.currentValue,
            successTarget:
                AssistantsTableSuccessTarget.selectRow(state.entryId),
          ),
        );
      }
      return AssistantsTableTransition(
        state: AssistantsTableSelectedRow(entryId: state.entryId),
      );
    }
    return AssistantsTableTransition(state: state);
  }

  AssistantsTableTransition _onPressEnter({
    required AssistantsTableState state,
    required List<AssistantsTableRowData> rows,
  }) {
    return switch (state) {
      AssistantsTableNoSelection() => const AssistantsTableTransition(
          state: AssistantsTableNoSelection(),
        ),
      AssistantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        AssistantsTableTransition(
          state: isContextMenuOpen
              ? AssistantsTableSelectedRow(entryId: entryId)
              : _editStateForRow(rows, entryId) ??
                  AssistantsTableSelectedRow(entryId: entryId),
        ),
      AssistantsTableEditRow(
        :final entryId,
        :final currentValue,
        :final isDirty
      ) =>
        isDirty
            ? AssistantsTableTransition(
                state: state,
                submitRequest: AssistantsTableSubmitRequest(
                  mode: AssistantsTableSubmitMode.update,
                  entryId: entryId,
                  rawValue: currentValue,
                  successTarget:
                      AssistantsTableSuccessTarget.selectRow(entryId),
                ),
              )
            : AssistantsTableTransition(
                state: AssistantsTableSelectedRow(entryId: entryId),
              ),
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) => isDirty
          ? AssistantsTableTransition(
              state: state,
              submitRequest: AssistantsTableSubmitRequest(
                mode: AssistantsTableSubmitMode.create,
                rawValue: currentValue,
                successTarget:
                    const AssistantsTableSuccessTarget.selectCreatedRow(),
              ),
            )
          : const AssistantsTableTransition(
              state: AssistantsTableNoSelection()),
    };
  }

  AssistantsTableTransition _onPressEscape(AssistantsTableState state) {
    return switch (state) {
      AssistantsTableNoSelection() => const AssistantsTableTransition(
          state: AssistantsTableNoSelection(),
        ),
      AssistantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        AssistantsTableTransition(
          state: isContextMenuOpen
              ? AssistantsTableSelectedRow(entryId: entryId)
              : const AssistantsTableNoSelection(),
        ),
      AssistantsTableEditRow(:final entryId) => AssistantsTableTransition(
          state: AssistantsTableSelectedRow(entryId: entryId),
        ),
      AssistantsTableEditNewRow() => const AssistantsTableTransition(
          state: AssistantsTableNoSelection(),
        ),
    };
  }

  AssistantsTableTransition _onPressArrow({
    required AssistantsTableState state,
    required List<AssistantsTableRowData> rows,
    required int offset,
  }) {
    return switch (state) {
      AssistantsTableNoSelection() => _selectEdgeRow(rows, offset),
      AssistantsTableSelectedRow(:final entryId, :final isContextMenuOpen) =>
        isContextMenuOpen
            ? AssistantsTableTransition(state: state)
            : _moveSelectedRow(
                rows: rows,
                entryId: entryId,
                offset: offset,
              ),
      AssistantsTableEditRow(
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
      AssistantsTableEditNewRow(:final currentValue, :final isDirty) =>
        _moveFromNewRow(
          rows: rows,
          currentValue: currentValue,
          isDirty: isDirty,
          offset: offset,
        ),
    };
  }

  AssistantsTableTransition _onTextChanged({
    required AssistantsTableState state,
    required String value,
  }) {
    return switch (state) {
      AssistantsTableEditRow(:final entryId, :final initialValue) =>
        AssistantsTableTransition(
          state: AssistantsTableEditRow(
            entryId: entryId,
            initialValue: initialValue,
            currentValue: value,
          ),
        ),
      AssistantsTableEditNewRow() => AssistantsTableTransition(
          state: AssistantsTableEditNewRow(currentValue: value),
        ),
      _ => AssistantsTableTransition(state: state),
    };
  }

  AssistantsTableTransition _selectEdgeRow(
    List<AssistantsTableRowData> rows,
    int offset,
  ) {
    if (rows.isEmpty) {
      return const AssistantsTableTransition(
        state: AssistantsTableNoSelection(),
      );
    }

    return AssistantsTableTransition(
      state: AssistantsTableSelectedRow(
        entryId: offset > 0 ? rows.first.id : rows.last.id,
      ),
    );
  }

  AssistantsTableTransition _moveSelectedRow({
    required List<AssistantsTableRowData> rows,
    required String entryId,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const AssistantsTableTransition(
        state: AssistantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return AssistantsTableTransition(
        state: AssistantsTableSelectedRow(entryId: entryId),
      );
    }

    return AssistantsTableTransition(
      state: AssistantsTableSelectedRow(entryId: rows[targetIndex].id),
    );
  }

  AssistantsTableTransition _moveEditRow({
    required List<AssistantsTableRowData> rows,
    required String entryId,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == entryId);
    if (currentIndex == -1) {
      return const AssistantsTableTransition(
        state: AssistantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return AssistantsTableTransition(
        state: _editStateForRow(rows, entryId) ??
            const AssistantsTableNoSelection(),
      );
    }

    final targetEntryId = rows[targetIndex].id;
    if (!isDirty) {
      return AssistantsTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const AssistantsTableNoSelection(),
      );
    }

    return AssistantsTableTransition(
      state: AssistantsTableEditRow(
        entryId: entryId,
        initialValue: _editStateForRow(rows, entryId)!.initialValue,
        currentValue: currentValue,
      ),
      submitRequest: AssistantsTableSubmitRequest(
        mode: AssistantsTableSubmitMode.update,
        entryId: entryId,
        rawValue: currentValue,
        successTarget: AssistantsTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }

  AssistantsTableTransition _moveFromNewRow({
    required List<AssistantsTableRowData> rows,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    if (offset > 0 || rows.isEmpty) {
      return AssistantsTableTransition(
        state: AssistantsTableEditNewRow(currentValue: currentValue),
      );
    }

    final targetEntryId = rows.last.id;
    if (!isDirty) {
      return AssistantsTableTransition(
        state: _editStateForRow(rows, targetEntryId) ??
            const AssistantsTableNoSelection(),
      );
    }

    return AssistantsTableTransition(
      state: AssistantsTableEditNewRow(currentValue: currentValue),
      submitRequest: AssistantsTableSubmitRequest(
        mode: AssistantsTableSubmitMode.create,
        rawValue: currentValue,
        successTarget: AssistantsTableSuccessTarget.editRow(targetEntryId),
      ),
    );
  }
}
