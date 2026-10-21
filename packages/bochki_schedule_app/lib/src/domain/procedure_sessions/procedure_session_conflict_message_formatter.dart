import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';

import 'conflict_resource_type.dart';
import 'schedule_conflict.dart';
import 'schedule_conflict_type.dart';

final class ProcedureSessionConflictMessageFormatter {
  const ProcedureSessionConflictMessageFormatter();

  String format(
    ScheduleConflict conflict, {
    required Iterable<Human> humans,
    required Iterable<ProcedureKind> procedureKinds,
    Iterable<Assistant> assistants = const [],
  }) {
    if (conflict.type != ScheduleConflictType.resourceOverload) {
      return conflict.message ?? 'Нарушены границы времени программы.';
    }
    switch (conflict.resourceType!) {
      case ConflictResourceType.human:
        final humanName = _findHumanName(humans, assistants, conflict.humanId);
        return 'Участник/сопровождающий $humanName занят с '
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

  String _findHumanName(
    Iterable<Human> humans,
    Iterable<Assistant> assistants,
    String? humanId,
  ) {
    if (humanId == null) {
      return 'неизвестный ресурс';
    }
    for (final human in humans) {
      if (human.id == humanId) {
        return human.name;
      }
    }
    for (final assistant in assistants) {
      if (assistant.id == humanId) {
        return assistant.name;
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
