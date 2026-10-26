import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import 'procedure_kind_dialog.dart';
import 'procedure_kinds_view_model.dart';

class ProcedureKindsContent extends StatefulWidget {
  const ProcedureKindsContent({
    required this.viewModel,
    this.columnWidths = const [],
    this.onColumnWidthsChanged,
    this.onOpenCreate,
    this.onOpenEdit,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;
  final List<double> columnWidths;
  final Future<void> Function(List<double> widths)? onColumnWidthsChanged;
  final Future<void> Function()? onOpenCreate;
  final Future<void> Function(ProcedureKind procedureKind)? onOpenEdit;

  static String assignedProcedureWord(int count) {
    final remainder100 = count % 100;
    if (remainder100 >= 11 && remainder100 <= 14) {
      return 'назначенных процедур';
    }
    return switch (count % 10) {
      1 => 'назначенная процедура',
      2 || 3 || 4 => 'назначенные процедуры',
      _ => 'назначенных процедур',
    };
  }

  @override
  State<ProcedureKindsContent> createState() => _ProcedureKindsContentState();
}

class _ProcedureKindsContentState extends State<ProcedureKindsContent> {
  static const _headerHeight = 32.0;
  static const _rowHeight = 30.0;
  static const List<_ProcedureKindsTableColumn> _columns = [
    _ProcedureKindsTableColumn('', 36, 36),
    _ProcedureKindsTableColumn('Название', 140, 100),
    _ProcedureKindsTableColumn('Тип', 80, 65),
    _ProcedureKindsTableColumn('емкость', 50, 50),
    _ProcedureKindsTableColumn('t участн.', 50, 50),
    _ProcedureKindsTableColumn('t ассист.', 50, 50),
    _ProcedureKindsTableColumn('t ресурс.', 50, 50),
    _ProcedureKindsTableColumn('', 60, 52),
    _ProcedureKindsTableColumn('', 60, 52),
  ];

  String? _selectedProcedureKindId;
  late List<double> _columnWidths;

  @override
  void initState() {
    super.initState();
    final saved = widget.columnWidths;
    _columnWidths = saved.length == _columns.length
        ? List<double>.from(saved)
        : _columns.map((column) => column.initialWidth).toList();
    widget.viewModel.addListener(_showActionErrorIfNeeded);
  }

  void _resizeColumns(int leftColumnIndex, double delta) {
    final leftColumn = _columns[leftColumnIndex];
    final leftWidth = _columnWidths[leftColumnIndex];
    if (leftColumnIndex == _columns.length - 1) {
      final actualDelta =
          delta.clamp(leftColumn.minimumWidth - leftWidth, double.infinity);
      if (actualDelta == 0) return;
      setState(() => _columnWidths[leftColumnIndex] = leftWidth + actualDelta);
      _saveColumnWidths();
      return;
    }
    final rightColumn = _columns[leftColumnIndex + 1];
    final rightWidth = _columnWidths[leftColumnIndex + 1];
    final actualDelta = delta.clamp(
      leftColumn.minimumWidth - leftWidth,
      rightWidth - rightColumn.minimumWidth,
    );
    if (actualDelta == 0) return;
    setState(() {
      _columnWidths[leftColumnIndex] = leftWidth + actualDelta;
      _columnWidths[leftColumnIndex + 1] = rightWidth - actualDelta;
    });
    _saveColumnWidths();
  }

  void _saveColumnWidths() {
    if (widget.onColumnWidthsChanged case final callback?) {
      unawaited(callback(List<double>.from(_columnWidths)));
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_showActionErrorIfNeeded);
    super.dispose();
  }

  void _showActionErrorIfNeeded() {
    final message = widget.viewModel.actionErrorMessage;
    if (!mounted || message == null) {
      return;
    }
    widget.viewModel.clearActionError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCreateDialog() async {
    if (widget.onOpenCreate case final callback?) {
      await callback();
      return;
    }
    widget.viewModel.clearFormError();
    final createdProcedureKind = await showDialog<ProcedureKind>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProcedureKindDialog(
          viewModel: widget.viewModel,
          procedureKinds: widget.viewModel.procedureKinds,
        );
      },
    );
    if (!mounted || createdProcedureKind == null) {
      return;
    }
    setState(() {
      _selectedProcedureKindId = createdProcedureKind.id;
    });
  }

  Future<void> _openEditDialog(ProcedureKind procedureKind) async {
    if (widget.onOpenEdit case final callback?) {
      await callback(procedureKind);
      return;
    }
    widget.viewModel.clearFormError();
    final updatedProcedureKind = await showDialog<ProcedureKind>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProcedureKindDialog(
          viewModel: widget.viewModel,
          initialProcedureKind: procedureKind,
          procedureKinds: widget.viewModel.procedureKinds,
        );
      },
    );
    if (!mounted || updatedProcedureKind == null) {
      return;
    }
    setState(() {
      _selectedProcedureKindId = updatedProcedureKind.id;
    });
  }

  Future<void> _deleteProcedureKind(ProcedureKind procedureKind) async {
    final referencesCount =
        await widget.viewModel.countReferences(procedureKind.id);
    if (!mounted) {
      return;
    }
    if (referencesCount > 0) {
      await _showDeletionBlockedDialog(procedureKind, referencesCount);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить процедуру?'),
          content: Text(
            'Процедура "${procedureKind.name}" будет скрыта из списка.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final result = await widget.viewModel.deleteProcedureKind(procedureKind.id);
    if (!mounted) {
      return;
    }
    if (result case ProcedureKindDeletionBlocked(:final referencesCount)) {
      await _showDeletionBlockedDialog(procedureKind, referencesCount);
      return;
    }
    if (result is ProcedureKindDeletionFailed) return;

    setState(() {
      if (_selectedProcedureKindId == procedureKind.id) {
        _selectedProcedureKindId = null;
      }
    });
  }

  Future<void> _showDeletionBlockedDialog(
    ProcedureKind procedureKind,
    int referencesCount,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Невозможно удалить процедуру'),
        content: Text(
          'Найдено: $referencesCount '
          '${ProcedureKindsContent.assignedProcedureWord(referencesCount)} '
          'для процедуры '
          '"${procedureKind.name}". '
          'Сначала удалите эти назначенные процедуры.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                key: const Key('procedure_kind_add_button'),
                onPressed: widget.viewModel.isSaving ? null : _openCreateDialog,
                child: const Text('Добавить новую процедуру...'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (widget.viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.viewModel.loadErrorMessage case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.viewModel.loadProcedureKinds,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth < constraints.maxWidth
                ? constraints.maxWidth
                : _tableWidth,
            child: Column(
              children: [
                Container(
                  key: const Key('procedure_kinds_table_header'),
                  height: _headerHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F6F8),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD0D7DE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var index = 0; index < _columns.length; index++)
                        _ProcedureKindsResizableHeaderCell(
                          key: Key('procedure_kinds_column_header_$index'),
                          width: _columnWidths[index],
                          text: _columns[index].label,
                          onResize: (delta) => _resizeColumns(index, delta),
                          resizeHandleKey:
                              Key('procedure_kinds_column_resizer_$index'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.viewModel.procedureKinds.length,
                    itemBuilder: (context, index) {
                      final procedureKind =
                          widget.viewModel.procedureKinds[index];
                      final isSelected =
                          _selectedProcedureKindId == procedureKind.id;
                      return InkWell(
                        key: Key('procedure_kind_row_${procedureKind.id}'),
                        onTap: () {
                          setState(() {
                            _selectedProcedureKindId = procedureKind.id;
                          });
                        },
                        child: Container(
                          height: _rowHeight,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF0F6FF)
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFFE5E9EF)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: _columnWidths[0],
                                child: Text(isSelected ? '▶' : ''),
                              ),
                              SizedBox(
                                width: _columnWidths[1],
                                child: Text(procedureKind.name),
                              ),
                              SizedBox(
                                width: _columnWidths[2],
                                child: _ProcedureKindPatternIcon(
                                  patternId: procedureKind.patternId,
                                  tooltip: procedureKind.pattern.shortName,
                                ),
                              ),
                              SizedBox(
                                width: _columnWidths[3],
                                child: Text(procedureKind.useCapacityRestriction
                                    ? '${procedureKind.capacity ?? '—'}'
                                    : '—'),
                              ),
                              SizedBox(
                                width: _columnWidths[4],
                                child: Text(
                                    '${procedureKind.participantBusyTime}'),
                              ),
                              SizedBox(
                                width: _columnWidths[5],
                                child: Text(
                                  procedureKind.assistantBusyTime?.toString() ??
                                      '',
                                ),
                              ),
                              SizedBox(
                                width: _columnWidths[6],
                                child: Text(
                                  procedureKind.useCapacityRestriction
                                      ? procedureKind.resourceBusyTime
                                              ?.toString() ??
                                          '—'
                                      : '—',
                                ),
                              ),
                              SizedBox(
                                width: _columnWidths[7],
                                child: TextButton(
                                  key: Key(
                                      'procedure_kind_edit_${procedureKind.id}'),
                                  onPressed: widget.viewModel.isSaving
                                      ? null
                                      : () => unawaited(
                                            _openEditDialog(procedureKind),
                                          ),
                                  child: const Text('Изм.'),
                                ),
                              ),
                              SizedBox(
                                width: _columnWidths[8],
                                child: TextButton(
                                  key: Key(
                                      'procedure_kind_delete_${procedureKind.id}'),
                                  onPressed: widget.viewModel.isSaving
                                      ? null
                                      : () => unawaited(
                                            _deleteProcedureKind(procedureKind),
                                          ),
                                  child: const Text('Удл.'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _tableWidth =>
      _columnWidths.fold<double>(0, (sum, width) => sum + width);
}

class _ProcedureKindsTableColumn {
  const _ProcedureKindsTableColumn(
    this.label,
    this.initialWidth,
    this.minimumWidth,
  );

  final String label;
  final double initialWidth;
  final double minimumWidth;
}

class _ProcedureKindsResizableHeaderCell extends StatelessWidget {
  const _ProcedureKindsResizableHeaderCell({
    required this.width,
    required this.text,
    required this.onResize,
    required this.resizeHandleKey,
    super.key,
  });

  final double width;
  final String text;
  final ValueChanged<double> onResize;
  final Key resizeHandleKey;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 32,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(text,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 8,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Listener(
                  key: resizeHandleKey,
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: (event) {
                    if (event.buttons == kPrimaryMouseButton) {
                      onResize(event.delta.dx);
                    }
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProcedureKindPatternIcon extends StatelessWidget {
  const _ProcedureKindPatternIcon({
    required this.patternId,
    required this.tooltip,
  });

  final String patternId;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final icon = switch (patternId) {
      'single' => Icons.person_outline,
      'curated' => Icons.people_outline,
      'grouped' => Icons.groups_outlined,
      _ => Icons.cloud_outlined,
    };
    return Tooltip(message: tooltip, child: Icon(icon));
  }
}

class ProcedureKindsDialog extends StatelessWidget {
  const ProcedureKindsDialog({
    required this.viewModel,
    required this.columnWidths,
    required this.onColumnWidthsChanged,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;
  final List<double> columnWidths;
  final Future<void> Function(List<double> widths) onColumnWidthsChanged;

  static String assignedProcedureWord(int count) =>
      ProcedureKindsContent.assignedProcedureWord(count);

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('procedure_kinds_dialog'),
        title: const Text('Список процедур'),
        content: SizedBox(
          width: 980,
          height: 520,
          child: ProcedureKindsContent(
            viewModel: viewModel,
            columnWidths: columnWidths,
            onColumnWidthsChanged: onColumnWidthsChanged,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      );
}
