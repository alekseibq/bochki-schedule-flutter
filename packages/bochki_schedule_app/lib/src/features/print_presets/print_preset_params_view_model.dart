import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/foundation.dart';

import '../../domain/print_preset_params/get_print_preset_params_use_case.dart';
import '../../domain/print_preset_params/update_print_preset_params_use_case.dart';
import '../../domain/print_schedule/open_print_schedule_file_use_case.dart';
import '../../domain/print_schedule/print_schedule_group_by.dart';
import '../../domain/print_schedule/save_print_schedule_file_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';

final class PrintPresetParamsViewModel extends ChangeNotifier {
  PrintPresetParamsViewModel({
    required GetPrintPresetParamsUseCase getPrintPresetParamsUseCase,
    required UpdatePrintPresetParamsUseCase updatePrintPresetParamsUseCase,
    required SavePrintScheduleFileUseCase savePrintScheduleFileUseCase,
    required OpenPrintScheduleFileUseCase openPrintScheduleFileUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
  })  : _getPrintPresetParamsUseCase = getPrintPresetParamsUseCase,
        _updatePrintPresetParamsUseCase = updatePrintPresetParamsUseCase,
        _savePrintScheduleFileUseCase = savePrintScheduleFileUseCase,
        _openPrintScheduleFileUseCase = openPrintScheduleFileUseCase,
        _listWorkdaysUseCase = listWorkdaysUseCase;

  final GetPrintPresetParamsUseCase _getPrintPresetParamsUseCase;
  final UpdatePrintPresetParamsUseCase _updatePrintPresetParamsUseCase;
  final SavePrintScheduleFileUseCase _savePrintScheduleFileUseCase;
  final OpenPrintScheduleFileUseCase _openPrintScheduleFileUseCase;
  final ListWorkdaysUseCase _listWorkdaysUseCase;

  PrintPresetParams _params = PrintPresetParams.defaults;
  List<Workday> _workdays = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _actionErrorMessage;

  PrintPresetParams get params => _params;
  List<Workday> get workdays => _workdays;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get hasAvailableWorkdays => _workdays.isNotEmpty;

  String? get initialWorkdayId {
    if (_workdays.isEmpty) {
      return null;
    }
    for (final workday in _workdays) {
      if (workday.id == _params.workdayId) {
        return workday.id;
      }
    }
    return _workdays.first.id;
  }

  Future<void> load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _params = await _getPrintPresetParamsUseCase.execute();
      _workdays = await _listWorkdaysUseCase.execute();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить настройки распечатки.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    _actionErrorMessage = null;
  }

  Future<bool> save({
    required String workdayId,
    required String textBefore,
    required String textAfter,
  }) async {
    return _runAction(
      action: () => _updatePrintPresetParamsUseCase.execute(
        PrintPresetParams(
          workdayId: workdayId,
          textBefore: textBefore,
          textAfter: textAfter,
        ),
      ),
      errorMessage: 'Не удалось сохранить настройки распечатки.',
    );
  }

  Future<bool> saveFile({
    required String workdayId,
    required String textBefore,
    required String textAfter,
    required PrintScheduleGroupBy groupBy,
  }) async {
    return _runAction(
      action: () => _savePrintScheduleFileUseCase.execute(
        workdayId: workdayId,
        textBefore: textBefore,
        textAfter: textAfter,
        groupBy: groupBy,
      ),
      errorMessage: 'Не удалось сохранить файл распечатки.',
    );
  }

  Future<bool> openFile({
    required String workdayId,
    required String textBefore,
    required String textAfter,
    required PrintScheduleGroupBy groupBy,
  }) async {
    return _runAction(
      action: () => _openPrintScheduleFileUseCase.execute(
        workdayId: workdayId,
        textBefore: textBefore,
        textAfter: textAfter,
        groupBy: groupBy,
      ),
      errorMessage: 'Не удалось открыть файл распечатки.',
    );
  }

  Future<bool> _runAction({
    required Future<Object?> Function() action,
    required String errorMessage,
  }) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await action();
      _params = await _getPrintPresetParamsUseCase.execute();
      return true;
    } catch (_) {
      _actionErrorMessage = errorMessage;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
