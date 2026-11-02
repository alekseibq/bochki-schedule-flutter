import 'package:flutter/foundation.dart';

import '../../domain/named_directory/named_directory_entry.dart';
import '../../domain/named_directory/named_directory_validation_exception.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/create_participant_use_case.dart';
import '../../domain/participants/update_participant_use_case.dart';
import '../../domain/participants/delete_participant_use_case.dart';
import '../../domain/participants/list_participants_use_case.dart';
import '../directory/named_directory_view_model.dart';
import 'participants_operations.dart';

final class ParticipantsViewModel extends ChangeNotifier
    implements NamedDirectoryState<Participant> {
  ParticipantsViewModel({
    required ListParticipantsUseCase listParticipantsUseCase,
    required CreateParticipantUseCase createParticipantUseCase,
    required UpdateParticipantUseCase updateParticipantUseCase,
    required DeleteParticipantUseCase deleteParticipantUseCase,
  }) : this.fromOperations(UseCaseParticipantsOperations(
          listParticipantsUseCase: listParticipantsUseCase,
          createParticipantUseCase: createParticipantUseCase,
          updateParticipantUseCase: updateParticipantUseCase,
          deleteParticipantUseCase: deleteParticipantUseCase,
        ));

  ParticipantsViewModel.fromOperations(ParticipantsOperations operations)
      : _loadEntries = operations.list,
        _createEntry = operations.create,
        _updateEntry = ((
                {required entryId, required rawName, required fieldId}) =>
            operations.update(entryId, rawName)),
        _deleteEntry = operations.delete,
        _countReferences = operations.countReferences;

  final NamedDirectoryLoader<Participant> _loadEntries;
  final NamedDirectoryCreator<Participant> _createEntry;
  final NamedDirectoryUpdater<Participant> _updateEntry;
  final NamedDirectoryDeleter _deleteEntry;
  final NamedDirectoryReferenceCounter? _countReferences;
  final String loadErrorMessageText = 'Не удалось загрузить участников.';
  final String saveErrorMessageText = 'Не удалось сохранить изменения.';
  final String deleteErrorMessageText = 'Не удалось удалить участника.';

  List<Participant> _entries = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<Participant> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<int> countReferences(String entryId) async {
    return _countReferences?.call(entryId) ?? 0;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      _entries = _sortEntries(await _loadEntries());
    } catch (_) {
      _loadErrorMessage = loadErrorMessageText;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEntry(String rawName) async {
    return _runFormCommand(() async {
      final entry = await _createEntry(rawName);
      _entries = [..._entries, entry];
    });
  }

  Future<bool> updateEntry({
    required String entryId,
    required String rawName,
    String fieldId = 'name',
  }) async {
    return _runFormCommand(() async {
      final entry = await _updateEntry(
        entryId: entryId,
        rawName: rawName,
        fieldId: fieldId,
      );
      _entries = _entries
          .map(
            (candidate) => candidate.id == entry.id ? entry : candidate,
          )
          .toList(growable: false);
    });
  }

  Future<bool> deleteEntry(String entryId) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      await _deleteEntry(entryId);
      _entries = _entries
          .where((entry) => entry.id != entryId)
          .toList(growable: false);
      return true;
    } on NamedDirectoryValidationException catch (error) {
      _actionErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = deleteErrorMessageText;
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
    } on NamedDirectoryValidationException catch (error) {
      _formErrorMessage = error.message;
      return false;
    } catch (_) {
      _actionErrorMessage = saveErrorMessageText;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<Participant> _sortEntries(List<Participant> entries) {
    final sortedEntries = [...entries];
    sortedEntries.sort(
      (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
          .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
    );
    return List<Participant>.unmodifiable(sortedEntries);
  }

  List<Participant> get participants => entries;
  Future<void> loadParticipants() => loadEntries();
  Future<bool> createParticipant(String rawName) => createEntry(rawName);
  Future<bool> updateParticipant({
    required String participantId,
    required String rawName,
  }) =>
      updateEntry(entryId: participantId, rawName: rawName);
  Future<bool> deleteParticipant(String participantId) =>
      deleteEntry(participantId);
}
