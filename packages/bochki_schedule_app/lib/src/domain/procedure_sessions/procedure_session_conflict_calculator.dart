import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'conflict_resource_type.dart';
import 'procedure_session_occupancy_record.dart';
import 'procedure_session_rich.dart';
import 'procedure_session_time.dart';
import 'schedule_conflict.dart';
import 'schedule_conflict_type.dart';

final class ProcedureSessionConflictCalculator {
  const ProcedureSessionConflictCalculator();

  List<ScheduleConflict> calculate(
    Iterable<ProcedureSessionRich> sessions, {
    required ProgramSettings programSettings,
  }) {
    final records = <ProcedureSessionOccupancyRecord>[
      for (final session in sessions) ..._buildRecords(session),
    ];
    final grouped = <String, List<ProcedureSessionOccupancyRecord>>{};
    for (final record in records) {
      final key =
          '${record.resourceType.name}|${record.resourceId}|${record.workdayId}';
      grouped
          .putIfAbsent(key, () => <ProcedureSessionOccupancyRecord>[])
          .add(record);
    }

    final conflicts = <ScheduleConflict>[];
    for (final group in grouped.values) {
      conflicts.addAll(_calculateGroup(group));
    }
    for (final session in sessions) {
      conflicts
          .addAll(_calculateTimeBoundaryConflicts(session, programSettings));
    }
    return _mergeAdjacentConflicts(conflicts);
  }

  List<ScheduleConflict> _calculateTimeBoundaryConflicts(
    ProcedureSessionRich session,
    ProgramSettings settings,
  ) {
    final start = ProcedureSessionTime.toMinutes(session.startTime);
    final minimum =
        settings.minimumTime.hour * 60 + settings.minimumTime.minute;
    final maximum =
        settings.maximumTime.hour * 60 + settings.maximumTime.minute;
    final conflicts = <ScheduleConflict>[];
    if (start < minimum) {
      conflicts.add(ScheduleConflict(
        type: ScheduleConflictType.timeBoundary,
        workdayId: session.dayId,
        timeStart: session.startTime,
        timeFinish: _formatAbsoluteTime(minimum),
        procedureSessionId: session.id,
        message:
            'Процедура начинается раньше минимального времени ${_formatAbsoluteTime(minimum)}.',
      ));
    }

    final kind = session.procedureKind;
    if (kind == null) return conflicts;
    final ends = <String>[];
    final endMinutes = <int>[];
    void addEnd(String label, int? duration) {
      if (duration == null) return;
      final end = start + duration;
      endMinutes.add(end);
      if (end > maximum) ends.add('$label до ${_formatAbsoluteTime(end)}');
    }

    addEnd('участник', kind.participantBusyTime);
    if (session.assistantId != null)
      addEnd('ассистент', kind.assistantBusyTime);
    addEnd('ресурс', kind.resourceBusyTime);
    if (ends.isNotEmpty) {
      conflicts.add(ScheduleConflict(
        type: ScheduleConflictType.timeBoundary,
        workdayId: session.dayId,
        timeStart: session.startTime,
        timeFinish:
            _formatAbsoluteTime(endMinutes.reduce((a, b) => a > b ? a : b)),
        procedureSessionId: session.id,
        message:
            'Процедура выходит за максимальное время ${_formatAbsoluteTime(maximum)}: ${ends.join(', ')}.',
      ));
    }
    return conflicts;
  }

  String _formatAbsoluteTime(int minutes) {
    final dayOffset = minutes ~/ (24 * 60);
    final time = ProcedureSessionTime.fromMinutes(minutes);
    return dayOffset > 0 ? '$time следующего дня' : time;
  }

  List<ProcedureSessionOccupancyRecord> _buildRecords(
    ProcedureSessionRich session,
  ) {
    final procedureKind = session.procedureKind;
    if (procedureKind == null) {
      return const [];
    }

    final records = <ProcedureSessionOccupancyRecord>[
      ProcedureSessionOccupancyRecord(
        resourceType: ConflictResourceType.human,
        resourceId: session.participantId,
        workdayId: session.dayId,
        timeStart: session.startTime,
        timeFinish: session.finishTime ?? session.startTime,
        procedureSessionId: session.id,
        capacityAllowed: 1,
      ),
      ProcedureSessionOccupancyRecord(
        resourceType: ConflictResourceType.item,
        resourceId: session.procedureKindId,
        workdayId: session.dayId,
        timeStart: session.startTime,
        timeFinish: session.resourceFinishTime ?? session.startTime,
        procedureSessionId: session.id,
        capacityAllowed: procedureKind.capacity,
      ),
    ];

    final assistantFinishTime = session.assistantFinishTime;
    final assistantId = session.assistantId;
    if (assistantFinishTime != null && assistantId != null) {
      records.add(
        ProcedureSessionOccupancyRecord(
          resourceType: ConflictResourceType.human,
          resourceId: assistantId,
          workdayId: session.dayId,
          timeStart: session.startTime,
          timeFinish: assistantFinishTime,
          procedureSessionId: session.id,
          capacityAllowed: 1,
        ),
      );
    }

    return records;
  }

  List<ScheduleConflict> _calculateGroup(
    List<ProcedureSessionOccupancyRecord> records,
  ) {
    final boundaries = <int>{};
    for (final record in records) {
      boundaries.add(ProcedureSessionTime.toMinutes(record.timeStart));
      boundaries.add(ProcedureSessionTime.toMinutes(record.timeFinish));
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final conflicts = <ScheduleConflict>[];
    for (var index = 0; index < sortedBoundaries.length - 1; index++) {
      final startMinutes = sortedBoundaries[index];
      final finishMinutes = sortedBoundaries[index + 1];
      if (startMinutes == finishMinutes) {
        continue;
      }

      final activeRecords = records.where((record) {
        final recordStart = ProcedureSessionTime.toMinutes(record.timeStart);
        final recordFinish = ProcedureSessionTime.toMinutes(record.timeFinish);
        return recordStart < finishMinutes && recordFinish > startMinutes;
      }).toList(growable: false);
      if (activeRecords.isEmpty) {
        continue;
      }

      final capacityAllowed = activeRecords.first.capacityAllowed;
      final capacityRegistered = activeRecords.length;
      if (capacityRegistered <= capacityAllowed) {
        continue;
      }

      for (final record in activeRecords) {
        conflicts.add(
          ScheduleConflict(
            resourceType: record.resourceType,
            workdayId: record.workdayId,
            timeStart: ProcedureSessionTime.fromMinutes(startMinutes),
            timeFinish: ProcedureSessionTime.fromMinutes(finishMinutes),
            procedureSessionId: record.procedureSessionId,
            humanId: record.resourceType == ConflictResourceType.human
                ? record.resourceId
                : null,
            itemId: record.resourceType == ConflictResourceType.item
                ? record.resourceId
                : null,
            capacityAllowed: capacityAllowed,
            capacityRegistered: capacityRegistered,
          ),
        );
      }
    }

    return conflicts;
  }

  List<ScheduleConflict> _mergeAdjacentConflicts(
    List<ScheduleConflict> conflicts,
  ) {
    final sortedConflicts = [...conflicts]..sort((left, right) {
        final bySession =
            left.procedureSessionId.compareTo(right.procedureSessionId);
        if (bySession != 0) {
          return bySession;
        }
        final byResourceType = (left.resourceType?.name ?? '')
            .compareTo(right.resourceType?.name ?? '');
        if (byResourceType != 0) {
          return byResourceType;
        }
        final byResourceId = left.resourceId.compareTo(right.resourceId);
        if (byResourceId != 0) {
          return byResourceId;
        }
        final byWorkday = left.workdayId.compareTo(right.workdayId);
        if (byWorkday != 0) {
          return byWorkday;
        }
        final byStart = left.timeStart.compareTo(right.timeStart);
        if (byStart != 0) {
          return byStart;
        }
        return left.timeFinish.compareTo(right.timeFinish);
      });

    final merged = <ScheduleConflict>[];
    for (final conflict in sortedConflicts) {
      if (merged.isEmpty) {
        merged.add(conflict);
        continue;
      }

      final previous = merged.last;
      final canMerge = previous.type == ScheduleConflictType.resourceOverload &&
          conflict.type == ScheduleConflictType.resourceOverload &&
          previous.procedureSessionId == conflict.procedureSessionId &&
          previous.resourceType == conflict.resourceType &&
          previous.resourceId == conflict.resourceId &&
          previous.workdayId == conflict.workdayId &&
          previous.capacityAllowed == conflict.capacityAllowed &&
          previous.capacityRegistered == conflict.capacityRegistered &&
          previous.timeFinish == conflict.timeStart;
      if (!canMerge) {
        merged.add(conflict);
        continue;
      }

      merged[merged.length - 1] = previous.copyWith(
        timeFinish: conflict.timeFinish,
      );
    }

    return merged;
  }
}
