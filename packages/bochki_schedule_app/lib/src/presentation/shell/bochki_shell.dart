import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

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
import '../../features/quick_reassignments/quick_reassignments_dialog.dart';
import '../../features/quick_reassignments/quick_reassignments_view_model.dart';
import '../desktop_windows.dart';

enum DirectorySection {
  procedureKinds('Процедуры'),
  workdays('Дни'),
  assistants('Ассистенты'),
  participants('Участники'),
  settings('Настройки');

  const DirectorySection(this.title);

  final String title;
}

enum ReportsSection { statistics, procedureStatistics, freeTime }

enum TemplatesSection { create, load, delete }

class BochkiShell extends StatefulWidget {
  const BochkiShell({
    required this.services,
    this.onProjectLoaded,
    super.key,
  });

  final AppServices services;
  final Future<void> Function()? onProjectLoaded;

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
  bool _quickReassignmentsDialogOpen = false;
  bool _templatesDialogOpen = false;
  int? _procedureKindsCount;
  int? _workdaysCount;
  int? _assistantsCount;
  int? _participantsCount;
  late final ProcedureSessionsViewModel _procedureSessionsViewModel;
  DesktopWindowCoordinator? _desktopWindows;
  StreamSubscription<void>? _windowsSubscription;
  bool _hasChildWindows = false;

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
    final statistics = widget.services.buildProcedureStatisticsTableUseCase;
    final scheduleGaps = widget.services.buildScheduleGapsUseCase;
    if (statistics != null && scheduleGaps != null) {
      _desktopWindows = DesktopWindowCoordinator(
        services: widget.services,
        statistics: statistics,
        scheduleGaps: scheduleGaps,
        sessions: _procedureSessionsViewModel,
      );
      unawaited(_startDesktopWindows());
      _windowsSubscription =
          onWindowsChanged.listen((_) => _refreshWindowModalState());
      unawaited(_refreshWindowModalState());
    }
    unawaited(_procedureSessionsViewModel.load());
    unawaited(_loadDirectoryCounts());
  }

  Future<void> _loadDirectoryCounts() async {
    await _refreshProcedureKindsCount();
    await _refreshWorkdaysCount();
    await _refreshAssistantsCount();
    await _refreshParticipantsCount();
  }

  Future<void> _refreshProcedureKindsCount() async {
    try {
      final count =
          (await widget.services.listProcedureKindsUseCase.execute()).length;
      if (mounted) {
        setState(() => _procedureKindsCount = count);
      }
    } catch (_) {
      // Keep the most recently loaded value, if any.
    }
  }

  Future<void> _refreshWorkdaysCount() async {
    try {
      final count =
          (await widget.services.listWorkdaysUseCase.execute()).length;
      if (mounted) {
        setState(() => _workdaysCount = count);
      }
    } catch (_) {
      // Keep the most recently loaded value, if any.
    }
  }

  Future<void> _refreshAssistantsCount() async {
    try {
      final count =
          (await widget.services.listAssistantsUseCase.execute()).length;
      if (mounted) {
        setState(() => _assistantsCount = count);
      }
    } catch (_) {
      // Keep the most recently loaded value, if any.
    }
  }

  Future<void> _refreshParticipantsCount() async {
    try {
      final count =
          (await widget.services.listParticipantsUseCase.execute()).length;
      if (mounted) {
        setState(() => _participantsCount = count);
      }
    } catch (_) {
      // Keep the most recently loaded value, if any.
    }
  }

  String _directoryMenuLabel(DirectorySection section) {
    final count = switch (section) {
      DirectorySection.procedureKinds => _procedureKindsCount,
      DirectorySection.workdays => _workdaysCount,
      DirectorySection.assistants => _assistantsCount,
      DirectorySection.participants => _participantsCount,
      DirectorySection.settings => null,
    };
    return count == null ? section.title : '${section.title} ($count)';
  }

  Future<void> _startDesktopWindows() async {
    try {
      await _desktopWindows?.start();
    } catch (_) {
      // The channel is not present in widget tests and unsupported targets.
    }
  }

  @override
  void dispose() {
    _windowsSubscription?.cancel();
    unawaited(_desktopWindows?.closeChildren());
    unawaited(_desktopWindows?.dispose());
    _procedureSessionsViewModel.dispose();
    super.dispose();
  }

  Future<void> _refreshWindowModalState() async {
    try {
      final windows = await WindowController.getAll();
      final active = windows.any((window) =>
          windowKindFromArguments(window.arguments) != DesktopWindowKind.main);
      if (mounted && active != _hasChildWindows) {
        setState(() => _hasChildWindows = active);
      }
    } catch (_) {
      // Multi-window APIs are intentionally absent from widget tests.
    }
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
      await _refreshProcedureKindsCount();
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
      await _refreshParticipantsCount();
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
      await _refreshWorkdaysCount();
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
      await _refreshAssistantsCount();
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
      savePrintScheduleFileUseCase:
          widget.services.savePrintScheduleFileUseCase,
      openPrintScheduleFileUseCase:
          widget.services.openPrintScheduleFileUseCase,
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

  Future<void> _openStatistics() async {
    try {
      final useCase = widget.services.openProcedureStatisticsFileUseCase;
      if (useCase == null) {
        return;
      }
      await useCase.execute();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сформировать отчёт: $error')),
      );
    }
  }

  Future<void> _openProcedureStatistics() async {
    await _desktopWindows?.openStatistics();
  }

  Future<void> _openFreeTime() async => _desktopWindows?.openFreeTime();

  Future<void> _openQuickReassignments() async {
    if (_quickReassignmentsDialogOpen ||
        widget.services.quickReassignmentsUseCase == null) {
      return;
    }
    setState(() => _quickReassignmentsDialogOpen = true);
    final viewModel = QuickReassignmentsViewModel(
      sessions: widget.services.listRichProcedureSessionsUseCase,
      workdays: widget.services.listWorkdaysUseCase,
      humans: widget.services.listHumansUseCase,
      settings: widget.services.getProgramSettingsUseCase,
      mutations: widget.services.quickReassignmentsUseCase!,
    );
    try {
      await viewModel.load();
      if (mounted) {
        await showDialog<void>(
            context: context,
            builder: (_) => QuickReassignmentsDialog(viewModel: viewModel));
      }
    } finally {
      viewModel.dispose();
      unawaited(_procedureSessionsViewModel.load());
      if (mounted) setState(() => _quickReassignmentsDialogOpen = false);
    }
  }

  Future<void> _selectTemplateSection(TemplatesSection section) async {
    if (widget.services.templateService == null) return;
    if (_templatesDialogOpen) return;
    setState(() => _templatesDialogOpen = true);
    try {
      switch (section) {
        case TemplatesSection.create:
          await _createTemplate();
          return;
        case TemplatesSection.load:
          await _chooseTemplate(isDelete: false);
          return;
        case TemplatesSection.delete:
          await _chooseTemplate(isDelete: true);
          return;
      }
    } finally {
      if (mounted) setState(() => _templatesDialogOpen = false);
    }
  }

  Future<void> _createTemplate() async {
    final templateService = widget.services.templateService;
    if (templateService == null) return;
    final controller = TextEditingController();
    try {
      final title = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Создать шаблон'),
          content: TextField(
            key: const Key('template_title_field'),
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название шаблона'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: const Text('Сохранить')),
          ],
        ),
      );
      if (title == null) return;
      final error = templateService.validateTitle(title);
      if (error.isNotEmpty) {
        _showError(error);
        return;
      }
      final existing = await templateService.existingForTitle(title);
      if (existing != null &&
          !await _confirm('Перезаписать шаблон?',
              'Шаблон «${existing.displayName}» уже существует.')) return;
      await templateService.save(title);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Шаблон сохранён.')));
      }
    } catch (error) {
      _showError('Не удалось сохранить шаблон: $error');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _chooseTemplate({required bool isDelete}) async {
    final templateService = widget.services.templateService;
    if (templateService == null) return;
    final templates = await templateService.list();
    if (!mounted) return;
    TemplateFile? selected;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(isDelete ? 'Удалить шаблон' : 'Загрузить данные из шаблона'),
          content: SizedBox(
            width: 520,
            height: 300,
            child: templates.isEmpty
                ? const Center(child: Text('Сохранённых шаблонов нет.'))
                : ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (_, index) {
                      final template = templates[index];
                      return RadioListTile<TemplateFile>(
                        value: template,
                        groupValue: selected,
                        title: Text(template.displayName),
                        onChanged: (value) =>
                            setDialogState(() => selected = value),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена')),
            FilledButton(
              style: isDelete
                  ? FilledButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              onPressed:
                  selected == null ? null : () => Navigator.pop(dialogContext),
              child: Text(isDelete ? 'Удалить' : 'Загрузить'),
            ),
          ],
        ),
      ),
    );
    final template = selected;
    if (template == null || !mounted) return;
    if (isDelete) {
      if (!await _confirm('Удалить шаблон?',
          'Шаблон «${template.displayName}» будет удалён без возможности восстановления.',
          destructive: true)) return;
      await templateService.delete(template);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Шаблон удалён.')));
      }
      return;
    }
    if (!await _confirm('Загрузить шаблон?',
        'Текущие данные будут заменены шаблоном «${template.displayName}».')) {
      return;
    }
    try {
      await templateService.load(template);
      await widget.onProjectLoaded?.call();
    } catch (error) {
      _showError('Не удалось загрузить шаблон: $error');
    }
  }

  Future<bool> _confirm(String title, String content,
          {bool destructive = false}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена')),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(destructive ? 'Удалить' : 'Загрузить'),
            ),
          ],
        ),
      ) ??
      false;

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _selectDirectorySection(DirectorySection section) {
    switch (section) {
      case DirectorySection.procedureKinds:
        if (_desktopWindows case final coordinator?) {
          unawaited(
              coordinator.openDirectory(DesktopWindowKind.procedureKinds));
        } else {
          unawaited(_openProcedureKindsDialog());
        }
        return;
      case DirectorySection.workdays:
        if (_desktopWindows case final coordinator?) {
          unawaited(coordinator.openDirectory(DesktopWindowKind.workdays));
        } else {
          unawaited(_openWorkdaysDialog());
        }
        return;
      case DirectorySection.assistants:
        if (_desktopWindows case final coordinator?) {
          unawaited(coordinator.openDirectory(DesktopWindowKind.assistants));
        } else {
          unawaited(_openAssistantsDialog());
        }
        return;
      case DirectorySection.participants:
        if (_desktopWindows case final coordinator?) {
          unawaited(coordinator.openDirectory(DesktopWindowKind.participants));
        } else {
          unawaited(_openParticipantsDialog());
        }
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
    if (!isEditing) {
      await _desktopWindows?.openSession();
      return;
    }
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
          humans: _procedureSessionsViewModel.humans,
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

    return AbsorbPointer(
      absorbing: _hasChildWindows,
      child: Scaffold(
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
                      tooltip: 'Данные',
                      popUpAnimationStyle: AnimationStyle.noAnimation,
                      onSelected: _selectDirectorySection,
                      itemBuilder: (context) => [
                        PopupMenuItem<DirectorySection>(
                          value: DirectorySection.participants,
                          child: Text(
                            _directoryMenuLabel(DirectorySection.participants),
                          ),
                        ),
                        PopupMenuItem<DirectorySection>(
                          value: DirectorySection.assistants,
                          child: Text(
                            _directoryMenuLabel(DirectorySection.assistants),
                          ),
                        ),
                        PopupMenuItem<DirectorySection>(
                          value: DirectorySection.procedureKinds,
                          child: Text(
                            _directoryMenuLabel(
                                DirectorySection.procedureKinds),
                          ),
                        ),
                        PopupMenuItem<DirectorySection>(
                          value: DirectorySection.workdays,
                          child: Text(
                            _directoryMenuLabel(DirectorySection.workdays),
                          ),
                        ),
                        const PopupMenuItem<DirectorySection>(
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
                            Text('Данные'),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<ReportsSection>(
                      key: const Key('reports_menu_button'),
                      tooltip: 'Отчёты',
                      onSelected: (section) =>
                          unawaited(section == ReportsSection.statistics
                              ? _openStatistics()
                              : section == ReportsSection.procedureStatistics
                                  ? _openProcedureStatistics()
                                  : _openFreeTime()),
                      itemBuilder: (context) => const [
                        PopupMenuItem<ReportsSection>(
                          value: ReportsSection.statistics,
                          child: Text('Статистика по сопровождениям'),
                        ),
                        PopupMenuItem<ReportsSection>(
                          value: ReportsSection.procedureStatistics,
                          child: Text('Статистика процедур'),
                        ),
                        PopupMenuItem<ReportsSection>(
                          value: ReportsSection.freeTime,
                          child: Text('Свободное время'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white.withOpacity(0.72),
                          border: Border.all(color: const Color(0xFFD0D7DE)),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Отчёты'),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_drop_down, size: 18),
                            ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      key: const Key('print_preset_params_button'),
                      onPressed: _openPrintPresetParamsDialog,
                      child: const Text('Распечатки'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      key: const Key('quick_reassignments_button'),
                      onPressed: _openQuickReassignments,
                      child: const Text('Быстрые перестановки'),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<TemplatesSection>(
                      key: const Key('templates_menu_button'),
                      tooltip: 'Шаблоны',
                      popUpAnimationStyle: AnimationStyle.noAnimation,
                      onSelected: (section) =>
                          unawaited(_selectTemplateSection(section)),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: TemplatesSection.create,
                            child: Text('Создать шаблон')),
                        PopupMenuItem(
                            value: TemplatesSection.load,
                            child: Text('Загрузить данные из шаблона')),
                        PopupMenuItem(
                            value: TemplatesSection.delete,
                            child: Text('Удалить шаблон')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white.withOpacity(0.72),
                          border: Border.all(color: const Color(0xFFD0D7DE)),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Шаблоны'),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_drop_down, size: 18),
                            ]),
                      ),
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
      ),
    );
  }
}

class _ProcedureSessionsHome extends StatelessWidget {
  static const Color _filtersResultsDividerColor = Color(0xFFC4CDD5);

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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    key: Key('procedure_sessions_filters_results_divider'),
                    height: 1,
                    thickness: 1,
                    color: _filtersResultsDividerColor,
                  ),
                ),
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
    final dayOptions = [
      'Все',
      for (final workday in viewModel.workdays) workday.name,
    ];
    final partOfDayOptions = [
      for (final filter in ProcedureSessionsPartOfDayFilter.values)
        filter.label,
    ];
    final procedureOptions = [
      'Все',
      for (final procedureKind in viewModel.procedureKinds) procedureKind.name,
    ];
    final participantOptions = [
      'Все',
      for (final participant in viewModel.participants) participant.name,
    ];

    return SingleChildScrollView(
      key: const Key('procedure_sessions_filters_scroll_view'),
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterField(
                  label: 'День',
                  width: _dropdownWidth(context, dayOptions),
                  child: DropdownButtonFormField<String?>(
                    key: const Key('procedure_sessions_day_filter'),
                    value: viewModel.selectedDayId,
                    decoration: const InputDecoration(isDense: true),
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
                const SizedBox(width: 24),
                _FilterField(
                  label: 'Часть дня',
                  width: _dropdownWidth(context, partOfDayOptions),
                  child:
                      DropdownButtonFormField<ProcedureSessionsPartOfDayFilter>(
                    key: const Key('procedure_sessions_part_of_day_filter'),
                    value: viewModel.partOfDayFilter,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      for (final filter
                          in ProcedureSessionsPartOfDayFilter.values)
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
                const SizedBox(width: 24),
                _FilterField(
                  label: 'Процедура',
                  width: _dropdownWidth(context, procedureOptions),
                  child: DropdownButtonFormField<String?>(
                    key: const Key('procedure_sessions_procedure_filter'),
                    value: viewModel.selectedProcedureKindId,
                    decoration: const InputDecoration(isDense: true),
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
                    onChanged: (value) =>
                        viewModel.setProcedureKindFilter(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterField(
                  label: 'Участник',
                  width: _dropdownWidth(context, participantOptions),
                  child: DropdownButtonFormField<String?>(
                    key: const Key('procedure_sessions_participant_filter'),
                    value: viewModel.selectedParticipantId,
                    decoration: const InputDecoration(isDense: true),
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
                const SizedBox(width: 24),
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
        ),
      ),
    );
  }

  double _dropdownWidth(BuildContext context, List<String> options) {
    final textStyle = Theme.of(context).textTheme.bodyLarge ??
        DefaultTextStyle.of(context).style;
    final textPainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final longestOptionWidth = options.fold(0.0, (maxWidth, option) {
      textPainter.text = TextSpan(text: option, style: textStyle);
      textPainter.layout();
      return maxWidth > textPainter.width ? maxWidth : textPainter.width;
    });
    textPainter.dispose();

    return longestOptionWidth + 64;
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: 10),
        SizedBox(width: width, child: child),
      ],
    );
  }
}

class _ProcedureSessionsTable extends StatefulWidget {
  const _ProcedureSessionsTable({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final ProcedureSessionsViewModel viewModel;
  final void Function(String entryId) onEdit;
  final void Function(String entryId) onDelete;

  @override
  State<_ProcedureSessionsTable> createState() =>
      _ProcedureSessionsTableState();
}

class _ProcedureSessionsTableState extends State<_ProcedureSessionsTable> {
  static const double _headerHeight = 32;
  static const double _rowHeight = 30;
  static const double _conflictColumnWidth = 40;
  static const double _actionColumnWidth = 48;
  static const Color _dividerColor = Color(0xFFD7DFE8);

  late List<double> _dataColumnWidths;

  @override
  void initState() {
    super.initState();
    _dataColumnWidths =
        _dataColumns.map((column) => column.initialWidth).toList();
  }

  void _resizeColumns(int leftColumnIndex, double delta) {
    final leftColumn = _dataColumns[leftColumnIndex];
    final rightColumn = _dataColumns[leftColumnIndex + 1];
    final leftWidth = _dataColumnWidths[leftColumnIndex];
    final rightWidth = _dataColumnWidths[leftColumnIndex + 1];
    final actualDelta = delta.clamp(
      leftColumn.minimumWidth - leftWidth,
      rightWidth - rightColumn.minimumWidth,
    );

    if (actualDelta == 0) {
      return;
    }
    setState(() {
      _dataColumnWidths[leftColumnIndex] = leftWidth + actualDelta;
      _dataColumnWidths[leftColumnIndex + 1] = rightWidth - actualDelta;
    });
  }

  void _handleRowPointerDown(String entryId, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }
    widget.viewModel.selectEntry(entryId);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.viewModel.entries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          widget.viewModel.showConflictsOnly
              ? 'Конфликтов по текущим фильтрам нет.'
              : 'Список назначенных процедур пуст.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = _tableWidth < constraints.maxWidth
            ? constraints.maxWidth
            : _tableWidth;
        return SingleChildScrollView(
          key: const Key('procedure_sessions_table_horizontal_scroll'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: _dividerColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _dividerColor),
                    itemBuilder: (context, index) => _buildRow(entries[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double get _tableWidth =>
      _dataColumnWidths.fold<double>(0, (sum, width) => sum + width) +
      _conflictColumnWidth +
      (_actionColumnWidth * 2);

  Widget _buildHeader() {
    return Container(
      key: const Key('procedure_sessions_table_header'),
      height: _headerHeight,
      color: const Color(0xFFF2F5F8),
      child: Row(
        children: [
          for (var index = 0; index < _dataColumns.length; index++)
            _ResizableHeaderCell(
              key: Key('procedure_sessions_column_header_$index'),
              width: _dataColumnWidths[index],
              text: _dataColumns[index].label,
              showResizeHandle: index < _dataColumns.length - 1,
              onResize: (delta) => _resizeColumns(index, delta),
              resizeHandleKey: Key('procedure_sessions_column_resizer_$index'),
            ),
          const _TableCell(width: _conflictColumnWidth),
          const _TableCell(width: _actionColumnWidth),
          const _TableCell(width: _actionColumnWidth, showRightDivider: false),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic entry) {
    final isSelected = widget.viewModel.selectedEntryId == entry.id;
    final hasConflicts = entry.hasConflicts;
    return Listener(
      onPointerDown: (event) => _handleRowPointerDown(entry.id, event),
      child: GestureDetector(
        key: Key('procedure_session_row_${entry.id}'),
        onTap: () => widget.viewModel.selectEntry(entry.id),
        onDoubleTap: () => widget.onEdit(entry.id),
        child: Container(
          key: Key('procedure_session_row_content_${entry.id}'),
          height: _rowHeight,
          decoration: BoxDecoration(
            color: isSelected
                ? (hasConflicts
                    ? const Color(0xFFFFE6E2)
                    : const Color(0xFFE7F1FB))
                : (hasConflicts ? const Color(0xFFFFF4F2) : Colors.white),
          ),
          child: Row(
            children: [
              _TableCell(width: _dataColumnWidths[0], text: _dayText(entry)),
              _buildPersonSummaryCell(
                width: _dataColumnWidths[1],
                entryId: entry.id,
                column: 'participant',
                humanId: entry.participant?.id,
                humanName: entry.participant?.name,
                fallbackText: _participantText(entry),
              ),
              _TableCell(width: _dataColumnWidths[2], text: entry.startTime),
              _TableCell(
                width: _dataColumnWidths[3],
                text: entry.finishTime ?? '',
              ),
              _TableCell(
                width: _dataColumnWidths[4],
                text: _procedureText(entry),
              ),
              _buildPersonSummaryCell(
                width: _dataColumnWidths[5],
                entryId: entry.id,
                column: 'assistant',
                humanId: entry.requiresAssistant ? entry.assistant?.id : null,
                humanName:
                    entry.requiresAssistant ? entry.assistant?.name : null,
                fallbackText: _assistantText(entry),
              ),
              _TableCell(
                width: _conflictColumnWidth,
                alignment: Alignment.center,
                child: hasConflicts
                    ? const Tooltip(
                        message: 'Есть конфликты',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD66A57),
                          size: 18,
                        ),
                      )
                    : null,
              ),
              _TableCell(
                width: _actionColumnWidth,
                alignment: Alignment.center,
                child: TextButton(
                  key: Key('procedure_session_edit_${entry.id}'),
                  style: _compactButtonStyle,
                  onPressed: () => widget.onEdit(entry.id),
                  child: const Text('Изм.'),
                ),
              ),
              _TableCell(
                width: _actionColumnWidth,
                alignment: Alignment.center,
                showRightDivider: false,
                child: TextButton(
                  key: Key('procedure_session_delete_${entry.id}'),
                  style: _compactButtonStyle,
                  onPressed: () => widget.onDelete(entry.id),
                  child: const Text('Удл.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final ButtonStyle _compactButtonStyle = TextButton.styleFrom(
    minimumSize: Size.zero,
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

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

  Widget _buildPersonSummaryCell({
    required double width,
    required String entryId,
    required String column,
    required String? humanId,
    required String? humanName,
    required String fallbackText,
  }) {
    final cell = _TableCell(width: width, text: fallbackText);
    if (humanId == null || humanName == null) {
      return cell;
    }

    return Tooltip(
      key: Key('procedure_session_${column}_summary_$entryId'),
      message: widget.viewModel.participantSummaryTooltip(
        humanId: humanId,
        humanName: humanName,
      ),
      waitDuration: const Duration(milliseconds: 300),
      exitDuration: Duration.zero,
      child: cell,
    );
  }
}

const List<_ProcedureSessionsDataColumn> _dataColumns = [
  _ProcedureSessionsDataColumn('День', 75, 60),
  _ProcedureSessionsDataColumn('Участник', 180, 110),
  _ProcedureSessionsDataColumn('Начало', 75, 60),
  _ProcedureSessionsDataColumn('Конец', 75, 60),
  _ProcedureSessionsDataColumn('Процедура', 220, 130),
  _ProcedureSessionsDataColumn('Ассистент/Напарник', 180, 120),
];

class _ProcedureSessionsDataColumn {
  const _ProcedureSessionsDataColumn(
    this.label,
    this.initialWidth,
    this.minimumWidth,
  );

  final String label;
  final double initialWidth;
  final double minimumWidth;
}

class _ResizableHeaderCell extends StatelessWidget {
  const _ResizableHeaderCell({
    required this.width,
    required this.text,
    required this.showResizeHandle,
    required this.onResize,
    required this.resizeHandleKey,
    super.key,
  });

  final double width;
  final String text;
  final bool showResizeHandle;
  final ValueChanged<double> onResize;
  final Key resizeHandleKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _TableCell(
            width: width,
            text: text,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (showResizeHandle)
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
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.width,
    this.text,
    this.child,
    this.alignment = Alignment.centerLeft,
    this.textStyle,
    this.showRightDivider = true,
  });

  final double width;
  final String? text;
  final Widget? child;
  final Alignment alignment;
  final TextStyle? textStyle;
  final bool showRightDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: showRightDivider
            ? const Border(right: BorderSide(color: Color(0xFFD7DFE8)))
            : null,
      ),
      child: child ??
          Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
    );
  }
}
