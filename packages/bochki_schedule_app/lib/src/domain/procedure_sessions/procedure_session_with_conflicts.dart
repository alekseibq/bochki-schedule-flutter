import 'procedure_session_rich.dart';
import 'procedure_session_raw.dart';
import 'schedule_conflict.dart';

final class ProcedureSessionWithConflicts {
  const ProcedureSessionWithConflicts({
    required this.rich,
    required this.conflicts,
  });

  final ProcedureSessionRich rich;
  final List<ScheduleConflict> conflicts;

  String get id => rich.id;
  String get dayId => rich.dayId;
  String get participantId => rich.participantId;
  String get startTime => rich.startTime;
  String? get finishTime => rich.finishTime;
  String get procedureKindId => rich.procedureKindId;
  String? get assistantId => rich.assistantId;
  bool get requiresAssistant => rich.requiresAssistant;
  bool get hasConflicts => conflicts.isNotEmpty;
  ProcedureSessionRaw get raw => rich.raw;
  get day => rich.day;
  get participant => rich.participant;
  get procedureKind => rich.procedureKind;
  get assistant => rich.assistant;
}
