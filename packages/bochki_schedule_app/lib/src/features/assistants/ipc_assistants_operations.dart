import '../../domain/assistants/assistant.dart';
import 'assistants_operations.dart';

typedef AssistantsIpcInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

/// Child-engine adapter for the assistants feature.
final class IpcAssistantsOperations implements AssistantsOperations {
  const IpcAssistantsOperations(this._invoke);
  final AssistantsIpcInvoker _invoke;

  @override
  Future<List<Assistant>> list() async {
    final snapshot = Map<String, dynamic>.from(
      await _invoke('directorySnapshot', 'assistants') as Map,
    );
    return (snapshot['entries'] as List)
        .map((value) => _fromMap(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  @override
  Future<Assistant> create(String name) async {
    await _mutate('create', entry: {'name': name});
    return Assistant(id: 'created', name: name, shortName: '');
  }

  @override
  Future<Assistant> update(String id, String name) async {
    await _mutate('update', id: id, entry: {'name': name});
    return Assistant(id: id, name: name, shortName: '');
  }

  @override
  Future<int> countReferences(String id) async =>
      await _invoke(
              'directoryReferences', {'directory': 'assistants', 'id': id})
          as int? ??
      0;

  @override
  Future<void> delete(String id) => _mutate('delete', id: id);

  Future<void> _mutate(String action,
      {String? id, Map<String, dynamic>? entry}) async {
    final result = Map<String, dynamic>.from(await _invoke('directoryMutate', {
      'directory': 'assistants',
      'action': action,
      if (id != null) 'id': id,
      'entry': entry ?? const <String, dynamic>{},
    }) as Map);
    if (result['ok'] != true) {
      throw StateError(
          result['error'] as String? ?? 'Не удалось сохранить изменения.');
    }
  }

  Assistant _fromMap(Map<String, dynamic> map) => Assistant(
        id: map['id'] as String,
        name: map['name'] as String,
        shortName: map['shortName'] as String? ?? '',
      );
}
