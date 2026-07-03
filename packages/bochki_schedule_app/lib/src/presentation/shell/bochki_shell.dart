import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../features/participants/participants_dialog.dart';
import '../../features/participants/participants_view_model.dart';

enum DirectorySection {
  trainers('Тренеры', 'Раздел тренеров находится в разработке.'),
  participants('Участники', 'Откройте диалог участников для редактирования.');

  const DirectorySection(this.title, this.description);

  final String title;
  final String description;
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
  DirectorySection? _selectedSection;
  bool _participantsDialogOpen = false;

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

  void _selectDirectorySection(DirectorySection section) {
    if (section == DirectorySection.trainers) {
      setState(() {
        _selectedSection = section;
      });
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
              child: _selectedSection == null
                  ? const _HomePlaceholder()
                  : _SectionPlaceholder(section: _selectedSection!),
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
                'Выберите раздел из меню "Справочники", чтобы открыть экран-заглушку.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({
    required this.section,
  });

  final DirectorySection section;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D7DE)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            key: Key('placeholder_${section.name}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                section.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                section.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
