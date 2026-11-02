import 'package:flutter/material.dart';

import 'participants_view_model.dart';

/// Fallback host for the participants feature.
class ParticipantsDialog extends StatelessWidget {
  const ParticipantsDialog({required this.viewModel, super.key});
  final ParticipantsViewModel viewModel;

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('participants_directory_dialog'),
        title: const Text('Список участников'),
        content: SizedBox(
          width: 700,
          height: 460,
          child: ParticipantsContent(viewModel: viewModel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      );
}

class ParticipantsContent extends StatefulWidget {
  const ParticipantsContent({required this.viewModel, super.key});
  final ParticipantsViewModel viewModel;
  @override
  State<ParticipantsContent> createState() => _ParticipantsContentState();
}

class _ParticipantsContentState extends State<ParticipantsContent> {
  final _controller = TextEditingController();
  String? _editingId;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _editingId == null
        ? await widget.viewModel.createParticipant(_controller.text)
        : await widget.viewModel.updateParticipant(
            participantId: _editingId!, rawName: _controller.text);
    if (ok && mounted)
      setState(() {
        _editingId = null;
        _controller.clear();
      });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.viewModel,
        builder: (_, __) => Column(children: [
          Row(children: [
            Expanded(
                child: TextField(
                    key: const Key('participants_name_field'),
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Имя'))),
            const SizedBox(width: 8),
            FilledButton(
                onPressed: widget.viewModel.isSaving ? null : _submit,
                child: Text(_editingId == null ? 'Создать' : 'Сохранить')),
          ]),
          if (widget.viewModel.formErrorMessage != null)
            Text(widget.viewModel.formErrorMessage!,
                style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          Expanded(
              child: widget.viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(children: [
                      for (final entry in widget.viewModel.entries)
                        ListTile(
                          key: Key('participant_${entry.id}'),
                          title: Text(entry.name),
                          onTap: () => setState(() {
                            _editingId = entry.id;
                            _controller.text = entry.name;
                          }),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: widget.viewModel.isSaving
                                  ? null
                                  : () => widget.viewModel
                                      .deleteParticipant(entry.id)),
                        ),
                    ])),
        ]),
      );
}
