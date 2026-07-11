import 'package:flutter/foundation.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import '../../domain/humans/human.dart';
import '../../domain/humans/list_humans_use_case.dart';
import '../../domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_sessions/create_procedure_session_use_case.dart';
import '../../domain/procedure_sessions/delete_procedure_session_use_case.dart';
import '../../domain/procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_session_rich.dart';
import '../../domain/procedure_sessions/procedure_session_time.dart';
import '../../domain/procedure_sessions/procedure_sessions_validation_exception.dart';
import '../../domain/procedure_sessions/update_procedure_session_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

enum ProcedureSessionsPartOfDayFilter {
  fullDay('Весь день'),
  beforeLunch('До обеда'),
  afterLunch('После обеда');

  const ProcedureSessionsPartOfDayFilter(this.label);

  final String label;
}

final class ProcedureSessionsViewModel extends ChangeNotifier {
  ProcedureSessionsViewModel({
    required ListRichProcedureSessionsUseCase listRichProcedureSessionsUseCase,
    required CreateProcedureSessionUseCase createProcedureSessionUseCase,
    required UpdateProcedureSessionUseCase updateProcedureSessionUseCase,
    required DeleteProcedureSessionUseCase deleteProcedureSessionUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required ListHumansUseCase listHumansUseCase,
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required ListAssistantsUseCase listAssistantsUseCase,
  })  : _listRichProcedureSessionsUseCase = listRichProcedureSessionsUseCase,
        _createProcedureSessionUseCase = createProcedureSessionUseCase,
        _updateProcedureSessionUseCase = updateProcedureSessionUseCase,
        _deleteProcedureSessionUseCase = deleteProcedureSessionUseCase,
        _listWorkdaysUseCase = listWorkdaysUseCase,
        _listHumansUseCase = listHumansUseCase,
        _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _listAssistantsUseCase = listAssistantsUseCase;

  final ListRichProcedureSessionsUseCase _listRichProcedureSessionsUseCase;
  final CreateProcedureSessionUseCase _createProcedureSessionUseCase;
  final UpdateProcedureSessionUseCase _updateProcedureSessionUseCase;
  final DeleteProcedureSessionUseCase _deleteProcedureSessionUseCase;
  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final ListHumansUseCase _listHumansUseCase;
  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final ListAssistantsUseCase _listAssistantsUseCase;

  List<ProcedureSessionRich> _allEntries = const [];
  List<Workday> _workdays = const [];
  List<Human> _participants = const [];
  List<ProcedureKind> _procedureKinds = const [];
  List<Assistant> _assistants = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _actionErrorMessage;
  String? _selectedEntryId;
  String? _selectedDayId;
  ProcedureSessionsPartOfDayFilter _partOfDayFilter =
      ProcedureSessionsPartOfDayFilter.fullDay;
  String? _selectedProcedureKindId;
  String? _selectedParticipantId;
  bool _showConflictsOnly = false;

  List<ProcedureSessionRich> get entries => _applyFilters(_allEntries);
  List<Workday> get workdays => _workdays;
  List<Human> get participants => _participants;
  List<ProcedureKind> get procedureKinds => _procedureKinds;
  List<Assistant> get assistants => _assistants;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String? get selectedEntryId => _selectedEntryId;
  String? get selectedDayId => _selectedDayId;
  ProcedureSessionsPartOfDayFilter get partOfDayFilter => _partOfDayFilter;
  String? get selectedProcedureKindId => _selectedProcedureKindId;
  String? get selectedParticipantId => _selectedParticipantId;
  bool get showConflictsOnly => _showConflictsOnly;

  Future<void> load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _workdays = await _listWorkdaysUseCase.execute();
      _participants = (await _listHumansUseCase.execute())
          .where((human) => human.isParticipant)
          .toList(growable: false);
      _procedureKinds = await _listProcedureKindsUseCase.execute();
      _assistants = await _listAssistantsUseCase.execute();
      _allEntries = await _listRichProcedureSessionsUseCase.execute();
      _syncSelection();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить назначенные процедуры.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    _actionErrorMessage = null;
  }

  void selectEntry(String? entryId) {
    if (_selectedEntryId == entryId) {
      return;
    }
    _selectedEntryId = entryId;
    notifyListeners();
  }

  void setDayFilter(String? dayId) {
    _selectedDayId = dayId;
    _syncSelection();
    notifyListeners();
  }

  void setPartOfDayFilter(ProcedureSessionsPartOfDayFilter filter) {
    if (_partOfDayFilter == filter) {
      return;
    }
    _partOfDayFilter = filter;
    _syncSelection();
    notifyListeners();
  }

  void setProcedureKindFilter(String? procedureKindId) {
    _selectedProcedureKindId = procedureKindId;
    _syncSelection();
    notifyListeners();
  }

  void setParticipantFilter(String? participantId) {
    _selectedParticipantId = participantId;
    _syncSelection();
    notifyListeners();
  }

  void setShowConflictsOnly(bool value) {
    if (_showConflictsOnly == value) {
      return;
    }
    _showConflictsOnly = value;
    notifyListeners();
  }

  Future<bool> createProcedureSession(
      ProcedureSessionRaw procedureSession) async {
    return _runMutation(() async {
      await _createProcedureSessionUseCase.execute(procedureSession);
      await _reloadEntries();
    });
  }

  Future<bool> updateProcedureSession(
      ProcedureSessionRaw procedureSession) async {
    return _runMutation(() async {
      await _updateProcedureSessionUseCase.execute(procedureSession);
      await _reloadEntries();
      _selectedEntryId = procedureSession.id;
    });
  }

  Future<bool> deleteProcedureSession(String procedureSessionId) async {
    return _runMutation(() async {
      await _deleteProcedureSessionUseCase.execute(procedureSessionId);
      await _reloadEntries();
      if (_selectedEntryId == procedureSessionId) {
        _selectedEntryId = null;
      }
    });
  }

  ProcedureSessionRaw createDraft() {
    final firstProcedureKind =
        _procedureKinds.isEmpty ? null : _procedureKinds.first;
    return ProcedureSessionRaw(
      id: 'draft',
      dayId: _workdays.isEmpty ? 'missing-day' : _workdays.first.id,
      participantId: _participants.isEmpty
          ? 'missing-participant'
          : _participants.first.id,
      startTime: '08:00',
      procedureKindId: firstProcedureKind == null
          ? 'missing-procedure'
          : firstProcedureKind.id,
      assistantId: firstProcedureKind != null &&
              firstProcedureKind.isCurated &&
              _assistants.isNotEmpty
          ? _assistants.first.id
          : null,
    );
  }

  Future<void> _reloadEntries() async {
    _allEntries = await _listRichProcedureSessionsUseCase.execute();
    _workdays = await _listWorkdaysUseCase.execute();
    _participants = (await _listHumansUseCase.execute())
        .where((human) => human.isParticipant)
        .toList(growable: false);
    _procedureKinds = await _listProcedureKindsUseCase.execute();
    _assistants = await _listAssistantsUseCase.execute();
    _syncSelection();
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await action();
      return true;
    } on ProcedureSessionsValidationException catch (error) {
      _actionErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось сохранить назначенную процедуру.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<ProcedureSessionRich> _applyFilters(List<ProcedureSessionRich> entries) {
    return entries.where((entry) {
      if (_selectedDayId != null && entry.dayId != _selectedDayId) {
        return false;
      }
      if (_selectedProcedureKindId != null &&
          entry.procedureKindId != _selectedProcedureKindId) {
        return false;
      }
      if (_selectedParticipantId != null &&
          entry.participantId != _selectedParticipantId) {
        return false;
      }
      final startMinutes = ProcedureSessionTime.toMinutes(entry.startTime);
      switch (_partOfDayFilter) {
        case ProcedureSessionsPartOfDayFilter.fullDay:
          break;
        case ProcedureSessionsPartOfDayFilter.beforeLunch:
          if (startMinutes >= 13 * 60) {
            return false;
          }
          break;
        case ProcedureSessionsPartOfDayFilter.afterLunch:
          if (startMinutes < 13 * 60) {
            return false;
          }
          break;
      }
      return true;
    }).toList(growable: false);
  }

  void _syncSelection() {
    final visibleIds = entries.map((entry) => entry.id).toSet();
    if (_selectedEntryId != null && !visibleIds.contains(_selectedEntryId)) {
      _selectedEntryId = entries.isEmpty ? null : entries.first.id;
    } else if (_selectedEntryId == null && entries.isNotEmpty) {
      _selectedEntryId = entries.first.id;
    }
  }
}
