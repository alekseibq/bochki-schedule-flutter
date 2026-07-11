import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';
import '../workdays/workday.dart';

import 'procedure_session_raw.dart';
import 'procedure_session_rich.dart';

final class ProcedureSessionRichFactory {
  const ProcedureSessionRichFactory();

  ProcedureSessionRich create({
    required ProcedureSessionRaw raw,
    required Iterable<Workday> workdays,
    required Iterable<Human> humans,
    required Iterable<ProcedureKind> procedureKinds,
    required Iterable<Assistant> assistants,
  }) {
    return ProcedureSessionRich(
      raw: raw,
      day: _findById(workdays, raw.dayId),
      participant: humans.where((human) => human.isParticipant).fold<Human?>(
            null,
            (current, human) =>
                current ?? (human.id == raw.participantId ? human : null),
          ),
      procedureKind: _findById(procedureKinds, raw.procedureKindId),
      assistant: raw.assistantId == null
          ? null
          : _findById(assistants, raw.assistantId!),
    );
  }

  T? _findById<T>(Iterable<T> entries, String id) {
    for (final entry in entries) {
      final candidateId = switch (entry) {
        Workday(:final id) => id,
        Human(:final id) => id,
        ProcedureKind(:final id) => id,
        Assistant(:final id) => id,
        _ => null,
      };
      if (candidateId == id) {
        return entry;
      }
    }
    return null;
  }
}
