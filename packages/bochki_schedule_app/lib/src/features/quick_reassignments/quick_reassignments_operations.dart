import '../../domain/procedure_sessions/procedure_session_raw.dart';
import 'quick_reassignments_view_model.dart';

abstract interface class QuickReassignmentsOperations {
  Future<QuickReassignmentsSnapshot> load();
  Future<void> mutate(List<ProcedureSessionRaw> replacements);
  Future<List<double>> loadColumnWidths();
  Future<void> saveColumnWidths(List<double> widths);
}

/// The host supplies direct use-case calls or IPC calls at the boundary.
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
