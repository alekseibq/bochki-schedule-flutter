import 'dart:ui';

sealed class ParticipantsTableState {
  const ParticipantsTableState();

  String? get selectedParticipantId => null;
  bool get isEditing => false;
}

final class ParticipantsTableNoSelection extends ParticipantsTableState {
  const ParticipantsTableNoSelection();
}

final class ParticipantsTableSelectedDataRow extends ParticipantsTableState {
  const ParticipantsTableSelectedDataRow({
    required this.participantId,
    this.contextMenuPosition,
  });

  final String participantId;
  final Offset? contextMenuPosition;

  bool get isContextMenuOpen => contextMenuPosition != null;

  @override
  String? get selectedParticipantId => participantId;
}

final class ParticipantsTableEditDataRow extends ParticipantsTableState {
  const ParticipantsTableEditDataRow({
    required this.participantId,
    required this.initialValue,
    required this.currentValue,
  });

  final String participantId;
  final String initialValue;
  final String currentValue;

  bool get isDirty => currentValue != initialValue;

  @override
  bool get isEditing => true;

  @override
  String? get selectedParticipantId => participantId;

  ParticipantsTableEditDataRow copyWith({
    String? currentValue,
  }) {
    return ParticipantsTableEditDataRow(
      participantId: participantId,
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
    required this.name,
  });

  final String id;
  final String name;
}

sealed class ParticipantsTableEvent {
  const ParticipantsTableEvent();

  const factory ParticipantsTableEvent.clickDataRow(String participantId) =
      ParticipantsTableClickDataRow;
  const factory ParticipantsTableEvent.clickNewRow() =
      ParticipantsTableClickNewRow;
  const factory ParticipantsTableEvent.clickOutside() =
      ParticipantsTableClickOutside;
  const factory ParticipantsTableEvent.doubleClickDataRow(
      String participantId) = ParticipantsTableDoubleClickDataRow;
  const factory ParticipantsTableEvent.doubleClickNewRow() =
      ParticipantsTableDoubleClickNewRow;
  const factory ParticipantsTableEvent.rightClickDataRow({
    required String participantId,
    required Offset position,
  }) = ParticipantsTableRightClickDataRow;
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

final class ParticipantsTableClickDataRow extends ParticipantsTableEvent {
  const ParticipantsTableClickDataRow(this.participantId);

  final String participantId;
}

final class ParticipantsTableClickNewRow extends ParticipantsTableEvent {
  const ParticipantsTableClickNewRow();
}

final class ParticipantsTableClickOutside extends ParticipantsTableEvent {
  const ParticipantsTableClickOutside();
}

final class ParticipantsTableDoubleClickDataRow extends ParticipantsTableEvent {
  const ParticipantsTableDoubleClickDataRow(this.participantId);

  final String participantId;
}

final class ParticipantsTableDoubleClickNewRow extends ParticipantsTableEvent {
  const ParticipantsTableDoubleClickNewRow();
}

final class ParticipantsTableRightClickDataRow extends ParticipantsTableEvent {
  const ParticipantsTableRightClickDataRow({
    required this.participantId,
    required this.position,
  });

  final String participantId;
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
  const factory ParticipantsTableSuccessTarget.selectRow(String participantId) =
      ParticipantsTableSuccessSelectRow;
  const factory ParticipantsTableSuccessTarget.editRow(String participantId) =
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
  const ParticipantsTableSuccessSelectRow(this.participantId);

  final String participantId;
}

final class ParticipantsTableSuccessEditRow
    extends ParticipantsTableSuccessTarget {
  const ParticipantsTableSuccessEditRow(this.participantId);

  final String participantId;
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
    this.participantId,
  });

  final ParticipantsTableSubmitMode mode;
  final String rawValue;
  final String? participantId;
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
      ParticipantsTableClickDataRow(:final participantId) => _onClickDataRow(
          state: state,
          targetParticipantId: participantId,
        ),
      ParticipantsTableClickNewRow() => _onClickNewRow(state),
      ParticipantsTableClickOutside() => _onClickOutside(state),
      ParticipantsTableDoubleClickDataRow(:final participantId) =>
        _onDoubleClickDataRow(
          state: state,
          targetParticipantId: participantId,
          rows: rows,
        ),
      ParticipantsTableDoubleClickNewRow() => _onDoubleClickNewRow(state),
      ParticipantsTableRightClickDataRow(
        :final participantId,
        :final position,
      ) =>
        _onRightClickDataRow(
          state: state,
          targetParticipantId: participantId,
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
    String? createdParticipantId,
  }) {
    return switch (target) {
      ParticipantsTableSuccessNoSelection() =>
        const ParticipantsTableNoSelection(),
      ParticipantsTableSuccessSelectRow(:final participantId) =>
        ParticipantsTableSelectedDataRow(participantId: participantId),
      ParticipantsTableSuccessEditRow(:final participantId) =>
        _editStateForRow(rows, participantId) ??
            const ParticipantsTableNoSelection(),
      ParticipantsTableSuccessEditNewRow() =>
        const ParticipantsTableEditNewRow(currentValue: ''),
      ParticipantsTableSuccessSelectCreatedRow() => createdParticipantId == null
          ? const ParticipantsTableNoSelection()
          : ParticipantsTableSelectedDataRow(
              participantId: createdParticipantId),
    };
  }

  ParticipantsTableEditDataRow? _editStateForRow(
    List<ParticipantsTableRowData> rows,
    String participantId,
  ) {
    for (final row in rows) {
      if (row.id == participantId) {
        return ParticipantsTableEditDataRow(
          participantId: participantId,
          initialValue: row.name,
          currentValue: row.name,
        );
      }
    }
    return null;
  }

  ParticipantsTableTransition _onClickDataRow({
    required ParticipantsTableState state,
    required String targetParticipantId,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() => ParticipantsTableTransition(
          state: ParticipantsTableSelectedDataRow(
            participantId: targetParticipantId,
          ),
        ),
      ParticipantsTableSelectedDataRow() => ParticipantsTableTransition(
          state: ParticipantsTableSelectedDataRow(
            participantId: targetParticipantId,
          ),
        ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetParticipantId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedDataRow(
                  participantId: targetParticipantId,
                ),
              ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetParticipantId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedDataRow(
                  participantId: targetParticipantId,
                ),
              ),
    };
  }

  ParticipantsTableTransition _onClickNewRow(ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedDataRow() =>
        const ParticipantsTableTransition(
          state: ParticipantsTableEditNewRow(currentValue: ''),
        ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
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
      ParticipantsTableNoSelection() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
      ParticipantsTableSelectedDataRow() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
                  rawValue: currentValue,
                  successTarget:
                      const ParticipantsTableSuccessTarget.noSelection(),
                ),
              )
            : const ParticipantsTableTransition(
                state: ParticipantsTableNoSelection(),
              ),
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
                state: ParticipantsTableNoSelection(),
              ),
    };
  }

  ParticipantsTableTransition _onDoubleClickDataRow({
    required ParticipantsTableState state,
    required String targetParticipantId,
    required List<ParticipantsTableRowData> rows,
  }) {
    final targetEditState = _editStateForRow(rows, targetParticipantId);
    if (targetEditState == null) {
      return ParticipantsTableTransition(state: state);
    }

    return switch (state) {
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.editRow(
                    targetParticipantId,
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
                    targetParticipantId,
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
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
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

  ParticipantsTableTransition _onRightClickDataRow({
    required ParticipantsTableState state,
    required String targetParticipantId,
    required Offset position,
  }) {
    return switch (state) {
      ParticipantsTableNoSelection() ||
      ParticipantsTableSelectedDataRow() =>
        ParticipantsTableTransition(
          state: ParticipantsTableSelectedDataRow(
            participantId: targetParticipantId,
            contextMenuPosition: position,
          ),
        ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetParticipantId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedDataRow(
                  participantId: targetParticipantId,
                ),
              ),
      ParticipantsTableEditNewRow(:final currentValue, :final isDirty) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.create,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    targetParticipantId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedDataRow(
                  participantId: targetParticipantId,
                ),
              ),
    };
  }

  ParticipantsTableTransition _onRightClickNewRow(
      ParticipantsTableState state) {
    if (state is ParticipantsTableSelectedDataRow) {
      return ParticipantsTableTransition(
        state: state.isContextMenuOpen
            ? ParticipantsTableSelectedDataRow(
                participantId: state.participantId)
            : state,
      );
    }
    if (state is ParticipantsTableNoSelection) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }
    if (state is ParticipantsTableEditDataRow) {
      if (state.isDirty) {
        return ParticipantsTableTransition(
          state: state,
          submitRequest: ParticipantsTableSubmitRequest(
            mode: ParticipantsTableSubmitMode.update,
            participantId: state.participantId,
            rawValue: state.currentValue,
            successTarget: ParticipantsTableSuccessTarget.selectRow(
              state.participantId,
            ),
          ),
        );
      }
      return ParticipantsTableTransition(
        state: ParticipantsTableSelectedDataRow(
          participantId: state.participantId,
        ),
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
      ParticipantsTableSelectedDataRow(
        :final participantId,
        :final isContextMenuOpen,
      ) =>
        ParticipantsTableTransition(
          state: isContextMenuOpen
              ? ParticipantsTableSelectedDataRow(participantId: participantId)
              : _editStateForRow(rows, participantId) ??
                  ParticipantsTableSelectedDataRow(
                      participantId: participantId),
        ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        isDirty
            ? ParticipantsTableTransition(
                state: state,
                submitRequest: ParticipantsTableSubmitRequest(
                  mode: ParticipantsTableSubmitMode.update,
                  participantId: participantId,
                  rawValue: currentValue,
                  successTarget: ParticipantsTableSuccessTarget.selectRow(
                    participantId,
                  ),
                ),
              )
            : ParticipantsTableTransition(
                state: ParticipantsTableSelectedDataRow(
                    participantId: participantId),
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
                state: ParticipantsTableNoSelection(),
              ),
    };
  }

  ParticipantsTableTransition _onPressEscape(ParticipantsTableState state) {
    return switch (state) {
      ParticipantsTableNoSelection() => const ParticipantsTableTransition(
          state: ParticipantsTableNoSelection(),
        ),
      ParticipantsTableSelectedDataRow(
        :final participantId,
        :final isContextMenuOpen,
      ) =>
        ParticipantsTableTransition(
          state: isContextMenuOpen
              ? ParticipantsTableSelectedDataRow(participantId: participantId)
              : const ParticipantsTableNoSelection(),
        ),
      ParticipantsTableEditDataRow(:final participantId) =>
        ParticipantsTableTransition(
          state: ParticipantsTableSelectedDataRow(participantId: participantId),
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
      ParticipantsTableSelectedDataRow(
        :final participantId,
        :final isContextMenuOpen,
      ) =>
        isContextMenuOpen
            ? ParticipantsTableTransition(state: state)
            : _moveSelectedRow(
                rows: rows,
                participantId: participantId,
                offset: offset,
              ),
      ParticipantsTableEditDataRow(
        :final participantId,
        :final currentValue,
        :final isDirty,
      ) =>
        _moveEditRow(
          rows: rows,
          participantId: participantId,
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
      ParticipantsTableEditDataRow(:final participantId, :final initialValue) =>
        ParticipantsTableTransition(
          state: ParticipantsTableEditDataRow(
            participantId: participantId,
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
      state: ParticipantsTableSelectedDataRow(
        participantId: offset > 0 ? rows.first.id : rows.last.id,
      ),
    );
  }

  ParticipantsTableTransition _moveSelectedRow({
    required List<ParticipantsTableRowData> rows,
    required String participantId,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == participantId);
    if (currentIndex == -1) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return ParticipantsTableTransition(
        state: ParticipantsTableSelectedDataRow(participantId: participantId),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableSelectedDataRow(
        participantId: rows[targetIndex].id,
      ),
    );
  }

  ParticipantsTableTransition _moveEditRow({
    required List<ParticipantsTableRowData> rows,
    required String participantId,
    required String currentValue,
    required bool isDirty,
    required int offset,
  }) {
    final currentIndex = rows.indexWhere((row) => row.id == participantId);
    if (currentIndex == -1) {
      return const ParticipantsTableTransition(
        state: ParticipantsTableNoSelection(),
      );
    }

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= rows.length) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, participantId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    final targetParticipantId = rows[targetIndex].id;
    if (!isDirty) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, targetParticipantId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableEditDataRow(
        participantId: participantId,
        initialValue: _editStateForRow(rows, participantId)!.initialValue,
        currentValue: currentValue,
      ),
      submitRequest: ParticipantsTableSubmitRequest(
        mode: ParticipantsTableSubmitMode.update,
        participantId: participantId,
        rawValue: currentValue,
        successTarget: ParticipantsTableSuccessTarget.editRow(
          targetParticipantId,
        ),
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

    final targetParticipantId = rows.last.id;
    if (!isDirty) {
      return ParticipantsTableTransition(
        state: _editStateForRow(rows, targetParticipantId) ??
            const ParticipantsTableNoSelection(),
      );
    }

    return ParticipantsTableTransition(
      state: ParticipantsTableEditNewRow(currentValue: currentValue),
      submitRequest: ParticipantsTableSubmitRequest(
        mode: ParticipantsTableSubmitMode.create,
        rawValue: currentValue,
        successTarget: ParticipantsTableSuccessTarget.editRow(
          targetParticipantId,
        ),
      ),
    );
  }
}
