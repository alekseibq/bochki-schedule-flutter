import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_session_rich_factory.dart';
import '../../domain/workdays/workday.dart';
import '../procedure_sessions/ipc_procedure_session_editor_operations.dart';
import 'quick_reassignments_operations.dart';
import 'quick_reassignments_view_model.dart';

final class IpcQuickReassignmentsOperations
    implements QuickReassignmentsOperations {
  IpcQuickReassignmentsOperations(this._invoke);
  final Future<Object?> Function(String method, Object? arguments) _invoke;
  List<double> _widths = const [];

  @override
  Future<QuickReassignmentsSnapshot> load() async {
    final value = Map<String, dynamic>.from(
        await _invoke('quickReassignmentsSnapshot', null) as Map);
    List<Map<String, dynamic>> maps(String key) =>
        (value[key] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    final workdays = maps('workdays')
        .map((m) => Workday(
            id: m['id'] as String,
            name: m['name'] as String,
            calendarDate: DateTime.parse(m['date'] as String)))
        .toList();
    final humans = maps('humans')
        .map((m) => Human(
            id: m['id'] as String,
            name: m['name'] as String,
            shortName: m['shortName'] as String,
            isParticipant: m['isParticipant'] as bool,
            isAssistant: m['isAssistant'] as bool))
        .toList();
    final assistants = maps('assistants')
        .map((m) => Assistant(
            id: m['id'] as String,
            name: m['name'] as String,
            shortName: m['shortName'] as String))
        .toList();
    final kinds = maps('procedureKinds')
        .map((m) => ProcedureKind(
            id: m['id'] as String,
            patternId: m['patternId'] as String,
            name: m['name'] as String,
            shortName: m['shortName'] as String,
            capacity: m['capacity'] as int?,
            useCapacityRestriction:
                m['useCapacityRestriction'] as bool? ?? true,
            participantBusyTime: m['participantBusyTime'] as int,
            assistantBusyTime: m['assistantBusyTime'] as int?,
            resourceBusyTime: m['resourceBusyTime'] as int?))
        .toList();
    final settings = Map<String, dynamic>.from(value['settings'] as Map);
    const factory = ProcedureSessionRichFactory();
    final entries = maps('procedureSessions')
        .map((m) => factory.create(
              raw: ProcedureSessionRaw(
                  id: m['id'] as String,
                  dayId: m['dayId'] as String,
                  participantId: m['participantId'] as String?,
                  startTime: m['startTime'] as String,
                  procedureKindId: m['procedureKindId'] as String,
                  assistantId: m['assistantId'] as String?),
              workdays: workdays,
              humans: humans,
              procedureKinds: kinds,
              assistants: assistants,
            ))
        .toList();
    _widths = (value['quickReassignmentsColumnWidths'] as List? ?? const [])
        .whereType<num>()
        .map((v) => v.toDouble())
        .toList();
    return QuickReassignmentsSnapshot(
        workdays: workdays,
        humans: humans,
        assistants: assistants,
        procedureKinds: kinds,
        programSettings: ProgramSettings(
            minimumTime: ProgramSettingsTime.fromJson(settings['minimumTime']),
            maximumTime: ProgramSettingsTime.fromJson(settings['maximumTime'])),
        entries: entries);
  }

  @override
  Future<void> mutate(List<ProcedureSessionRaw> replacements) async {
    await _invoke('quickReassignmentsMutate',
        replacements.map(procedureSessionToIpcMap).toList());
  }

  @override
  Future<List<double>> loadColumnWidths() async => List.of(_widths);

  @override
  Future<void> saveColumnWidths(List<double> widths) async {
    await _invoke('updateQuickReassignmentsColumnWidths', widths);
    _widths = List.of(widths);
  }
}
