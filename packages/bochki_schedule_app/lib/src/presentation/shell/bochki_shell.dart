import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../features/participants/participants_dialog.dart';
import '../../features/participants/participants_view_model.dart';
import '../../features/print_presets/print_preset_params_dialog.dart';
import '../../features/print_presets/print_preset_params_view_model.dart';
import '../../features/procedure_sessions/procedure_session_dialog.dart';
import '../../features/procedure_sessions/procedure_sessions_view_model.dart';
import '../../features/procedure_kinds/procedure_kinds_dialog.dart';
import '../../features/procedure_kinds/procedure_kinds_view_model.dart';
import '../../features/program_settings/program_settings_dialog.dart';
import '../../features/program_settings/program_settings_view_model.dart';
import '../../features/assistants/assistants_dialog.dart';
import '../../features/assistants/assistants_view_model.dart';
import '../../features/workdays/workdays_dialog.dart';
import '../../features/workdays/workdays_view_model.dart';

enum DirectorySection {
  procedureKinds('Процедуры'),
  workdays('Дни'),
  assistants('Ассистенты'),
  participants('Участники'),
  settings('Настройки');

  const DirectorySection(this.title);

  final String title;
}

class BochkiShell extends StatefulWidget {
  const BochkiShell({
    required this.services,
    super.key,
  });

  final AppServices services;

  @override
  State<BochkiShell> createState() => _BochkiShellState();
}

class _BochkiShellState extends State<BochkiShell> {
  bool _procedureKindsDialogOpen = false;
  bool _workdaysDialogOpen = false;
  bool _participantsDialogOpen = false;
  bool _assistantsDialogOpen = false;
  bool _programSettingsDialogOpen = false;
  bool _printPresetParamsDialogOpen = false;
  late final ProcedureSessionsViewModel _procedureSessionsViewModel;

  @override
  void initState() {
    super.initState();
    _procedureSessionsViewModel = ProcedureSessionsViewModel(
      listProcedureSessionsWithConflictsUseCase:
          widget.services.listProcedureSessionsWithConflictsUseCase,
      createProcedureSessionUseCase:
          widget.services.createProcedureSessionUseCase,
      updateProcedureSessionUseCase:
          widget.services.updateProcedureSessionUseCase,
      deleteProcedureSessionUseCase:
          widget.services.deleteProcedureSessionUseCase,
      listWorkdaysUseCase: widget.services.listWorkdaysUseCase,
      listHumansUseCase: widget.services.listHumansUseCase,
      listProcedureKindsUseCase: widget.services.listProcedureKindsUseCase,
      listAssistantsUseCase: widget.services.listAssistantsUseCase,
      getProgramSettingsUseCase: widget.services.getProgramSettingsUseCase,
    );
    unawaited(_procedureSessionsViewModel.load());
  }

  @override
  void dispose() {
    _procedureSessionsViewModel.dispose();
    super.dispose();
  }

  Future<void> _openProcedureKindsDialog() async {
    if (_procedureKindsDialogOpen) {
      return;
    }

    setState(() {
      _procedureKindsDialogOpen = true;
    });

    final viewModel = ProcedureKindsViewModel(
      listProcedureKindsUseCase: widget.services.listProcedureKindsUseCase,
      createProcedureKindUseCase: widget.services.createProcedureKindUseCase,
      updateProcedureKindUseCase: widget.services.updateProcedureKindUseCase,
      deleteProcedureKindUseCase: widget.services.deleteProcedureKindUseCase,
    );

    try {
      unawaited(viewModel.loadProcedureKinds());
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProcedureKindsDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _procedureKindsDialogOpen = false;
        });
      }
    }
  }

  Future<void> _openParticipantsDialog() async {
    if (_participantsDialogOpen) {
      return;
    }

    setState(() {
      _participantsDialogOpen = true;
    });

    final viewModel = ParticipantsViewModel(
      listParticipantsUseCase: widget.services.listParticipantsUseCase,
      createParticipantUseCase: widget.services.createParticipantUseCase,
      updateParticipantUseCase: widget.services.updateParticipantUseCase,
      deleteParticipantUseCase: widget.services.deleteParticipantUseCase,
    );

    try {
      unawaited(viewModel.loadParticipants());
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ParticipantsDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _participantsDialogOpen = false;
        });
      }
    }
  }

  Future<void> _openWorkdaysDialog() async {
    if (_workdaysDialogOpen) {
      return;
    }

    setState(() {
      _workdaysDialogOpen = true;
    });

    final viewModel = WorkdaysViewModel(
      listWorkdaysUseCase: widget.services.listWorkdaysUseCase,
      createWorkdayUseCase: widget.services.createWorkdayUseCase,
      updateWorkdayUseCase: widget.services.updateWorkdayUseCase,
      deleteWorkdayUseCase: widget.services.deleteWorkdayUseCase,
    );

    try {
      unawaited(viewModel.loadWorkdays());
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WorkdaysDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _workdaysDialogOpen = false;
        });
      }
    }
  }

  Future<void> _openAssistantsDialog() async {
    if (_assistantsDialogOpen) {
      return;
    }

    setState(() {
      _assistantsDialogOpen = true;
    });

    final viewModel = AssistantsViewModel(
      listAssistantsUseCase: widget.services.listAssistantsUseCase,
      createAssistantUseCase: widget.services.createAssistantUseCase,
      updateAssistantUseCase: widget.services.updateAssistantUseCase,
      deleteAssistantUseCase: widget.services.deleteAssistantUseCase,
    );

    try {
      unawaited(viewModel.loadAssistants());
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AssistantsDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _assistantsDialogOpen = false;
        });
      }
    }
  }

  Future<void> _openProgramSettingsDialog() async {
    if (_programSettingsDialogOpen) {
      return;
    }

    setState(() {
      _programSettingsDialogOpen = true;
    });

    final viewModel = ProgramSettingsViewModel(
      getProgramSettingsUseCase: widget.services.getProgramSettingsUseCase,
      updateProgramSettingsUseCase:
          widget.services.updateProgramSettingsUseCase,
    );

    try {
      await viewModel.loadProgramSettings();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProgramSettingsDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      unawaited(_procedureSessionsViewModel.load());
      if (mounted) {
        setState(() {
          _programSettingsDialogOpen = false;
        });
      }
    }
  }

  Future<void> _openPrintPresetParamsDialog() async {
    if (_printPresetParamsDialogOpen) {
      return;
    }

    setState(() {
      _printPresetParamsDialogOpen = true;
    });

    final viewModel = PrintPresetParamsViewModel(
      getPrintPresetParamsUseCase: widget.services.getPrintPresetParamsUseCase,
      updatePrintPresetParamsUseCase:
          widget.services.updatePrintPresetParamsUseCase,
      savePrintScheduleFileUseCase: widget.services.savePrintScheduleFileUseCase,
      openPrintScheduleFileUseCase: widget.services.openPrintScheduleFileUseCase,
      listWorkdaysUseCase: widget.services.listWorkdaysUseCase,
    );

    try {
      await viewModel.load();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PrintPresetParamsDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _printPresetParamsDialogOpen = false;
        });
      }
    }
  }

  void _selectDirectorySection(DirectorySection section) {
    switch (section) {
      case DirectorySection.procedureKinds:
        unawaited(_openProcedureKindsDialog());
        return;
      case DirectorySection.workdays:
        unawaited(_openWorkdaysDialog());
        return;
      case DirectorySection.assistants:
        unawaited(_openAssistantsDialog());
        return;
      case DirectorySection.participants:
        unawaited(_openParticipantsDialog());
        return;
      case DirectorySection.settings:
        unawaited(_openProgramSettingsDialog());
        return;
    }
  }

  Future<void> _openProcedureSessionDialog({
    required bool isEditing,
    String? procedureSessionId,
  }) async {
    final initialValue = isEditing
        ? _procedureSessionsViewModel.entries
            .firstWhere((entry) => entry.id == procedureSessionId!)
            .raw
        : _procedureSessionsViewModel.createDraft();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProcedureSessionDialog(
          initialValue: initialValue,
          workdays: _procedureSessionsViewModel.workdays,
          participants: _procedureSessionsViewModel.participants,
          procedureKinds: _procedureSessionsViewModel.procedureKinds,
          assistants: _procedureSessionsViewModel.assistants,
          programSettings: _procedureSessionsViewModel.programSettings,
          onSubmit: (procedureSession, allowConflicts) {
            return _procedureSessionsViewModel.submitProcedureSession(
              procedureSession,
              allowConflicts: allowConflicts,
            );
          },
          isSaving: _procedureSessionsViewModel.isSaving,
        );
      },
    );
  }

  Future<void> _confirmDeleteProcedureSession(String procedureSessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить запись?'),
          content: const Text('Назначенная процедура будет удалена из списка.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              key: const Key('confirm_delete_procedure_session_button'),
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
    final isSuccess = await _procedureSessionsViewModel.deleteProcedureSession(
      procedureSessionId,
    );
    if (!mounted || isSuccess) {
      return;
    }
    final message = _procedureSessionsViewModel.actionErrorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _procedureSessionsViewModel.clearActionError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE9EEF2),
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D7DE)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'ПО Расписание Бочки',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  FilledButton.tonal(
                    key: const Key('add_procedure_session_button'),
                    onPressed: () =>
                        _openProcedureSessionDialog(isEditing: false),
                    child: const Text('Добавить запись...'),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<DirectorySection>(
                    key: const Key('directories_menu_button'),
                    tooltip: 'Справочники',
                    onSelected: _selectDirectorySection,
                    itemBuilder: (context) => const [
                      PopupMenuItem<DirectorySection>(
                        value: DirectorySection.procedureKinds,
                        child: Text('Процедуры'),
                      ),
                      PopupMenuItem<DirectorySection>(
                        value: DirectorySection.workdays,
                        child: Text('Дни'),
                      ),
                      PopupMenuItem<DirectorySection>(
                        value: DirectorySection.assistants,
                        child: Text('Ассистенты'),
                      ),
                      PopupMenuItem<DirectorySection>(
                        value: DirectorySection.participants,
                        child: Text('Участники'),
                      ),
                      PopupMenuItem<DirectorySection>(
                        value: DirectorySection.settings,
                        child: Text('Настройки'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withOpacity(0.72),
                        border: Border.all(color: const Color(0xFFD0D7DE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Справочники'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    key: const Key('print_preset_params_button'),
                    onPressed: _openPrintPresetParamsDialog,
                    child: const Text('Распечатки'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _ProcedureSessionsHome(
                viewModel: _procedureSessionsViewModel,
                onEdit: (entryId) {
                  unawaited(
                    _openProcedureSessionDialog(
                      isEditing: true,
                      procedureSessionId: entryId,
                    ),
                  );
                },
                onDelete: (entryId) {
                  unawaited(_confirmDeleteProcedureSession(entryId));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcedureSessionsHome extends StatelessWidget {
  const _ProcedureSessionsHome({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final ProcedureSessionsViewModel viewModel;
  final void Function(String entryId) onEdit;
  final void Function(String entryId) onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD0D7DE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProcedureSessionFilters(viewModel: viewModel),
                const SizedBox(height: 20),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.loadErrorMessage != null
                          ? Center(child: Text(viewModel.loadErrorMessage!))
                          : _ProcedureSessionsTable(
                              viewModel: viewModel,
                              onEdit: onEdit,
                              onDelete: onDelete,
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProcedureSessionFilters extends StatelessWidget {
  const _ProcedureSessionFilters({
    required this.viewModel,
  });

  final ProcedureSessionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('procedure_sessions_day_filter'),
                value: viewModel.selectedDayId,
                decoration: const InputDecoration(labelText: 'День'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все'),
                  ),
                  for (final workday in viewModel.workdays)
                    DropdownMenuItem<String?>(
                      value: workday.id,
                      child: Text(workday.name),
                    ),
                ],
                onChanged: (value) => viewModel.setDayFilter(value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<ProcedureSessionsPartOfDayFilter>(
                key: const Key('procedure_sessions_part_of_day_filter'),
                value: viewModel.partOfDayFilter,
                decoration: const InputDecoration(labelText: 'Часть дня'),
                items: [
                  for (final filter in ProcedureSessionsPartOfDayFilter.values)
                    DropdownMenuItem<ProcedureSessionsPartOfDayFilter>(
                      value: filter,
                      child: Text(filter.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    viewModel.setPartOfDayFilter(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('procedure_sessions_procedure_filter'),
                value: viewModel.selectedProcedureKindId,
                decoration: const InputDecoration(labelText: 'Процедура'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все'),
                  ),
                  for (final procedureKind in viewModel.procedureKinds)
                    DropdownMenuItem<String?>(
                      value: procedureKind.id,
                      child: Text(procedureKind.name),
                    ),
                ],
                onChanged: (value) => viewModel.setProcedureKindFilter(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('procedure_sessions_participant_filter'),
                value: viewModel.selectedParticipantId,
                decoration: const InputDecoration(labelText: 'Участник'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все'),
                  ),
                  for (final participant in viewModel.participants)
                    DropdownMenuItem<String?>(
                      value: participant.id,
                      child: Text(participant.name),
                    ),
                ],
                onChanged: (value) => viewModel.setParticipantFilter(value),
              ),
            ),
            const SizedBox(width: 16),
            Checkbox(
              key: const Key('procedure_sessions_conflicts_checkbox'),
              value: viewModel.showConflictsOnly,
              onChanged: (value) =>
                  viewModel.setShowConflictsOnly(value ?? false),
            ),
            const Text('Показать только конфликты'),
          ],
        ),
      ],
    );
  }
}

class _ProcedureSessionsTable extends StatelessWidget {
  const _ProcedureSessionsTable({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final ProcedureSessionsViewModel viewModel;
  final void Function(String entryId) onEdit;
  final void Function(String entryId) onDelete;

  void _handleRowPointerDown(String entryId, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }
    viewModel.selectEntry(entryId);
  }

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.entries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          viewModel.showConflictsOnly
              ? 'Конфликтов по текущим фильтрам нет.'
              : 'Список назначенных процедур пуст.',
        ),
      );
    }

    return Column(
      children: [
        Container(
          key: const Key('procedure_sessions_table_header'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD0D7DE)),
          ),
          child: const Row(
            children: [
              _HeaderCell(flex: 2, text: 'День'),
              _HeaderCell(flex: 2, text: 'Участник'),
              _HeaderCell(flex: 1, text: 'Начало'),
              _HeaderCell(flex: 1, text: 'Конец'),
              _HeaderCell(flex: 2, text: 'Процедура'),
              _HeaderCell(flex: 2, text: 'Ассистент/Напарник'),
              _HeaderCell(flex: 1, text: ''),
              _HeaderCell(flex: 1, text: ''),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isSelected = viewModel.selectedEntryId == entry.id;
              final hasConflicts = entry.hasConflicts;
              return Listener(
                onPointerDown: (event) =>
                    _handleRowPointerDown(entry.id, event),
                child: GestureDetector(
                  key: Key('procedure_session_row_${entry.id}'),
                  onTap: () => viewModel.selectEntry(entry.id),
                  onDoubleTap: () => onEdit(entry.id),
                  child: Container(
                    key: Key('procedure_session_row_content_${entry.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (hasConflicts
                              ? const Color(0xFFFFE6E2)
                              : const Color(0xFFE7F1FB))
                          : (hasConflicts
                              ? const Color(0xFFFFF4F2)
                              : const Color(0xFFFBFCFD)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasConflicts
                            ? const Color(0xFFD66A57)
                            : (isSelected
                                ? const Color(0xFF7AA7D9)
                                : const Color(0xFFDCE3EA)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _ValueCell(flex: 2, text: _dayText(entry)),
                        _ValueCell(flex: 2, text: _participantText(entry)),
                        _ValueCell(flex: 1, text: entry.startTime),
                        _ValueCell(flex: 1, text: entry.finishTime ?? ''),
                        _ValueCell(
                          flex: 2,
                          text: _procedureText(entry),
                        ),
                        _ValueCell(
                          flex: 2,
                          text: _assistantText(entry),
                        ),
                        SizedBox(
                          width: 28,
                          child: hasConflicts
                              ? const Tooltip(
                                  message: 'Есть конфликты',
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD66A57),
                                    size: 18,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(
                          child: TextButton(
                            key: Key('procedure_session_edit_${entry.id}'),
                            onPressed: () => onEdit(entry.id),
                            child: const Text('Изм.'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            key: Key('procedure_session_delete_${entry.id}'),
                            onPressed: () => onDelete(entry.id),
                            child: const Text('Удл.'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _dayText(dynamic entry) {
    return entry.day?.name ?? 'Ошибка: день не найден';
  }

  String _participantText(dynamic entry) {
    return entry.participant?.name ?? 'Ошибка: участник не найден';
  }

  String _procedureText(dynamic entry) {
    return entry.procedureKind?.name ?? 'Ошибка: процедура не найдена';
  }

  String _assistantText(dynamic entry) {
    if (!entry.requiresAssistant) {
      return '';
    }
    return entry.assistant?.name ?? 'Ошибка: ассистент не найден';
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.flex,
    required this.text,
  });

  final int flex;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.flex,
    required this.text,
  });

  final int flex;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text),
    );
  }
}
