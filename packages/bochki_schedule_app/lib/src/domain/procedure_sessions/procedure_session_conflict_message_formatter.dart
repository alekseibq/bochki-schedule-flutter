import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';

import 'conflict_resource_type.dart';
import 'schedule_conflict.dart';

final class ProcedureSessionConflictMessageFormatter {
  const ProcedureSessionConflictMessageFormatter();

  String format(
    ScheduleConflict conflict, {
    required Iterable<Human> humans,
    required Iterable<ProcedureKind> procedureKinds,
  }) {
    switch (conflict.resourceType) {
      case ConflictResourceType.human:
        final humanName = _findHumanName(humans, conflict.humanId);
        return 'Участник/ассистент $humanName занят с '
            '${conflict.timeStart} до ${conflict.timeFinish} '
            '(${conflict.capacityRegistered} из ${conflict.capacityAllowed}).';
      case ConflictResourceType.item:
        final procedureName =
            _findProcedureKindName(procedureKinds, conflict.itemId);
        return 'Оборудование процедуры "$procedureName" перегружено с '
            '${conflict.timeStart} до ${conflict.timeFinish} '
            '(${conflict.capacityRegistered} из ${conflict.capacityAllowed}).';
    }
  }

  String _findHumanName(Iterable<Human> humans, String? humanId) {
    if (humanId == null) {
      return 'неизвестный ресурс';
    }
    for (final human in humans) {
      if (human.id == humanId) {
        return human.name;
      }
    }
    return 'id=$humanId';
  }

  String _findProcedureKindName(
    Iterable<ProcedureKind> procedureKinds,
    String? procedureKindId,
  ) {
    if (procedureKindId == null) {
      return 'неизвестная процедура';
    }
    for (final procedureKind in procedureKinds) {
      if (procedureKind.id == procedureKindId) {
        return procedureKind.name;
      }
    }
    return 'id=$procedureKindId';
  }
}
