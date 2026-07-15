import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';
import '../workdays/workday.dart';

import 'procedure_session_raw.dart';
import 'procedure_session_time.dart';

final class ProcedureSessionRich {
  const ProcedureSessionRich({
    required this.raw,
    required this.day,
    required this.participant,
    required this.procedureKind,
    this.assistant,
  });

  final ProcedureSessionRaw raw;
  final Workday? day;
  final Human? participant;
  final ProcedureKind? procedureKind;
  final Assistant? assistant;

  String get id => raw.id;
  String get dayId => raw.dayId;
  String get participantId => raw.participantId;
  String get startTime => raw.startTime;
  String get procedureKindId => raw.procedureKindId;
  String? get assistantId => raw.assistantId;

  bool get requiresAssistant => procedureKind?.isCurated ?? false;

  String? get finishTime {
    final kind = procedureKind;
    if (kind == null) {
      return null;
    }

    return ProcedureSessionTime.fromMinutes(
      ProcedureSessionTime.toMinutes(startTime) + kind.participantBusyTime,
    );
  }

  String? get assistantFinishTime {
    final kind = procedureKind;
    final assistantBusyTime = kind?.assistantBusyTime;
    if (assistantBusyTime == null) {
      return null;
    }

    return ProcedureSessionTime.fromMinutes(
      ProcedureSessionTime.toMinutes(startTime) + assistantBusyTime,
    );
  }

  String? get resourceFinishTime {
    final kind = procedureKind;
    final resourceBusyTime = kind?.resourceBusyTime;
    if (resourceBusyTime == null) {
      return null;
    }

    return ProcedureSessionTime.fromMinutes(
      ProcedureSessionTime.toMinutes(startTime) + resourceBusyTime,
    );
  }
}
