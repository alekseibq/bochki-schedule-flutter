import 'package:flutter/foundation.dart';

import '../../domain/workdays/create_workday_use_case.dart';
import '../../domain/workdays/delete_workday_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/update_workday_use_case.dart';
import '../../domain/workdays/workday.dart';
import '../../domain/workdays/workday_defaults.dart';
import '../../domain/workdays/workdays_validation_exception.dart';

final class WorkdaysViewModel extends ChangeNotifier {
  WorkdaysViewModel({
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required CreateWorkdayUseCase createWorkdayUseCase,
    required UpdateWorkdayUseCase updateWorkdayUseCase,
    required DeleteWorkdayUseCase deleteWorkdayUseCase,
    WorkdayDefaults? defaults,
  })  : _listWorkdaysUseCase = listWorkdaysUseCase,
        _createWorkdayUseCase = createWorkdayUseCase,
        _updateWorkdayUseCase = updateWorkdayUseCase,
        _deleteWorkdayUseCase = deleteWorkdayUseCase,
        _defaults = defaults ?? const WorkdayDefaults();

  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final CreateWorkdayUseCase _createWorkdayUseCase;
  final UpdateWorkdayUseCase _updateWorkdayUseCase;
  final DeleteWorkdayUseCase _deleteWorkdayUseCase;
  final WorkdayDefaults _defaults;

  List<Workday> _workdays = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<Workday> get workdays => _workdays;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadWorkdays() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _workdays = await _listWorkdaysUseCase.execute();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить дни.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Workday suggestDraftWorkday() => _defaults.createDraft(_workdays);

  void clearFormError() {
    if (_formErrorMessage == null) {
      return;
    }
    _formErrorMessage = null;
    notifyListeners();
  }

  void clearActionError() {
    _actionErrorMessage = null;
  }

  Future<Workday?> createWorkday({
    required String rawName,
    required String rawCalendarDate,
  }) {
    return _runFormCommand(() async {
      final createdWorkday = await _createWorkdayUseCase.execute(
        _buildWorkday(
          id: 'new',
          rawName: rawName,
          rawCalendarDate: rawCalendarDate,
        ),
      );
      _workdays = _sortEntries([..._workdays, createdWorkday]);
      return createdWorkday;
    });
  }

  Future<Workday?> updateWorkday({
    required String workdayId,
    required String rawName,
    required String rawCalendarDate,
  }) {
    return _runFormCommand(() async {
      final updatedWorkday = await _updateWorkdayUseCase.execute(
        _buildWorkday(
          id: workdayId,
          rawName: rawName,
          rawCalendarDate: rawCalendarDate,
        ),
      );
      _workdays = _sortEntries(
        _workdays
            .map(
              (workday) =>
                  workday.id == updatedWorkday.id ? updatedWorkday : workday,
            )
            .toList(growable: false),
      );
      return updatedWorkday;
    });
  }

  Future<bool> deleteWorkday(String workdayId) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _deleteWorkdayUseCase.execute(workdayId);
      _workdays = _workdays
          .where((workday) => workday.id != workdayId)
          .toList(growable: false);
      return true;
    } on WorkdaysValidationException catch (error) {
      _actionErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось удалить день.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Workday?> _runFormCommand(
    Future<Workday> Function() action,
  ) async {
    _formErrorMessage = null;
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      return await action();
    } on WorkdaysValidationException catch (error) {
      _formErrorMessage = error.message;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Не удалось сохранить изменения.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Workday _buildWorkday({
    required String id,
    required String rawName,
    required String rawCalendarDate,
  }) {
    return Workday(
      id: id,
      name: rawName,
      calendarDate: _parseRequiredDate(rawCalendarDate),
    );
  }

  DateTime _parseRequiredDate(String rawValue) {
    final normalizedValue = rawValue.trim();
    if (normalizedValue.isEmpty) {
      throw const WorkdaysValidationException('Укажите дату.');
    }
    final parts = normalizedValue.split('.');
    if (parts.length != 3) {
      throw const WorkdaysValidationException(
        'Дата должна быть в формате дд.мм.гггг.',
      );
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      throw const WorkdaysValidationException(
        'Дата должна быть в формате дд.мм.гггг.',
      );
    }
    final parsedDate = DateTime(year, month, day);
    if (parsedDate.year != year ||
        parsedDate.month != month ||
        parsedDate.day != day) {
      throw const WorkdaysValidationException(
        'Дата должна быть в формате дд.мм.гггг.',
      );
    }
    return parsedDate;
  }

  List<Workday> _sortEntries(List<Workday> workdays) {
    final sortedWorkdays = [...workdays];
    sortedWorkdays.sort((left, right) {
      final dateComparison = left.calendarDate.compareTo(right.calendarDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return Workday.sortKeyForName(left.name)
          .compareTo(Workday.sortKeyForName(right.name));
    });
    return List<Workday>.unmodifiable(sortedWorkdays);
  }
}
