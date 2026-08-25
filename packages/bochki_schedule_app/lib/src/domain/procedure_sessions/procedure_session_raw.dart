import 'procedure_session_time.dart';
import 'procedure_sessions_validation_exception.dart';

final class ProcedureSessionRaw {
  ProcedureSessionRaw({
    required String id,
    required String dayId,
    String? clientId,
    String? participantId,
    required String startTime,
    required String procedureKindId,
    String? companionId,
    String? assistantId,
  })  : id = id.trim(),
        dayId = dayId.trim(),
        clientId = (clientId ?? participantId)?.trim().isEmpty ?? true
            ? null
            : (clientId ?? participantId)!.trim(),
        startTime = startTime.trim(),
        procedureKindId = procedureKindId.trim(),
        companionId = (companionId ?? assistantId)?.trim().isEmpty ?? true
            ? null
            : (companionId ?? assistantId)!.trim() {
    if (this.id.isEmpty) {
      throw const ProcedureSessionsValidationException(
        'Идентификатор назначенной процедуры не должен быть пустым.',
      );
    }
    if (this.dayId.isEmpty) {
      throw const ProcedureSessionsValidationException(
        'Выберите день.',
      );
    }
    if (!ProcedureSessionTime.isValid(this.startTime)) {
      throw const ProcedureSessionsValidationException(
        'Время начала должно быть в формате hh:mm.',
      );
    }
    if (this.procedureKindId.isEmpty) {
      throw const ProcedureSessionsValidationException(
        'Выберите процедуру.',
      );
    }
  }

  final String id;
  final String dayId;
  final String? clientId;
  @Deprecated('Use clientId.')
  String? get participantId => clientId;
  final String startTime;
  final String procedureKindId;
  final String? companionId;
  @Deprecated('Use companionId.')
  String? get assistantId => companionId;

  ProcedureSessionRaw copyWith({
    String? id,
    String? dayId,
    String? clientId,
    String? participantId,
    String? startTime,
    String? procedureKindId,
    String? companionId,
    String? assistantId,
    bool clearClientId = false,
    bool clearCompanionId = false,
    bool clearParticipantId = false,
    bool clearAssistantId = false,
  }) {
    return ProcedureSessionRaw(
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
    );
  }
}
