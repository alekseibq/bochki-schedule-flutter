import 'conflict_resource_type.dart';

final class ScheduleConflict {
  const ScheduleConflict({
    required this.resourceType,
    required this.workdayId,
    required this.timeStart,
    required this.timeFinish,
    required this.procedureSessionId,
    required this.capacityAllowed,
    required this.capacityRegistered,
    this.humanId,
    this.itemId,
  });

  final ConflictResourceType resourceType;
  final String workdayId;
  final String timeStart;
  final String timeFinish;
  final String procedureSessionId;
  final String? humanId;
  final String? itemId;
  final int capacityAllowed;
  final int capacityRegistered;

  String get resourceId => humanId ?? itemId ?? '';

  ScheduleConflict copyWith({
    String? timeStart,
    String? timeFinish,
    int? capacityAllowed,
    int? capacityRegistered,
  }) {
    return ScheduleConflict(
      resourceType: resourceType,
      workdayId: workdayId,
      timeStart: timeStart ?? this.timeStart,
      timeFinish: timeFinish ?? this.timeFinish,
      procedureSessionId: procedureSessionId,
      humanId: humanId,
      itemId: itemId,
      capacityAllowed: capacityAllowed ?? this.capacityAllowed,
      capacityRegistered: capacityRegistered ?? this.capacityRegistered,
    );
  }
}
