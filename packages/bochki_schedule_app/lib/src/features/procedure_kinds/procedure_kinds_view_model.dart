import 'package:flutter/foundation.dart';

import '../../domain/procedure_kinds/create_procedure_kind_use_case.dart';
import '../../domain/procedure_kinds/delete_procedure_kind_use_case.dart';
import '../../domain/procedure_kinds/list_procedure_kinds_use_case.dart';
import '../../domain/procedure_kinds/procedure_kind.dart';
import '../../domain/procedure_kinds/procedure_kinds_validation_exception.dart';
import '../../domain/procedure_kinds/update_procedure_kind_use_case.dart';

final class ProcedureKindsViewModel extends ChangeNotifier {
  ProcedureKindsViewModel({
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required CreateProcedureKindUseCase createProcedureKindUseCase,
    required UpdateProcedureKindUseCase updateProcedureKindUseCase,
    required DeleteProcedureKindUseCase deleteProcedureKindUseCase,
  })  : _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _createProcedureKindUseCase = createProcedureKindUseCase,
        _updateProcedureKindUseCase = updateProcedureKindUseCase,
        _deleteProcedureKindUseCase = deleteProcedureKindUseCase;

  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final CreateProcedureKindUseCase _createProcedureKindUseCase;
  final UpdateProcedureKindUseCase _updateProcedureKindUseCase;
  final DeleteProcedureKindUseCase _deleteProcedureKindUseCase;

  List<ProcedureKind> _procedureKinds = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<ProcedureKind> get procedureKinds => _procedureKinds;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadProcedureKinds() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _procedureKinds = await _listProcedureKindsUseCase.execute();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить процедуры.';
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

  Future<ProcedureKind?> createProcedureKind({
    required String patternId,
    required String rawName,
    required String rawCapacity,
    required String rawParticipantBusyTime,
    String? rawAssistantBusyTime,
    String? rawResourceBusyTime,
  }) {
    return _runFormCommand(() async {
      final createdProcedureKind = await _createProcedureKindUseCase.execute(
        _buildProcedureKind(
          id: 'new',
          patternId: patternId,
          rawName: rawName,
          rawCapacity: rawCapacity,
          rawParticipantBusyTime: rawParticipantBusyTime,
          rawAssistantBusyTime: rawAssistantBusyTime,
          rawResourceBusyTime: rawResourceBusyTime,
        ),
      );
      _procedureKinds = _sortEntries([
        ..._procedureKinds,
        createdProcedureKind,
      ]);
      return createdProcedureKind;
    });
  }

  Future<ProcedureKind?> updateProcedureKind({
    required String procedureKindId,
    required String patternId,
    required String rawName,
    required String rawCapacity,
    required String rawParticipantBusyTime,
    String? rawAssistantBusyTime,
    String? rawResourceBusyTime,
  }) {
    return _runFormCommand(() async {
      final updatedProcedureKind = await _updateProcedureKindUseCase.execute(
        _buildProcedureKind(
          id: procedureKindId,
          patternId: patternId,
          rawName: rawName,
          rawCapacity: rawCapacity,
          rawParticipantBusyTime: rawParticipantBusyTime,
          rawAssistantBusyTime: rawAssistantBusyTime,
          rawResourceBusyTime: rawResourceBusyTime,
        ),
      );
      _procedureKinds = _sortEntries(
        _procedureKinds
            .map(
              (procedureKind) => procedureKind.id == updatedProcedureKind.id
                  ? updatedProcedureKind
                  : procedureKind,
            )
            .toList(growable: false),
      );
      return updatedProcedureKind;
    });
  }

  Future<bool> deleteProcedureKind(String procedureKindId) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _deleteProcedureKindUseCase.execute(procedureKindId);
      _procedureKinds = _procedureKinds
          .where((procedureKind) => procedureKind.id != procedureKindId)
          .toList(growable: false);
      return true;
    } on ProcedureKindsValidationException catch (error) {
      _actionErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось удалить процедуру.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ProcedureKind?> _runFormCommand(
    Future<ProcedureKind> Function() action,
  ) async {
    _formErrorMessage = null;
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      return await action();
    } on ProcedureKindsValidationException catch (error) {
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

  ProcedureKind _buildProcedureKind({
    required String id,
    required String patternId,
    required String rawName,
    required String rawCapacity,
    required String rawParticipantBusyTime,
    required String? rawAssistantBusyTime,
    required String? rawResourceBusyTime,
  }) {
    return ProcedureKind(
      id: id,
      patternId: patternId,
      name: rawName,
      capacity: _parseRequiredInt(
        rawCapacity,
        emptyMessage: 'Укажите емкость.',
      ),
      participantBusyTime: _parseRequiredInt(
        rawParticipantBusyTime,
        emptyMessage: 'Укажите время участника.',
      ),
      assistantBusyTime: _parseOptionalInt(rawAssistantBusyTime),
      resourceBusyTime: _parseOptionalInt(rawResourceBusyTime),
    );
  }

  int _parseRequiredInt(String rawValue, {required String emptyMessage}) {
    final normalizedValue = rawValue.trim();
    if (normalizedValue.isEmpty) {
      throw ProcedureKindsValidationException(emptyMessage);
    }
    final parsedValue = int.tryParse(normalizedValue);
    if (parsedValue == null) {
      throw ProcedureKindsValidationException(emptyMessage);
    }
    return parsedValue;
  }

  int? _parseOptionalInt(String? rawValue) {
    if (rawValue == null) {
      return null;
    }
    final normalizedValue = rawValue.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }
    return int.tryParse(normalizedValue);
  }

  List<ProcedureKind> _sortEntries(List<ProcedureKind> procedureKinds) {
    final sortedProcedureKinds = [...procedureKinds];
    sortedProcedureKinds.sort(
      (left, right) => ProcedureKind.sortKeyForName(left.name)
          .compareTo(ProcedureKind.sortKeyForName(right.name)),
    );
    return List<ProcedureKind>.unmodifiable(sortedProcedureKinds);
  }
}
