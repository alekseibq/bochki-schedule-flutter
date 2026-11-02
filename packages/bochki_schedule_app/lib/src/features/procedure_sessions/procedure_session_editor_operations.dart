import 'package:flutter/widgets.dart';

import '../../domain/procedure_sessions/procedure_session_raw.dart';
import 'procedure_session_submit_result.dart';
import 'procedure_sessions_view_model.dart';

/// Host-independent commands needed by the assigned-procedure editor.
///
/// A child engine will provide an IPC implementation; the fallback host uses
/// [DirectProcedureSessionEditorOperations]. Keeping this boundary feature
/// specific prevents the editor from knowing which window owns persistence.
abstract interface class ProcedureSessionEditorOperations {
  Future<ProcedureSessionSubmitResult> submit(
    ProcedureSessionRaw value, {
    required bool allowConflicts,
  });

  Future<void> logRenderedSave(int operationId);

  Future<void> openStatistics();

  Future<void> close();
}

/// Direct adapter for the main engine. The existing sessions ViewModel owns
/// the use cases and diagnostic logging, so this adapter preserves its current
/// save semantics while removing that ownership from the editor UI.
final class DirectProcedureSessionEditorOperations
    implements ProcedureSessionEditorOperations {
  const DirectProcedureSessionEditorOperations(
    this._sessions, {
    required Future<void> Function() onOpenStatistics,
    required Future<void> Function() onClose,
  })  : _onOpenStatistics = onOpenStatistics,
        _onClose = onClose;

  final ProcedureSessionsViewModel _sessions;
  final Future<void> Function() _onOpenStatistics;
  final Future<void> Function() _onClose;

  @override
  Future<ProcedureSessionSubmitResult> submit(
    ProcedureSessionRaw value, {
    required bool allowConflicts,
  }) =>
      _sessions.submitProcedureSession(value, allowConflicts: allowConflicts);

  @override
  Future<void> logRenderedSave(int operationId) async {
    await WidgetsBinding.instance.endOfFrame;
    await _sessions.logRenderedSave(operationId);
  }

  @override
  Future<void> openStatistics() => _onOpenStatistics();

  @override
  Future<void> close() => _onClose();
}
