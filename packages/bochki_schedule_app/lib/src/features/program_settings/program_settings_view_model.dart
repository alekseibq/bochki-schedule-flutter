import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:flutter/foundation.dart';

import '../../domain/program_settings/get_program_settings_use_case.dart';
import '../../domain/program_settings/program_settings_validation_exception.dart';
import '../../domain/program_settings/update_program_settings_use_case.dart';

final class ProgramSettingsViewModel extends ChangeNotifier {
  ProgramSettingsViewModel({
    required GetProgramSettingsUseCase getProgramSettingsUseCase,
    required UpdateProgramSettingsUseCase updateProgramSettingsUseCase,
  })  : _getProgramSettingsUseCase = getProgramSettingsUseCase,
        _updateProgramSettingsUseCase = updateProgramSettingsUseCase;

  final GetProgramSettingsUseCase _getProgramSettingsUseCase;
  final UpdateProgramSettingsUseCase _updateProgramSettingsUseCase;

  ProgramSettings? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  ProgramSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadProgramSettings() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _settings = await _getProgramSettingsUseCase.execute();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить настройки.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<bool> saveProgramSettings(ProgramSettings settings) async {
    _formErrorMessage = null;
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      _settings = await _updateProgramSettingsUseCase.execute(settings);
      return true;
    } on ProgramSettingsValidationException catch (error) {
      _formErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось сохранить настройки.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
