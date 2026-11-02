import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../data/ui_settings/ui_settings_repository.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import '../../domain/humans/list_humans_use_case.dart';
import '../../domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import '../../domain/procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../../domain/procedure_sessions/quick_reassignments_use_case.dart';
import '../../domain/program_settings/get_program_settings_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import 'quick_reassignments_view_model.dart';

abstract interface class QuickReassignmentsOperations {
  Future<QuickReassignmentsSnapshot> load();
  Future<void> mutate(List<ProcedureSessionRaw> replacements);
  Future<List<double>> loadColumnWidths();
  Future<void> saveColumnWidths(List<double> widths);
}

final class UseCaseQuickReassignmentsOperations
    implements QuickReassignmentsOperations {
  const UseCaseQuickReassignmentsOperations({
    required this.listWorkdays,
    required this.listHumans,
    required this.listAssistants,
    required this.listProcedureKinds,
    required this.getProgramSettings,
    required this.listSessions,
    required this.reassignments,
    required this.uiSettings,
  });
  final ListWorkdaysUseCase listWorkdays;
  final ListHumansUseCase listHumans;
  final ListAssistantsUseCase listAssistants;
  final ListProcedureKindsUseCase listProcedureKinds;
  final GetProgramSettingsUseCase getProgramSettings;
  final ListRichProcedureSessionsUseCase listSessions;
  final QuickReassignmentsUseCase reassignments;
  final UiSettingsRepository uiSettings;

  @override
  Future<QuickReassignmentsSnapshot> load() async => QuickReassignmentsSnapshot(
        workdays: await listWorkdays.execute(),
        humans: await listHumans.execute(),
        assistants: await listAssistants.execute(),
        procedureKinds: await listProcedureKinds.execute(),
        programSettings: await getProgramSettings.execute(),
        entries: await listSessions.execute(),
      );
  @override
  Future<void> mutate(List<ProcedureSessionRaw> replacements) =>
      reassignments.execute(replacements);
  @override
  Future<List<double>> loadColumnWidths() async =>
      uiSettings.settings.quickReassignmentsColumnWidths;
  @override
  Future<void> saveColumnWidths(List<double> widths) => uiSettings.update(
      uiSettings.settings.copyWith(quickReassignmentsColumnWidths: widths));
}

/// Callback adapter for isolated ViewModel tests.
final class QuickReassignmentsOperationsAdapter
    implements QuickReassignmentsOperations {
  const QuickReassignmentsOperationsAdapter({
    required Future<QuickReassignmentsSnapshot> Function() load,
    required Future<void> Function(List<ProcedureSessionRaw>) mutate,
    required Future<List<double>> Function() loadColumnWidths,
    required Future<void> Function(List<double>) saveColumnWidths,
  })  : _load = load,
        _mutate = mutate,
        _loadWidths = loadColumnWidths,
        _saveWidths = saveColumnWidths;

  final Future<QuickReassignmentsSnapshot> Function() _load;
  final Future<void> Function(List<ProcedureSessionRaw>) _mutate;
  final Future<List<double>> Function() _loadWidths;
  final Future<void> Function(List<double>) _saveWidths;

  @override
  Future<QuickReassignmentsSnapshot> load() => _load();
  @override
  Future<void> mutate(List<ProcedureSessionRaw> replacements) =>
      _mutate(replacements);
  @override
  Future<List<double>> loadColumnWidths() => _loadWidths();
  @override
  Future<void> saveColumnWidths(List<double> widths) => _saveWidths(widths);
}
