import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../features/participants/participants_dialog.dart';
import '../../features/participants/participants_view_model.dart';
import '../../features/procedure_kinds/procedure_kinds_dialog.dart';
import '../../features/procedure_kinds/procedure_kinds_view_model.dart';
import '../../features/assistants/assistants_dialog.dart';
import '../../features/assistants/assistants_view_model.dart';
import '../../features/workdays/workdays_dialog.dart';
import '../../features/workdays/workdays_view_model.dart';

enum DirectorySection {
  procedureKinds('Процедуры'),
  workdays('Дни'),
  assistants('Ассистенты'),
  participants('Участники');

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
            child: Row(
              children: [
                Text(
                  'ПО Расписание Бочки',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 20),
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
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: _HomePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D7DE)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'В разработке',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Выберите раздел из меню "Справочники", чтобы открыть нужный справочник.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
