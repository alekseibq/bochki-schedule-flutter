import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';
import '../workdays/workday.dart';
import 'procedure_session_conflict_calculator.dart';
import 'procedure_session_raw.dart';
import 'procedure_session_rich_factory.dart';
import 'procedure_session_with_conflicts.dart';
import 'schedule_conflict.dart';

/// Builds the schedule as it would look after [candidate] is saved.
///
/// Both the save path and editor previews use this projection so conflict
/// colours always mean the same thing as conflict confirmation on save.
final class ProcedureSessionScheduleProjection {
  const ProcedureSessionScheduleProjection({
    this.conflictCalculator = const ProcedureSessionConflictCalculator(),
    this.richFactory = const ProcedureSessionRichFactory(),
  });

  final ProcedureSessionConflictCalculator conflictCalculator;
  final ProcedureSessionRichFactory richFactory;

  List<ProcedureSessionWithConflicts> project({
    required Iterable<ProcedureSessionRaw> savedSessions,
    required ProcedureSessionRaw candidate,
    required String candidateId,
    required Iterable<Workday> workdays,
    required Iterable<Human> humans,
    required Iterable<ProcedureKind> procedureKinds,
    required Iterable<Assistant> assistants,
    required ProgramSettings programSettings,
  }) {
    final raws = savedSessions.toList(growable: true);
    final replacement = candidate.copyWith(id: candidateId);
    if (candidate.id == 'draft') {
      raws.add(replacement);
    } else {
      final index = raws.indexWhere((entry) => entry.id == candidate.id);
      if (index == -1) {
        raws.add(replacement);
      } else {
        raws[index] = replacement;
      }
    }

    final richSessions = [
      for (final raw in raws)
        richFactory.create(
          raw: raw,
          workdays: workdays,
          humans: humans,
          procedureKinds: procedureKinds,
          assistants: assistants,
        ),
    ]..sort((left, right) {
        final leftDayName = left.day?.name ?? left.dayId;
        final rightDayName = right.day?.name ?? right.dayId;
        final byDay = leftDayName.compareTo(rightDayName);
        if (byDay != 0) return byDay;

        final byStartTime = left.startTime.compareTo(right.startTime);
        if (byStartTime != 0) return byStartTime;

        final leftProcedureName =
            left.procedureKind?.name ?? left.procedureKindId;
        final rightProcedureName =
            right.procedureKind?.name ?? right.procedureKindId;
        final byProcedure = leftProcedureName.compareTo(rightProcedureName);
        if (byProcedure != 0) return byProcedure;

        return left.id.compareTo(right.id);
      });
    final conflicts = conflictCalculator.calculate(
      richSessions,
      programSettings: programSettings,
    );
    final conflictsBySessionId = <String, List<ScheduleConflict>>{};
    for (final conflict in conflicts) {
      conflictsBySessionId
          .putIfAbsent(conflict.procedureSessionId, () => <ScheduleConflict>[])
          .add(conflict);
    }
    return [
      for (final session in richSessions)
        ProcedureSessionWithConflicts(
          rich: session,
          conflicts: List.unmodifiable(
            conflictsBySessionId[session.id] ?? const <ScheduleConflict>[],
          ),
        ),
    ];
  }
}
