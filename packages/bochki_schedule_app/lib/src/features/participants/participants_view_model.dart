import 'package:flutter/foundation.dart';

import '../../domain/named_directory/named_directory_validation_exception.dart';
import '../../domain/participants/create_participant_use_case.dart';
import '../../domain/participants/delete_participant_use_case.dart';
import '../../domain/participants/list_participants_use_case.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/update_participant_use_case.dart';

/// State for the participants feature. It intentionally has no dependency on
/// the legacy generic named-directory ViewModel.
final class ParticipantsViewModel extends ChangeNotifier {
  ParticipantsViewModel({
    required ListParticipantsUseCase listParticipantsUseCase,
    required CreateParticipantUseCase createParticipantUseCase,
    required UpdateParticipantUseCase updateParticipantUseCase,
    required DeleteParticipantUseCase deleteParticipantUseCase,
  })  : _list = listParticipantsUseCase,
        _create = createParticipantUseCase,
        _update = updateParticipantUseCase,
        _delete = deleteParticipantUseCase;

  final ListParticipantsUseCase _list;
  final CreateParticipantUseCase _create;
  final UpdateParticipantUseCase _update;
  final DeleteParticipantUseCase _delete;
  List<Participant> _entries = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<Participant> get entries => _entries;
  List<Participant> get participants => _entries;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadParticipants() => _load();
  Future<void> loadEntries() => _load();

  Future<void> _load() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();
    try {
      _entries = _sort(await _list.execute());
    } catch (_) {
      _loadErrorMessage = 'Не удалось загрузить участников.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createParticipant(String rawName) => createEntry(rawName);
  Future<bool> createEntry(String rawName) => _save(() async {
        _entries = _sort([..._entries, await _create.execute(rawName)]);
      });

  Future<bool> updateParticipant({
    required String participantId,
    required String rawName,
  }) =>
      updateEntry(entryId: participantId, rawName: rawName);

  Future<bool> updateEntry({
    required String entryId,
    required String rawName,
    String fieldId = 'name',
  }) =>
      _save(() async {
        final value = await _update.execute(
          participantId: entryId,
          rawName: rawName,
        );
        _entries = _sort([
          for (final entry in _entries)
            if (entry.id == value.id) value else entry,
        ]);
      });

  Future<int> countReferences(String id) => _delete.countReferences(id);
  Future<bool> deleteParticipant(String id) => deleteEntry(id);
  Future<bool> deleteEntry(String id) async {
    _actionErrorMessage = null;
    _isSaving = true;
    notifyListeners();
    try {
      await _delete.execute(id);
      _entries =
          _entries.where((entry) => entry.id != id).toList(growable: false);
      return true;
    } on NamedDirectoryValidationException catch (error) {
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
    if (_formErrorMessage == null) return;
    _formErrorMessage = null;
    notifyListeners();
  }

  void clearActionError() => _actionErrorMessage = null;

  Future<bool> _save(Future<void> Function() action) async {
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
      _actionErrorMessage = 'Не удалось сохранить изменения.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<Participant> _sort(List<Participant> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sorted);
  }
}
