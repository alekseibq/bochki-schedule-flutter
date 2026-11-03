import '../humans/human.dart';
import 'procedure_session_raw.dart';

/// Identity of one logical grouped procedure.
///
/// Grouped assignments represent one procedure only when their day, start
/// time, procedure kind and leader all match.
final class GroupedProcedureKey {
  const GroupedProcedureKey({
    required this.dayId,
    required this.startTime,
    required this.procedureKindId,
    required this.assistantId,
  });

  final String dayId;
  final String startTime;
  final String procedureKindId;
  final String? assistantId;

  bool matches(ProcedureSessionRaw session) =>
      session.dayId == dayId &&
      session.startTime == startTime &&
      session.procedureKindId == procedureKindId &&
      session.assistantId == assistantId;
}

final class GroupedProcedureParticipant {
  const GroupedProcedureParticipant({required this.id, required this.name});

  final String id;
  final String name;
}

List<GroupedProcedureParticipant> groupedProcedureParticipants({
  required GroupedProcedureKey key,
  required Iterable<ProcedureSessionRaw> savedSessions,
  required Iterable<Human> humans,
}) {
  final namesById = {for (final human in humans) human.id: human.name};
  final participants = <GroupedProcedureParticipant>[];
  for (final session in savedSessions) {
    final participantId = session.participantId;
    if (!key.matches(session) || participantId == null) continue;
    participants.add(GroupedProcedureParticipant(
      id: participantId,
      name: namesById[participantId] ?? participantId,
    ));
  }
  participants.sort((left, right) => left.name.compareTo(right.name));
  return List.unmodifiable(participants);
}
