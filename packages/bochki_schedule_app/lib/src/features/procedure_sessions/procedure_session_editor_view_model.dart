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
        _snapshot = null,
        _operations = operations {
    sessions.addListener(notifyListeners);
  }

  ProcedureSessionEditorViewModel.fromSnapshot({
    required ProcedureSessionEditorSnapshot snapshot,
    required ProcedureSessionEditorOperations operations,
  })  : _sessions = null,
        _snapshot = snapshot,
        _operations = operations;

  final ProcedureSessionsViewModel? _sessions;
  final ProcedureSessionEditorSnapshot? _snapshot;
  final ProcedureSessionEditorOperations _operations;

  List<Workday> get workdays => _sessions?.workdays ?? _snapshot!.workdays;
  List<Human> get humans => _sessions?.humans ?? _snapshot!.humans;
  List<ProcedureKind> get procedureKinds =>
      _sessions?.procedureKinds ?? _snapshot!.procedureKinds;
  List<Assistant> get assistants =>
      _sessions?.assistants ?? _snapshot!.assistants;
  List<ProcedureSessionRaw> get procedureSessions =>
      _sessions?.allProcedureSessions ?? _snapshot!.procedureSessions;
  ProgramSettings get programSettings =>
      _sessions?.programSettings ?? _snapshot!.programSettings;
  bool get isSaving => _sessions?.isSaving ?? false;

  ProcedureSessionRaw createDraft() =>
      _sessions?.createDraft() ?? _snapshot!.draft;

  Future<ProcedureSessionSubmitResult> submit(
    ProcedureSessionRaw value, {
    required bool allowConflicts,
  }) =>
      _operations.submit(value, allowConflicts: allowConflicts);

  Future<void> logRenderedSave(int operationId) =>
      _operations.logRenderedSave(operationId);

  @override
  void dispose() {
    _sessions?.removeListener(notifyListeners);
    super.dispose();
  }
}

final class ProcedureSessionEditorSnapshot {
  const ProcedureSessionEditorSnapshot({
    required this.draft,
    required this.workdays,
    required this.humans,
    required this.procedureKinds,
    required this.assistants,
    required this.procedureSessions,
    required this.programSettings,
  });

  final ProcedureSessionRaw draft;
  final List<Workday> workdays;
  final List<Human> humans;
  final List<ProcedureKind> procedureKinds;
  final List<Assistant> assistants;
  final List<ProcedureSessionRaw> procedureSessions;
  final ProgramSettings programSettings;
}
