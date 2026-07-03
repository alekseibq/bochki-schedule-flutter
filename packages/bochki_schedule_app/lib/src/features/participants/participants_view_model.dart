import 'package:flutter/foundation.dart';

import '../../domain/participants/create_participant_use_case.dart';
import '../../domain/participants/delete_participant_use_case.dart';
import '../../domain/participants/list_participants_use_case.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_validation_exception.dart';
import '../../domain/participants/update_participant_use_case.dart';

final class ParticipantsViewModel extends ChangeNotifier {
  ParticipantsViewModel({
    required ListParticipantsUseCase listParticipantsUseCase,
    required CreateParticipantUseCase createParticipantUseCase,
    required UpdateParticipantUseCase updateParticipantUseCase,
    required DeleteParticipantUseCase deleteParticipantUseCase,
  })  : _listParticipantsUseCase = listParticipantsUseCase,
        _createParticipantUseCase = createParticipantUseCase,
        _updateParticipantUseCase = updateParticipantUseCase,
        _deleteParticipantUseCase = deleteParticipantUseCase;

  final ListParticipantsUseCase _listParticipantsUseCase;
  final CreateParticipantUseCase _createParticipantUseCase;
  final UpdateParticipantUseCase _updateParticipantUseCase;
  final DeleteParticipantUseCase _deleteParticipantUseCase;

  List<Participant> _participants = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<Participant> get participants => _participants;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadParticipants() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _participants = await _listParticipantsUseCase.execute();
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить участников.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createParticipant(String rawName) async {
    return _runFormCommand(() async {
      await _createParticipantUseCase.execute(rawName);
      _participants = await _listParticipantsUseCase.execute();
    });
  }

  Future<bool> updateParticipant({
    required String participantId,
    required String rawName,
  }) async {
    return _runFormCommand(() async {
      await _updateParticipantUseCase.execute(
        participantId: participantId,
        rawName: rawName,
      );
      _participants = await _listParticipantsUseCase.execute();
    });
  }

  Future<bool> deleteParticipant(String participantId) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _deleteParticipantUseCase.execute(participantId);
      _participants = await _listParticipantsUseCase.execute();
      return true;
    } on ParticipantsValidationException catch (error) {
      _actionErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось удалить участника.';
      return false;
    } finally {
      _isSaving = false;
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

  Future<bool> _runFormCommand(Future<void> Function() action) async {
    _formErrorMessage = null;
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await action();
      return true;
    } on ParticipantsValidationException catch (error) {
      _formErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Не удалось сохранить изменения.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
