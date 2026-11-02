import 'package:flutter/foundation.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/humans/human.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/workdays/workday.dart';
import 'procedure_session_editor_operations.dart';
import 'procedure_session_submit_result.dart';
import 'procedure_sessions_view_model.dart';

/// State exposed to a single assigned-procedure editor host.
///
/// The list ViewModel remains the owner of the main workspace data for now;
/// this adapter gives the editor a dedicated lifecycle and commands boundary.
final class ProcedureSessionEditorViewModel extends ChangeNotifier {
  ProcedureSessionEditorViewModel({
    required ProcedureSessionsViewModel sessions,
    required ProcedureSessionEditorOperations operations,
  })  : _sessions = sessions,
        _operations = operations {
    _sessions.addListener(notifyListeners);
  }

  final ProcedureSessionsViewModel _sessions;
  final ProcedureSessionEditorOperations _operations;

  List<Workday> get workdays => _sessions.workdays;
  List<Human> get humans => _sessions.humans;
  List<ProcedureKind> get procedureKinds => _sessions.procedureKinds;
  List<Assistant> get assistants => _sessions.assistants;
  List<ProcedureSessionRaw> get procedureSessions =>
      _sessions.allProcedureSessions;
  ProgramSettings get programSettings => _sessions.programSettings;
  bool get isSaving => _sessions.isSaving;

  ProcedureSessionRaw createDraft() => _sessions.createDraft();

  Future<ProcedureSessionSubmitResult> submit(
    ProcedureSessionRaw value, {
    required bool allowConflicts,
  }) =>
      _operations.submit(value, allowConflicts: allowConflicts);

  Future<void> logRenderedSave(int operationId) =>
      _operations.logRenderedSave(operationId);

  @override
  void dispose() {
    _sessions.removeListener(notifyListeners);
    super.dispose();
  }
}
