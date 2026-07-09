import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import 'procedure_kind_dialog.dart';
import 'procedure_kinds_view_model.dart';

class ProcedureKindsDialog extends StatefulWidget {
  const ProcedureKindsDialog({
    required this.viewModel,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;

  @override
  State<ProcedureKindsDialog> createState() => _ProcedureKindsDialogState();
}

class _ProcedureKindsDialogState extends State<ProcedureKindsDialog> {
  String? _selectedProcedureKindId;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_showActionErrorIfNeeded);
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
    widget.viewModel.clearFormError();
    final createdProcedureKind = await showDialog<ProcedureKind>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProcedureKindDialog(viewModel: widget.viewModel);
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
    widget.viewModel.clearFormError();
    final updatedProcedureKind = await showDialog<ProcedureKind>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProcedureKindDialog(
          viewModel: widget.viewModel,
          initialProcedureKind: procedureKind,
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

    final isSuccess =
        await widget.viewModel.deleteProcedureKind(procedureKind.id);
    if (!mounted || !isSuccess) {
      return;
    }

    setState(() {
      if (_selectedProcedureKindId == procedureKind.id) {
        _selectedProcedureKindId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return AlertDialog(
          key: const Key('procedure_kinds_dialog'),
          title: const Text('Список процедур'),
          content: SizedBox(
            width: 980,
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    key: const Key('procedure_kind_add_button'),
                    onPressed:
                        widget.viewModel.isSaving ? null : _openCreateDialog,
                    child: const Text('Добавить новую процедуру...'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
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
      child: Column(
        children: [
          Container(
            key: const Key('procedure_kinds_table_header'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F8),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D7DE)),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36, child: Text('')),
                Expanded(flex: 2, child: Text('Тип')),
                Expanded(flex: 3, child: Text('Название')),
                Expanded(child: Text('емкость')),
                Expanded(child: Text('t участн.')),
                Expanded(child: Text('t ассист.')),
                Expanded(child: Text('t ресуср.')),
                SizedBox(width: 72, child: Text('')),
                SizedBox(width: 72, child: Text('')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.viewModel.procedureKinds.length,
              itemBuilder: (context, index) {
                final procedureKind = widget.viewModel.procedureKinds[index];
                final isSelected = _selectedProcedureKindId == procedureKind.id;
                return InkWell(
                  key: Key('procedure_kind_row_${procedureKind.id}'),
                  onTap: () {
                    setState(() {
                      _selectedProcedureKindId = procedureKind.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                          width: 36,
                          child: Text(isSelected ? '▶' : ''),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(procedureKind.pattern.shortName),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(procedureKind.name),
                        ),
                        Expanded(child: Text('${procedureKind.capacity}')),
                        Expanded(
                          child: Text('${procedureKind.participantBusyTime}'),
                        ),
                        Expanded(
                          child: Text(
                            procedureKind.assistantBusyTime?.toString() ?? '',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            procedureKind.resourceBusyTime?.toString() ?? '',
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: TextButton(
                            key: Key('procedure_kind_edit_${procedureKind.id}'),
                            onPressed: widget.viewModel.isSaving
                                ? null
                                : () => unawaited(
                                      _openEditDialog(procedureKind),
                                    ),
                            child: const Text('Изм.'),
                          ),
                        ),
                        SizedBox(
                          width: 72,
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
    );
  }
}
