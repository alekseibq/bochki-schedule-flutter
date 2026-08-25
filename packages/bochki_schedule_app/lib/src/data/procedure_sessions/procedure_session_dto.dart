import '../../domain/procedure_sessions/procedure_session_raw.dart';

final class ProcedureSessionDto {
  const ProcedureSessionDto({
    required this.id,
    required this.dayId,
    required this.clientId,
    required this.startTime,
    required this.procedureKindId,
    required this.companionId,
    required this.deleted,
  });

  factory ProcedureSessionDto.fromJson(Map<String, Object?> json) {
    return ProcedureSessionDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      dayId: (json['dayId'] as num?)?.toInt() ?? 0,
      clientId: ((json['clientId'] ?? json['participantId']) as num?)?.toInt(),
      startTime: (json['startTime'] as String? ?? '').trim(),
      procedureKindId: (json['procedureKindId'] as num?)?.toInt() ?? 0,
      companionId:
          ((json['companionId'] ?? json['assistantId']) as num?)?.toInt(),
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory ProcedureSessionDto.fromDomain(
    ProcedureSessionRaw procedureSession, {
    required bool deleted,
  }) {
    return ProcedureSessionDto(
      id: int.parse(procedureSession.id),
      dayId: int.parse(procedureSession.dayId),
      clientId: procedureSession.clientId == null
          ? null
          : int.parse(procedureSession.clientId!),
      startTime: procedureSession.startTime,
      procedureKindId: int.parse(procedureSession.procedureKindId),
      companionId: procedureSession.companionId == null
          ? null
          : int.parse(procedureSession.companionId!),
      deleted: deleted,
    );
  }

  final int id;
  final int dayId;
  final int? clientId;
  @Deprecated('Use clientId.')
  int? get participantId => clientId;
  final String startTime;
  final int procedureKindId;
  final int? companionId;
  @Deprecated('Use companionId.')
  int? get assistantId => companionId;
  final bool deleted;

  ProcedureSessionRaw toDomain() {
    return ProcedureSessionRaw(
      id: '$id',
      dayId: '$dayId',
      clientId: clientId?.toString(),
      startTime: startTime,
      procedureKindId: '$procedureKindId',
      companionId: companionId?.toString(),
    );
  }

  ProcedureSessionDto copyWith({
    int? id,
    int? dayId,
    int? clientId,
    int? participantId,
    bool clearClientId = false,
    bool clearParticipantId = false,
    String? startTime,
    int? procedureKindId,
    int? companionId,
    int? assistantId,
    bool clearCompanionId = false,
    bool clearAssistantId = false,
    bool? deleted,
  }) {
    return ProcedureSessionDto(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      clientId: clearClientId || clearParticipantId
          ? null
          : clientId ?? participantId ?? this.clientId,
      startTime: startTime ?? this.startTime,
      procedureKindId: procedureKindId ?? this.procedureKindId,
      companionId: clearCompanionId || clearAssistantId
          ? null
          : companionId ?? assistantId ?? this.companionId,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'dayId': dayId,
      'clientId': clientId,
      'startTime': startTime,
      'procedureKindId': procedureKindId,
      'companionId': companionId,
      'deleted': deleted,
    };
  }
}
