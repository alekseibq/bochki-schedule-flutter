import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';
import '../workdays/workday.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'procedure_session_raw.dart';
import 'procedure_sessions_validation_exception.dart';

abstract final class ProcedureSessionValidator {
  static ProcedureSessionRaw validateForSave(
    ProcedureSessionRaw procedureSession, {
    required Iterable<Workday> existingWorkdays,
    required Iterable<Human> existingHumans,
    required Iterable<ProcedureKind> existingProcedureKinds,
    required Iterable<Assistant> existingAssistants,
    required ProgramSettings programSettings,
  }) {
    final workday = _findWorkday(existingWorkdays, procedureSession.dayId);
    if (workday == null) {
      throw const ProcedureSessionsValidationException('Выберите день.');
    }

    final participantId = procedureSession.participantId;
    final participant = participantId == null
        ? null
        : _findHuman(existingHumans, participantId);
    if (participant == null) {
      throw const ProcedureSessionsValidationException('Выберите участника.');
    }

    final procedureKind = _findProcedureKind(
      existingProcedureKinds,
      procedureSession.procedureKindId,
    );
    if (procedureKind == null) {
      throw const ProcedureSessionsValidationException('Выберите процедуру.');
    }

    if (procedureKind.requiresAssistant) {
      if (procedureSession.assistantId == null) {
        throw const ProcedureSessionsValidationException(
          'Выберите ассистента.',
        );
      }

      final assistant = _findAssistant(
        existingAssistants,
        procedureSession.assistantId!,
      );
      if (assistant == null) {
        throw const ProcedureSessionsValidationException(
          'Выберите ассистента.',
        );
      }
      return procedureSession;
    }

    return procedureSession.copyWith(clearAssistantId: true);
  }

  static void validateId(String procedureSessionId) {
    if (procedureSessionId.trim().isEmpty) {
      throw const ProcedureSessionsValidationException(
        'Идентификатор назначенной процедуры не должен быть пустым.',
      );
    }
  }

  static Workday? _findWorkday(Iterable<Workday> workdays, String id) {
    for (final workday in workdays) {
      if (workday.id == id) {
        return workday;
      }
    }
    return null;
  }

  static Human? _findHuman(Iterable<Human> humans, String id) {
    for (final human in humans) {
      if (human.id == id && human.hasProcedureRole(ProcedureRole.client)) {
        return human;
      }
    }
    return null;
  }

  static ProcedureKind? _findProcedureKind(
    Iterable<ProcedureKind> procedureKinds,
    String id,
  ) {
    for (final procedureKind in procedureKinds) {
      if (procedureKind.id == id) {
        return procedureKind;
      }
    }
    return null;
  }

  static Assistant? _findAssistant(Iterable<Assistant> assistants, String id) {
    for (final assistant in assistants) {
      if (assistant.id == id) {
        return assistant;
      }
    }
    return null;
  }

  static String _formatTime(int totalMinutes) {
    final hour = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
