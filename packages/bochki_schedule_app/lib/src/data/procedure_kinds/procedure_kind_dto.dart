import '../../domain/procedure_kinds/procedure_kind.dart';

final class ProcedureKindDto {
  const ProcedureKindDto({
    required this.id,
    required this.patternId,
    required this.name,
    required this.shortName,
    required this.capacity,
    required this.participantBusyTime,
    required this.assistantBusyTime,
    required this.resourceBusyTime,
    required this.useCapacityRestriction,
    required this.useForPairCount,
    required this.hasCapacityRestrictionFlag,
    required this.hasPairCountFlag,
    required this.deleted,
  });

  factory ProcedureKindDto.fromJson(Map<String, Object?> json) {
    return ProcedureKindDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patternId: (json['patternId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      shortName: (json['shortName'] as String?) ?? '',
      capacity: (json['capacity'] as num?)?.toInt(),
      participantBusyTime:
          ((json['clientBusyTime'] ?? json['participantBusyTime']) as num?)
                  ?.toInt() ??
              0,
      assistantBusyTime:
          ((json['companionBusyTime'] ?? json['assistantBusyTime']) as num?)
              ?.toInt(),
      resourceBusyTime: (json['resourceBusyTime'] as num?)?.toInt(),
      useCapacityRestriction: json['useCapacityRestriction'] as bool? ??
          ((json['capacity'] as num?)?.toInt() ?? 0) > 0,
      useForPairCount: json['useForPairCount'] as bool? ?? true,
      hasCapacityRestrictionFlag: json.containsKey('useCapacityRestriction'),
      hasPairCountFlag: json.containsKey('useForPairCount'),
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
      shortName: persistedProcedureKind.shortName,
      capacity: persistedProcedureKind.capacity,
      participantBusyTime: persistedProcedureKind.participantBusyTime,
      assistantBusyTime: persistedProcedureKind.assistantBusyTime,
      resourceBusyTime: persistedProcedureKind.resourceBusyTime,
      useCapacityRestriction: persistedProcedureKind.useCapacityRestriction,
      useForPairCount: persistedProcedureKind.useForPairCount,
      hasCapacityRestrictionFlag: true,
      hasPairCountFlag: true,
      deleted: deleted,
    );
  }

  final int id;
  final String patternId;
  final String name;
  final String shortName;
  final int? capacity;
  final int participantBusyTime;
  final int? assistantBusyTime;
  final int? resourceBusyTime;
  final bool useCapacityRestriction;
  final bool useForPairCount;
  final bool hasCapacityRestrictionFlag;
  final bool hasPairCountFlag;
  final bool deleted;

  ProcedureKind toDomain() {
    return ProcedureKind(
      id: id.toString(),
      patternId: patternId,
      name: name,
      shortName: shortName,
      capacity: capacity,
      participantBusyTime: participantBusyTime,
      assistantBusyTime: assistantBusyTime,
      resourceBusyTime: resourceBusyTime,
      useCapacityRestriction: useCapacityRestriction,
      useForPairCount: useForPairCount,
    ).sanitizedForPersistence();
  }

  ProcedureKindDto copyWith({
    int? id,
    String? patternId,
    String? name,
    String? shortName,
    int? capacity,
    bool? useCapacityRestriction,
    bool? useForPairCount,
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
      shortName: shortName ?? this.shortName,
      capacity: capacity ?? this.capacity,
      useCapacityRestriction:
          useCapacityRestriction ?? this.useCapacityRestriction,
      useForPairCount: useForPairCount ?? this.useForPairCount,
      hasCapacityRestrictionFlag: hasCapacityRestrictionFlag,
      hasPairCountFlag: hasPairCountFlag,
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
      'shortName': shortName,
      'clientBusyTime': participantBusyTime,
      'deleted': deleted,
      'useCapacityRestriction': useCapacityRestriction,
      'useForPairCount': useForPairCount,
    };
    if (capacity != null) json['capacity'] = capacity;
    if (assistantBusyTime != null) {
      json['companionBusyTime'] = assistantBusyTime;
    }
    if (resourceBusyTime != null) {
      json['resourceBusyTime'] = resourceBusyTime;
    }
    return json;
  }
}
