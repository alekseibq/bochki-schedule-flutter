import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../features/participants/participants_dialog.dart';
import '../../features/participants/participants_view_model.dart';
import '../../features/trainers/trainers_dialog.dart';
import '../../features/trainers/trainers_view_model.dart';

enum DirectorySection {
  trainers('Тренеры'),
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
  bool _participantsDialogOpen = false;
  bool _trainersDialogOpen = false;

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

  Future<void> _openTrainersDialog() async {
    if (_trainersDialogOpen) {
      return;
    }

    setState(() {
      _trainersDialogOpen = true;
    });

    final viewModel = TrainersViewModel(
      listTrainersUseCase: widget.services.listTrainersUseCase,
      createTrainerUseCase: widget.services.createTrainerUseCase,
      updateTrainerUseCase: widget.services.updateTrainerUseCase,
      deleteTrainerUseCase: widget.services.deleteTrainerUseCase,
    );

    try {
      unawaited(viewModel.loadTrainers());
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return TrainersDialog(viewModel: viewModel);
        },
      );
    } finally {
      viewModel.dispose();
      if (mounted) {
        setState(() {
          _trainersDialogOpen = false;
        });
      }
    }
  }

  void _selectDirectorySection(DirectorySection section) {
    if (section == DirectorySection.trainers) {
      unawaited(_openTrainersDialog());
      return;
    }

    unawaited(_openParticipantsDialog());
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
                      value: DirectorySection.trainers,
                      child: Text('Тренеры'),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const _HomePlaceholder(),
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
