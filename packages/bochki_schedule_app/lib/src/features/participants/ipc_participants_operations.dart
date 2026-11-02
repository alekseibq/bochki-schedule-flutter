import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_validation_exception.dart';
import 'participants_operations.dart';

typedef ParticipantsIpcInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

/// Child-engine adapter for the participants feature.
final class IpcParticipantsOperations implements ParticipantsOperations {
  const IpcParticipantsOperations(this._invoke);

  final ParticipantsIpcInvoker _invoke;

  @override
  Future<List<Participant>> list() async {
    final snapshot = Map<String, dynamic>.from(
      await _invoke('directorySnapshot', 'participants') as Map,
    );
    return (snapshot['entries'] as List)
        .map((value) => _fromMap(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  @override
  Future<Participant> create(String name) async {
    return _fromMap(await _mutate('create', entry: {'name': name}));
  }

  @override
  Future<Participant> update(String id, String name) async {
    return _fromMap(await _mutate('update', id: id, entry: {'name': name}));
  }

  @override
  Future<int> countReferences(String id) async =>
      await _invoke(
              'directoryReferences', {'directory': 'participants', 'id': id})
          as int? ??
      0;

  @override
  Future<void> delete(String id) async {
    await _mutate('delete', id: id);
  }

  Future<Map<String, dynamic>> _mutate(
    String action, {
    String? id,
    Map<String, dynamic>? entry,
  }) async {
    final result = Map<String, dynamic>.from(
      await _invoke('directoryMutate', {
        'directory': 'participants',
        'action': action,
        if (id != null) 'id': id,
        'entry': entry ?? const <String, dynamic>{},
      }) as Map,
    );
    if (result['ok'] != true) {
      if (result['validation'] == true) {
        throw ParticipantsValidationException(result['error'] as String);
      }
      throw StateError(
          result['error'] as String? ?? 'Не удалось сохранить изменения.');
    }
    return Map<String, dynamic>.from(result['entry'] as Map? ?? const {});
  }

  Participant _fromMap(Map<String, dynamic> map) => Participant(
        id: map['id'] as String,
        name: map['name'] as String,
      );
}
