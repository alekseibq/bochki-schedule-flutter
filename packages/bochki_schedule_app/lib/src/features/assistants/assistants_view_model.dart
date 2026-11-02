import 'package:flutter/foundation.dart';

import '../../domain/named_directory/named_directory_entry.dart';
import '../../domain/named_directory/named_directory_validation_exception.dart';
import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/create_assistant_use_case.dart';
import '../../domain/assistants/update_assistant_use_case.dart';
import '../../domain/assistants/delete_assistant_use_case.dart';
import '../../domain/assistants/list_assistants_use_case.dart';
import 'assistants_operations.dart';

final class AssistantsViewModel extends ChangeNotifier {
  AssistantsViewModel({
    required ListAssistantsUseCase listAssistantsUseCase,
    required CreateAssistantUseCase createAssistantUseCase,
    required UpdateAssistantUseCase updateAssistantUseCase,
    required DeleteAssistantUseCase deleteAssistantUseCase,
  }) : this.fromOperations(UseCaseAssistantsOperations(
          listAssistantsUseCase: listAssistantsUseCase,
          createAssistantUseCase: createAssistantUseCase,
          updateAssistantUseCase: updateAssistantUseCase,
          deleteAssistantUseCase: deleteAssistantUseCase,
        ));

  AssistantsViewModel.fromOperations(AssistantsOperations operations)
      : _loadEntries = operations.list,
        _createEntry = operations.create,
        _updateEntry = ((
                {required entryId, required rawName, required fieldId}) =>
            operations.update(entryId, rawName)),
        _deleteEntry = operations.delete,
        _countReferences = operations.countReferences;

  final Future<List<Assistant>> Function() _loadEntries;
  final Future<Assistant> Function(String) _createEntry;
  final Future<Assistant> Function(
      {required String entryId,
      required String rawName,
      required String fieldId}) _updateEntry;
  final Future<void> Function(String) _deleteEntry;
  final Future<int> Function(String)? _countReferences;
  final String loadErrorMessageText = 'Не удалось загрузить сопровождающих.';
  final String saveErrorMessageText = 'Не удалось сохранить изменения.';
  final String deleteErrorMessageText = 'Не удалось удалить сопровождающего.';

  List<Assistant> _entries = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<Assistant> get entries => _entries;
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

  List<Assistant> _sortEntries(List<Assistant> entries) {
    final sortedEntries = [...entries];
    sortedEntries.sort(
      (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
          .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
    );
    return List<Assistant>.unmodifiable(sortedEntries);
  }

  List<Assistant> get assistants => entries;
  Future<void> loadAssistants() => loadEntries();
  Future<bool> createAssistant(String rawName) => createEntry(rawName);
  Future<bool> updateAssistant({
    required String assistantId,
    required String rawName,
    String fieldId = 'name',
  }) =>
      updateEntry(entryId: assistantId, rawName: rawName, fieldId: fieldId);
  Future<bool> deleteAssistant(String assistantId) => deleteEntry(assistantId);
}
