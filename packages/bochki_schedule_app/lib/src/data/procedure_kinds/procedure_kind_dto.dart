import '../../domain/procedure_kinds/procedure_kind.dart';

final class ProcedureKindDto {
  const ProcedureKindDto({
    required this.id,
    required this.patternId,
    required this.name,
    required this.capacity,
    required this.participantBusyTime,
    required this.assistantBusyTime,
    required this.resourceBusyTime,
    required this.deleted,
  });

  factory ProcedureKindDto.fromJson(Map<String, Object?> json) {
    return ProcedureKindDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patternId: (json['patternId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      participantBusyTime: (json['participantBusyTime'] as num?)?.toInt() ?? 0,
      assistantBusyTime: (json['assistantBusyTime'] as num?)?.toInt(),
      resourceBusyTime: (json['resourceBusyTime'] as num?)?.toInt(),
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory ProcedureKindDto.fromDomain(
    ProcedureKind procedureKind, {
    required bool deleted,
  }) {
    final persistedProcedureKind = procedureKind.sanitizedForPersistence();
    return ProcedureKindDto(
      id: int.parse(persistedProcedureKind.id),
      patternId: persistedProcedureKind.patternId,
      name: persistedProcedureKind.name,
      capacity: persistedProcedureKind.capacity,
      participantBusyTime: persistedProcedureKind.participantBusyTime,
      assistantBusyTime: persistedProcedureKind.assistantBusyTime,
      resourceBusyTime: persistedProcedureKind.resourceBusyTime,
      deleted: deleted,
    );
  }

  final int id;
  final String patternId;
  final String name;
  final int capacity;
  final int participantBusyTime;
  final int? assistantBusyTime;
  final int? resourceBusyTime;
  final bool deleted;

  ProcedureKind toDomain() {
    return ProcedureKind(
      id: id.toString(),
      patternId: patternId,
      name: name,
      capacity: capacity,
      participantBusyTime: participantBusyTime,
      assistantBusyTime: assistantBusyTime,
      resourceBusyTime: resourceBusyTime,
    ).sanitizedForPersistence();
  }

  ProcedureKindDto copyWith({
    int? id,
    String? patternId,
    String? name,
    int? capacity,
    int? participantBusyTime,
    int? assistantBusyTime,
    bool clearAssistantBusyTime = false,
    int? resourceBusyTime,
    bool clearResourceBusyTime = false,
    bool? deleted,
  }) {
    return ProcedureKindDto(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      participantBusyTime: participantBusyTime ?? this.participantBusyTime,
      assistantBusyTime: clearAssistantBusyTime
          ? null
          : assistantBusyTime ?? this.assistantBusyTime,
      resourceBusyTime: clearResourceBusyTime
          ? null
          : resourceBusyTime ?? this.resourceBusyTime,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'patternId': patternId,
      'name': name,
      'capacity': capacity,
      'participantBusyTime': participantBusyTime,
      'deleted': deleted,
    };
    if (assistantBusyTime != null) {
      json['assistantBusyTime'] = assistantBusyTime;
    }
    if (resourceBusyTime != null) {
      json['resourceBusyTime'] = resourceBusyTime;
    }
    return json;
  }
}
