import '../../domain/procedure_kinds/procedure_kind.dart';
import 'procedure_kinds_operations.dart';

typedef ProcedureKindsIpcInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

final class IpcProcedureKindsOperations implements ProcedureKindsOperations {
  const IpcProcedureKindsOperations(this._invoke);

  final ProcedureKindsIpcInvoker _invoke;

  @override
  Future<List<ProcedureKind>> list() async {
    final snapshot = Map<String, dynamic>.from(
      await _invoke('directorySnapshot', 'procedureKinds') as Map,
    );
    return (snapshot['entries'] as List)
        .map((entry) =>
            procedureKindFromMap(Map<String, dynamic>.from(entry as Map)))
        .toList(growable: false);
  }

  @override
  Future<ProcedureKind> create(ProcedureKind procedureKind) async {
    await _mutate('create', entry: procedureKindToMap(procedureKind));
    return procedureKind;
  }

  @override
  Future<ProcedureKind> update(ProcedureKind procedureKind) async {
    await _mutate(
      'update',
      id: procedureKind.id,
      entry: procedureKindToMap(procedureKind),
    );
    return procedureKind;
  }

  @override
  Future<int> countReferences(String procedureKindId) async =>
      await _invoke('directoryReferences', {
        'directory': 'procedureKinds',
        'id': procedureKindId,
      }) as int? ??
      0;

  @override
  Future<void> delete(String procedureKindId) => _mutate(
        'delete',
        id: procedureKindId,
      );

  Future<void> _mutate(
    String action, {
    String? id,
    Map<String, dynamic>? entry,
  }) async {
    final result = Map<String, dynamic>.from(
      await _invoke('directoryMutate', {
        'directory': 'procedureKinds',
        'action': action,
        if (id != null) 'id': id,
        'entry': entry ?? const <String, dynamic>{},
      }) as Map,
    );
    if (result['ok'] != true) {
      throw StateError(
          result['error'] as String? ?? 'Не удалось сохранить изменения.');
    }
  }
}

Map<String, dynamic> procedureKindToMap(ProcedureKind procedureKind) => {
      'patternId': procedureKind.patternId,
      'name': procedureKind.name,
      'shortName': procedureKind.shortName,
      'capacity': procedureKind.capacity,
      'participantBusyTime': procedureKind.participantBusyTime,
      'assistantBusyTime': procedureKind.assistantBusyTime,
      'resourceBusyTime': procedureKind.resourceBusyTime,
    };

ProcedureKind procedureKindFromMap(Map<String, dynamic> map) => ProcedureKind(
      id: map['id'] as String,
      patternId: map['patternId'] as String,
      name: map['name'] as String,
      shortName: map['shortName'] as String,
      capacity: map['capacity'] as int,
      participantBusyTime: map['participantBusyTime'] as int,
      assistantBusyTime: map['assistantBusyTime'] as int?,
      resourceBusyTime: map['resourceBusyTime'] as int?,
    );
