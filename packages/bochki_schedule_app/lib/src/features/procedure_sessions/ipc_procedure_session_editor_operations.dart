import '../../domain/procedure_sessions/procedure_session_raw.dart';
import 'procedure_session_editor_operations.dart';
import 'procedure_session_submit_result.dart';

typedef ProcedureSessionEditorIpcInvoker = Future<Object?> Function(
  String method,
  Object? arguments,
);

final class IpcProcedureSessionEditorOperations
    implements ProcedureSessionEditorOperations {
  const IpcProcedureSessionEditorOperations(this._invoke);
  final ProcedureSessionEditorIpcInvoker _invoke;

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
}

Map<String, dynamic> procedureSessionToIpcMap(ProcedureSessionRaw value) => {
      'id': value.id,
      'dayId': value.dayId,
      'participantId': value.participantId,
      'startTime': value.startTime,
      'procedureKindId': value.procedureKindId,
      'assistantId': value.assistantId,
    };
