import 'conflict_resource_type.dart';

final class ProcedureSessionOccupancyRecord {
  const ProcedureSessionOccupancyRecord({
    required this.resourceType,
    required this.resourceId,
    required this.workdayId,
    required this.timeStart,
    required this.timeFinish,
    required this.procedureSessionId,
    required this.capacityAllowed,
  });

  final ConflictResourceType resourceType;
  final String resourceId;
  final String workdayId;
  final String timeStart;
  final String timeFinish;
  final String procedureSessionId;
  final int capacityAllowed;
}
