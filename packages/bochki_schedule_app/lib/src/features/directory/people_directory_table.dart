import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PeopleDirectoryType { participants, assistants }

class PeopleDirectoryEntry {
  const PeopleDirectoryEntry({
    required this.id,
    required this.name,
    this.shortName,
  });

  final String id;
  final String name;
  final String? shortName;
}

typedef PeopleDirectoryMutation = Future<String?> Function(
  String action, {
  String? id,
  String? name,
  String? shortName,
});

class PeopleDirectoryTable extends StatefulWidget {
  const PeopleDirectoryTable({
    required this.type,
    required this.entries,
    required this.onMutate,
    required this.onCountReferences,
    required this.onChanged,
    super.key,
  });

  final PeopleDirectoryType type;
  final List<PeopleDirectoryEntry> entries;
  final PeopleDirectoryMutation onMutate;
  final Future<int> Function(String entryId) onCountReferences;
  final Future<void> Function() onChanged;

  @override
  State<PeopleDirectoryTable> createState() => _PeopleDirectoryTableState();
}

class _PeopleDirectoryTableState extends State<PeopleDirectoryTable> {
  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _rowFocus = FocusNode();
  final _nameFocus = FocusNode();
  String? _editingId;
  bool _creating = false;
  bool _saving = false;
  String? _error;

  bool get _hasShortName => widget.type == PeopleDirectoryType.assistants;
  bool get _isEditing => _creating || _editingId != null;

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _rowFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _beginEdit(PeopleDirectoryEntry entry) {
    if (_saving) return;
    setState(() {
      _creating = false;
      _editingId = entry.id;
      _name.text = entry.name;
      _shortName.text = entry.shortName ?? '';
      _error = null;
    });
    _focusName();
  }

  void _beginCreate() {
    if (_saving) return;
    setState(() {
      _creating = true;
      _editingId = null;
      _name.clear();
      _shortName.clear();
      _error = null;
    });
    _focusName();
  }

  void _focusName() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _cancel() {
    if (!_isEditing || _saving) return;
    setState(() {
      _editingId = null;
      _creating = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_isEditing || _saving) return;
    setState(() => _saving = true);
    final error = await widget.onMutate(
      _creating ? 'create' : 'update',
      id: _editingId,
      name: _name.text,
      shortName: _hasShortName ? _shortName.text : null,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    setState(() {
      _saving = false;
      _editingId = null;
      _creating = false;
      _error = null;
    });
    await widget.onChanged();
  }

  Future<void> _delete(PeopleDirectoryEntry entry) async {
    if (_saving) return;
    final typeName = widget.type == PeopleDirectoryType.participants
        ? 'участника'
        : 'ассистента';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить $typeName?'),
        content: Text('Запись «${entry.name}» будет скрыта из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final referencesCount = await widget.onCountReferences(entry.id);
    if (!mounted) return;
    if (referencesCount > 0) {
      final referencesConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить связанные назначения?'),
          content: Text(
            'Запись используется в $referencesCount '
            '${_procedureWord(referencesCount)}. После удаления ссылки '
            'будут очищены, а назначения помечены конфликтными.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
      if (referencesConfirmed != true || !mounted) return;
    }
    setState(() => _saving = true);
    final error = await widget.onMutate('delete', id: entry.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) await widget.onChanged();
  }

  String _procedureWord(int count) {
    final remainder100 = count % 100;
    if (remainder100 >= 11 && remainder100 <= 14) {
      return 'назначенных процедурах';
    }
    return switch (count % 10) {
      1 => 'назначенной процедуре',
      _ => 'назначенных процедурах',
    };
  }

  bool _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      unawaited(_submit());
      return true;
    }
    return false;
  }

  Widget _field(TextEditingController controller, String label) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: TextField(
            controller: controller,
            focusNode: controller == _name ? _nameFocus : null,
            enabled: !_saving,
            decoration: InputDecoration(isDense: true, labelText: label),
          ),
        ),
      );

  Widget _row(PeopleDirectoryEntry entry) {
    final editing = _editingId == entry.id;
    final content = editing
        ? Focus(
            focusNode: _rowFocus,
            onKeyEvent: (node, event) => _onKey(node, event)
                ? KeyEventResult.handled
                : KeyEventResult.ignored,
            child: TapRegion(
              onTapOutside: (_) => unawaited(_submit()),
              child: Row(children: [
                _field(_name, 'Имя'),
                if (_hasShortName) _field(_shortName, 'Краткое имя'),
                const SizedBox(width: 180),
              ]),
            ),
          )
        : Row(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(entry.name))),
            if (_hasShortName)
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(entry.shortName ?? ''))),
            SizedBox(
              width: 180,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => _beginEdit(entry),
                    child: const Text('изм.')),
                TextButton(
                    onPressed: () => _delete(entry), child: const Text('удл.')),
              ]),
            ),
          ]);
    return InkWell(
      key: Key('people_directory_row_${entry.id}'),
      onTap: editing ? null : () => _beginEdit(entry),
      child: Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFD8E1EA)))),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF0F4F8),
            child: Row(children: [
              const Expanded(
                  child:
                      Padding(padding: EdgeInsets.all(12), child: Text('Имя'))),
              if (_hasShortName)
                const Expanded(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Краткое имя'))),
              const SizedBox(width: 180),
            ]),
          ),
          Expanded(
              child: ListView(
                  children: [for (final entry in widget.entries) _row(entry)])),
          if (_creating)
            Focus(
              focusNode: _rowFocus,
              onKeyEvent: (node, event) => _onKey(node, event)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored,
              child: TapRegion(
                onTapOutside: (_) => unawaited(_submit()),
                child: Row(children: [
                  _field(_name, 'Имя'),
                  if (_hasShortName) _field(_shortName, 'Краткое имя'),
                  const SizedBox(width: 180),
                ]),
              ),
            )
          else
            InkWell(
              key: const Key('people_directory_add_row'),
              onTap: _beginCreate,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Создать новую запись'),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      );
}
