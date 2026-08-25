import '../../domain/procedure_sessions/procedure_session_raw.dart';

final class ProcedureSessionDto {
  const ProcedureSessionDto({
    required this.id,
    required this.dayId,
    required this.participantId,
    required this.startTime,
    required this.procedureKindId,
    required this.assistantId,
    required this.deleted,
  });

  factory ProcedureSessionDto.fromJson(Map<String, Object?> json) {
    return ProcedureSessionDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      dayId: (json['dayId'] as num?)?.toInt() ?? 0,
      participantId: (json['participantId'] as num?)?.toInt(),
      startTime: (json['startTime'] as String? ?? '').trim(),
      procedureKindId: (json['procedureKindId'] as num?)?.toInt() ?? 0,
      assistantId: (json['assistantId'] as num?)?.toInt(),
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
      participantId: procedureSession.participantId == null
          ? null
          : int.parse(procedureSession.participantId!),
      startTime: procedureSession.startTime,
      procedureKindId: int.parse(procedureSession.procedureKindId),
      assistantId: procedureSession.assistantId == null
          ? null
          : int.parse(procedureSession.assistantId!),
      deleted: deleted,
    );
  }

  final int id;
  final int dayId;
  final int? participantId;
  final String startTime;
  final int procedureKindId;
  final int? assistantId;
  final bool deleted;

  ProcedureSessionRaw toDomain() {
    return ProcedureSessionRaw(
      id: '$id',
      dayId: '$dayId',
      participantId: participantId?.toString(),
      startTime: startTime,
      procedureKindId: '$procedureKindId',
      assistantId: assistantId?.toString(),
    );
  }

  ProcedureSessionDto copyWith({
    int? id,
    int? dayId,
    int? participantId,
    bool clearParticipantId = false,
    String? startTime,
    int? procedureKindId,
    int? assistantId,
    bool clearAssistantId = false,
    bool? deleted,
  }) {
    return ProcedureSessionDto(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      participantId:
          clearParticipantId ? null : participantId ?? this.participantId,
      startTime: startTime ?? this.startTime,
      procedureKindId: procedureKindId ?? this.procedureKindId,
      assistantId: clearAssistantId ? null : assistantId ?? this.assistantId,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'dayId': dayId,
      'participantId': participantId,
      'startTime': startTime,
      'procedureKindId': procedureKindId,
      'assistantId': assistantId,
      'deleted': deleted,
    };
  }
}
