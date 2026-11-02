import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/workdays/workday.dart';
import 'procedure_session_editor_operations.dart';
import 'procedure_session_editor_view_model.dart';
import 'procedure_session_submit_result.dart';

typedef ProcedureSessionEditorIpcInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

final class IpcProcedureSessionEditorOperations
    implements ProcedureSessionEditorOperations {
  const IpcProcedureSessionEditorOperations(
    this._invoke, {
    required Future<void> Function() onOpenStatistics,
    required Future<void> Function() onClose,
  })  : _onOpenStatistics = onOpenStatistics,
        _onClose = onClose;
  final ProcedureSessionEditorIpcInvoker _invoke;
  final Future<void> Function() _onOpenStatistics;
  final Future<void> Function() _onClose;

  Future<ProcedureSessionEditorSnapshot> loadSnapshot() async {
    final value = Map<String, dynamic>.from(
        await _invoke('procedureSessionSnapshot', null) as Map);
    List<Map<String, dynamic>> maps(String key) =>
        (value[key] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    ProcedureSessionRaw session(Map<String, dynamic> m) => ProcedureSessionRaw(
          id: m['id'] as String,
          dayId: m['dayId'] as String,
          participantId: m['participantId'] as String?,
          startTime: m['startTime'] as String,
          procedureKindId: m['procedureKindId'] as String,
          assistantId: m['assistantId'] as String?,
        );
    final settings = Map<String, dynamic>.from(value['settings'] as Map);
    return ProcedureSessionEditorSnapshot(
      draft: session(Map<String, dynamic>.from(value['draft'] as Map)),
      workdays: maps('workdays')
          .map((m) => Workday(
              id: m['id'] as String,
              name: m['name'] as String,
              calendarDate: DateTime.parse(m['date'] as String)))
          .toList(),
      humans: maps('humans')
          .map((m) => Human(
              id: m['id'] as String,
              name: m['name'] as String,
              shortName: m['shortName'] as String,
              isParticipant: m['isParticipant'] as bool,
              isAssistant: m['isAssistant'] as bool))
          .toList(),
      assistants: maps('assistants')
          .map((m) => Assistant(
              id: m['id'] as String,
              name: m['name'] as String,
              shortName: m['shortName'] as String))
          .toList(),
      procedureKinds: maps('procedureKinds')
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
          .toList(),
      procedureSessions: maps('procedureSessions').map(session).toList(),
      programSettings: ProgramSettings(
          minimumTime: ProgramSettingsTime.fromJson(settings['minimumTime']),
          maximumTime: ProgramSettingsTime.fromJson(settings['maximumTime'])),
    );
  }

  @override
  Future<ProcedureSessionSubmitResult> submit(
    ProcedureSessionRaw value, {
    required bool allowConflicts,
  }) async {
    final response = await _invoke('submitProcedureSession', {
      'session': procedureSessionToIpcMap(value),
      'allowConflicts': allowConflicts,
    });
    if (response == null) {
      return const ProcedureSessionSubmitResult.error(
        'Не удалось сохранить назначенную процедуру.',
      );
    }
    final result = Map<String, dynamic>.from(response as Map);
    if (result['didSave'] as bool) {
      return ProcedureSessionSubmitResult.saved(result['operationId'] as int);
    }
    final conflicts = (result['conflictMessages'] as List).cast<String>();
    return conflicts.isNotEmpty
        ? ProcedureSessionSubmitResult.conflicts(conflicts)
        : ProcedureSessionSubmitResult.error(result['errorMessage'] as String);
  }

  @override
  Future<void> logRenderedSave(int operationId) =>
      _invoke('procedureSessionRendered', operationId);

  @override
  Future<void> openStatistics() => _onOpenStatistics();

  @override
  Future<void> close() => _onClose();
}

Map<String, dynamic> procedureSessionToIpcMap(ProcedureSessionRaw value) => {
      'id': value.id,
      'dayId': value.dayId,
      'participantId': value.participantId,
      'startTime': value.startTime,
      'procedureKindId': value.procedureKindId,
      'assistantId': value.assistantId,
    };
