import 'conflict_resource_type.dart';
import 'schedule_conflict_type.dart';

final class ScheduleConflict {
  const ScheduleConflict({
    this.type = ScheduleConflictType.resourceOverload,
    this.resourceType,
    required this.workdayId,
    required this.timeStart,
    required this.timeFinish,
    required this.procedureSessionId,
    this.capacityAllowed,
    this.capacityRegistered,
    this.message,
    this.humanId,
    this.itemId,
  });

  final ScheduleConflictType type;
  final ConflictResourceType? resourceType;
  final String workdayId;
  final String timeStart;
  final String timeFinish;
  final String procedureSessionId;
  final String? humanId;
  final String? itemId;
  final int? capacityAllowed;
  final int? capacityRegistered;
  final String? message;

  String get resourceId => humanId ?? itemId ?? '';

  ScheduleConflict copyWith({
    String? timeStart,
    String? timeFinish,
    int? capacityAllowed,
    int? capacityRegistered,
    String? message,
  }) {
    return ScheduleConflict(
      type: type,
      resourceType: resourceType,
      workdayId: workdayId,
      timeStart: timeStart ?? this.timeStart,
      timeFinish: timeFinish ?? this.timeFinish,
      procedureSessionId: procedureSessionId,
      humanId: humanId,
      itemId: itemId,
      capacityAllowed: capacityAllowed ?? this.capacityAllowed,
      capacityRegistered: capacityRegistered ?? this.capacityRegistered,
      message: message ?? this.message,
    );
  }
}
