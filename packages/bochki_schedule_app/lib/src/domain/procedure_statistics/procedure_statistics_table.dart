import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';

enum ProcedureStatisticsPeopleFilter { all, participants, assistants }

enum ProcedureStatisticsMode { participation, assisting }

final class ProcedureStatisticsTable {
  const ProcedureStatisticsTable(
      {required this.people, required this.kinds, required this.counts});
  final List<Human> people;
  final List<ProcedureKind> kinds;
  final Map<String, int> counts;
  int count(Human human, ProcedureKind kind) =>
      counts['${human.id}/${kind.id}'] ?? 0;
}
