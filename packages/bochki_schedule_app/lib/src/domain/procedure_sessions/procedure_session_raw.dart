import 'procedure_session_time.dart';
import 'procedure_sessions_validation_exception.dart';

final class ProcedureSessionRaw {
  ProcedureSessionRaw({
    required String id,
    required String dayId,
    required String participantId,
    required String startTime,
    required String procedureKindId,
    String? assistantId,
  })  : id = id.trim(),
        dayId = dayId.trim(),
        participantId = participantId.trim(),
        startTime = startTime.trim(),
        procedureKindId = procedureKindId.trim(),
        assistantId =
            assistantId?.trim().isEmpty ?? true ? null : assistantId!.trim() {
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
    if (this.participantId.isEmpty) {
      throw const ProcedureSessionsValidationException(
        'Выберите участника.',
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
  final String participantId;
  final String startTime;
  final String procedureKindId;
  final String? assistantId;

  ProcedureSessionRaw copyWith({
    String? id,
    String? dayId,
    String? participantId,
    String? startTime,
    String? procedureKindId,
    String? assistantId,
    bool clearAssistantId = false,
  }) {
    return ProcedureSessionRaw(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      participantId: participantId ?? this.participantId,
      startTime: startTime ?? this.startTime,
      procedureKindId: procedureKindId ?? this.procedureKindId,
      assistantId: clearAssistantId ? null : assistantId ?? this.assistantId,
    );
  }
}
