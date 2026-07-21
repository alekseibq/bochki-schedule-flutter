import 'package:flutter/foundation.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import '../../domain/humans/human.dart';
import '../../domain/humans/list_humans_use_case.dart';
import '../../domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/program_settings/get_program_settings_use_case.dart';
import '../../domain/procedure_sessions/create_procedure_session_use_case.dart';
import '../../domain/procedure_sessions/delete_procedure_session_use_case.dart';
import '../../domain/procedure_sessions/list_procedure_sessions_with_conflicts_use_case.dart';
import '../../domain/procedure_sessions/procedure_session_conflict_calculator.dart';
import '../../domain/procedure_sessions/procedure_session_conflict_message_formatter.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/procedure_session_rich_factory.dart';
import '../../domain/procedure_sessions/procedure_session_time.dart';
import '../../domain/procedure_sessions/procedure_session_with_conflicts.dart';
import '../../domain/procedure_sessions/procedure_sessions_validation_exception.dart';
import '../../domain/procedure_sessions/schedule_conflict.dart';
import '../../domain/procedure_sessions/update_procedure_session_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

import 'procedure_session_submit_result.dart';

enum ProcedureSessionsPartOfDayFilter {
  fullDay('Весь день'),
  beforeLunch('До обеда'),
  afterLunch('После обеда');

  const ProcedureSessionsPartOfDayFilter(this.label);

  final String label;
}

final class ProcedureSessionsViewModel extends ChangeNotifier {
  static const String draftConflictSessionId = '__draft_procedure_session__';

  ProcedureSessionsViewModel({
    required ListProcedureSessionsWithConflictsUseCase
        listProcedureSessionsWithConflictsUseCase,
    required CreateProcedureSessionUseCase createProcedureSessionUseCase,
    required UpdateProcedureSessionUseCase updateProcedureSessionUseCase,
    required DeleteProcedureSessionUseCase deleteProcedureSessionUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required ListHumansUseCase listHumansUseCase,
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required ListAssistantsUseCase listAssistantsUseCase,
    required GetProgramSettingsUseCase getProgramSettingsUseCase,
    ProcedureSessionConflictCalculator? conflictCalculator,
    ProcedureSessionConflictMessageFormatter? conflictMessageFormatter,
    ProcedureSessionRichFactory? richFactory,
  })  : _listProcedureSessionsWithConflictsUseCase =
            listProcedureSessionsWithConflictsUseCase,
        _createProcedureSessionUseCase = createProcedureSessionUseCase,
        _updateProcedureSessionUseCase = updateProcedureSessionUseCase,
        _deleteProcedureSessionUseCase = deleteProcedureSessionUseCase,
        _listWorkdaysUseCase = listWorkdaysUseCase,
        _listHumansUseCase = listHumansUseCase,
        _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _listAssistantsUseCase = listAssistantsUseCase,
        _getProgramSettingsUseCase = getProgramSettingsUseCase,
        _conflictCalculator =
            conflictCalculator ?? const ProcedureSessionConflictCalculator(),
        _conflictMessageFormatter = conflictMessageFormatter ??
            const ProcedureSessionConflictMessageFormatter(),
        _richFactory = richFactory ?? const ProcedureSessionRichFactory();

  final ListProcedureSessionsWithConflictsUseCase
      _listProcedureSessionsWithConflictsUseCase;
  final CreateProcedureSessionUseCase _createProcedureSessionUseCase;
  final UpdateProcedureSessionUseCase _updateProcedureSessionUseCase;
  final DeleteProcedureSessionUseCase _deleteProcedureSessionUseCase;
  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final ListHumansUseCase _listHumansUseCase;
  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final ListAssistantsUseCase _listAssistantsUseCase;
  final GetProgramSettingsUseCase _getProgramSettingsUseCase;
  final ProcedureSessionConflictCalculator _conflictCalculator;
  final ProcedureSessionConflictMessageFormatter _conflictMessageFormatter;
  final ProcedureSessionRichFactory _richFactory;

  List<ProcedureSessionWithConflicts> _allEntries = const [];
  List<Workday> _workdays = const [];
  List<Human> _participants = const [];
  List<Human> _humans = const [];
  List<ProcedureKind> _procedureKinds = const [];
  List<Assistant> _assistants = const [];
  ProgramSettings _programSettings = ProgramSettings.defaults;
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

  List<ProcedureSessionWithConflicts> get entries => _applyFilters(_allEntries);
  List<Workday> get workdays => _workdays;
  List<Human> get participants => _participants;
  List<ProcedureKind> get procedureKinds => _procedureKinds;
  List<Assistant> get assistants => _assistants;
  ProgramSettings get programSettings => _programSettings;
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

  String participantSummaryTooltip({
    required String humanId,
    required String humanName,
  }) {
    final countsByDayId = <String, int>{};
    for (final entry in _allEntries) {
      if (entry.participantId != humanId) {
        continue;
      }
      countsByDayId.update(entry.dayId, (count) => count + 1,
          ifAbsent: () => 1);
    }

    if (countsByDayId.isEmpty) {
      return '$humanName\nНет процедур в роли участника';
    }

    return [
      humanName,
      for (final workday in _workdays)
        if (countsByDayId[workday.id] case final count?)
          '${workday.name}: $count',
    ].join('\n');
  }

  Future<void> load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _programSettings = await _getProgramSettingsUseCase.execute();
      _workdays = await _listWorkdaysUseCase.execute();
      _humans = await _listHumansUseCase.execute();
      _participants =
          _humans.where((human) => human.isParticipant).toList(growable: false);
      _procedureKinds = await _listProcedureKindsUseCase.execute();
      _assistants = await _listAssistantsUseCase.execute();
      _allEntries = await _listProcedureSessionsWithConflictsUseCase.execute();
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
    final result = await submitProcedureSession(
      procedureSession,
      allowConflicts: true,
    );
    return result.didSave;
  }

  Future<bool> updateProcedureSession(
      ProcedureSessionRaw procedureSession) async {
    final result = await submitProcedureSession(
      procedureSession,
      allowConflicts: true,
    );
    return result.didSave;
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
      startTime:
          '${_programSettings.minimumHour.toString().padLeft(2, '0')}:00',
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
    _programSettings = await _getProgramSettingsUseCase.execute();
    _allEntries = await _listProcedureSessionsWithConflictsUseCase.execute();
    _workdays = await _listWorkdaysUseCase.execute();
    _humans = await _listHumansUseCase.execute();
    _participants =
        _humans.where((human) => human.isParticipant).toList(growable: false);
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

  Future<ProcedureSessionSubmitResult> submitProcedureSession(
    ProcedureSessionRaw procedureSession, {
    required bool allowConflicts,
  }) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final candidateId = procedureSession.id == 'draft'
          ? draftConflictSessionId
          : procedureSession.id;
      final projectedEntries =
          _buildProjectedEntries(procedureSession, candidateId: candidateId);
      final projectedConflicts = projectedEntries
          .where((entry) => entry.id == candidateId)
          .expand((entry) => entry.conflicts)
          .toList(growable: false);
      if (projectedConflicts.isNotEmpty && !allowConflicts) {
        return ProcedureSessionSubmitResult.conflicts(
          _formatConflictMessages(projectedConflicts),
        );
      }

      if (procedureSession.id == 'draft') {
        final created = await _createProcedureSessionUseCase.execute(
          procedureSession,
        );
        await _reloadEntries();
        _selectedEntryId = created.id;
      } else {
        await _updateProcedureSessionUseCase.execute(procedureSession);
        await _reloadEntries();
        _selectedEntryId = procedureSession.id;
      }
      return const ProcedureSessionSubmitResult.saved();
    } on ProcedureSessionsValidationException catch (error) {
      _actionErrorMessage = error.message;
      return ProcedureSessionSubmitResult.error(error.message);
    } catch (_) {
      _actionErrorMessage = 'Не удалось сохранить назначенную процедуру.';
      return const ProcedureSessionSubmitResult.error(
        'Не удалось сохранить назначенную процедуру.',
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<ProcedureSessionWithConflicts> _applyFilters(
    List<ProcedureSessionWithConflicts> entries,
  ) {
    return entries.where((entry) {
      if (_showConflictsOnly && !entry.hasConflicts) {
        return false;
      }
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
      final lunchStartMinutes = _programSettings.lunchStart.hour * 60 +
          _programSettings.lunchStart.minute;
      switch (_partOfDayFilter) {
        case ProcedureSessionsPartOfDayFilter.fullDay:
          break;
        case ProcedureSessionsPartOfDayFilter.beforeLunch:
          if (startMinutes >= lunchStartMinutes) {
            return false;
          }
          break;
        case ProcedureSessionsPartOfDayFilter.afterLunch:
          if (startMinutes < lunchStartMinutes) {
            return false;
          }
          break;
      }
      return true;
    }).toList(growable: false);
  }

  List<ProcedureSessionWithConflicts> _buildProjectedEntries(
    ProcedureSessionRaw candidate, {
    required String candidateId,
  }) {
    final raws = _allEntries.map((entry) => entry.raw).toList(growable: true);
    if (candidate.id == 'draft') {
      raws.add(candidate.copyWith(id: candidateId));
    } else {
      final index = raws.indexWhere((entry) => entry.id == candidate.id);
      final replacement = candidate.copyWith(id: candidateId);
      if (index == -1) {
        raws.add(replacement);
      } else {
        raws[index] = replacement;
      }
    }

    final richSessions = [
      for (final raw in raws)
        _richFactory.create(
          raw: raw,
          workdays: _workdays,
          humans: _humans,
          procedureKinds: _procedureKinds,
          assistants: _assistants,
        ),
    ]..sort((left, right) {
        final leftDayName = left.day?.name ?? left.dayId;
        final rightDayName = right.day?.name ?? right.dayId;
        final byDay = leftDayName.compareTo(rightDayName);
        if (byDay != 0) {
          return byDay;
        }

        final byStartTime = left.startTime.compareTo(right.startTime);
        if (byStartTime != 0) {
          return byStartTime;
        }

        final leftProcedureName =
            left.procedureKind?.name ?? left.procedureKindId;
        final rightProcedureName =
            right.procedureKind?.name ?? right.procedureKindId;
        final byProcedure = leftProcedureName.compareTo(rightProcedureName);
        if (byProcedure != 0) {
          return byProcedure;
        }

        return left.id.compareTo(right.id);
      });

    final conflicts = _conflictCalculator.calculate(richSessions);
    final conflictsBySessionId = <String, List<ScheduleConflict>>{};
    for (final conflict in conflicts) {
      conflictsBySessionId
          .putIfAbsent(conflict.procedureSessionId, () => <ScheduleConflict>[])
          .add(conflict);
    }

    return [
      for (final session in richSessions)
        ProcedureSessionWithConflicts(
          rich: session,
          conflicts: List.unmodifiable(
            conflictsBySessionId[session.id] ?? const <ScheduleConflict>[],
          ),
        ),
    ];
  }

  List<String> _formatConflictMessages(List<ScheduleConflict> conflicts) {
    return [
      for (final conflict in conflicts)
        _conflictMessageFormatter.format(
          conflict,
          humans: _humans,
          procedureKinds: _procedureKinds,
        ),
    ];
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
