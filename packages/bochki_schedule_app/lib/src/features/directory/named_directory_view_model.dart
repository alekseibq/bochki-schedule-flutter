import 'package:flutter/foundation.dart';

import '../../domain/named_directory/named_directory_entry.dart';
import '../../domain/named_directory/named_directory_validation_exception.dart';

typedef NamedDirectoryLoader<T extends NamedDirectoryEntry> = Future<List<T>>
    Function();
typedef NamedDirectoryCreator<T extends NamedDirectoryEntry> = Future<T>
    Function(String rawName);
typedef NamedDirectoryUpdater<T extends NamedDirectoryEntry> = Future<T>
    Function({
  required String entryId,
  required String rawName,
});
typedef NamedDirectoryDeleter = Future<void> Function(String entryId);

class NamedDirectoryViewModel<T extends NamedDirectoryEntry>
    extends ChangeNotifier {
  NamedDirectoryViewModel({
    required NamedDirectoryLoader<T> loadEntries,
    required NamedDirectoryCreator<T> createEntry,
    required NamedDirectoryUpdater<T> updateEntry,
    required NamedDirectoryDeleter deleteEntry,
    required this.loadErrorMessageText,
    required this.saveErrorMessageText,
    required this.deleteErrorMessageText,
  })  : _loadEntries = loadEntries,
        _createEntry = createEntry,
        _updateEntry = updateEntry,
        _deleteEntry = deleteEntry;

  final NamedDirectoryLoader<T> _loadEntries;
  final NamedDirectoryCreator<T> _createEntry;
  final NamedDirectoryUpdater<T> _updateEntry;
  final NamedDirectoryDeleter _deleteEntry;
  final String loadErrorMessageText;
  final String saveErrorMessageText;
  final String deleteErrorMessageText;

  List<T> _entries = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _formErrorMessage;
  String? _actionErrorMessage;

  List<T> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

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
  }) async {
    return _runFormCommand(() async {
      final entry = await _updateEntry(
        entryId: entryId,
        rawName: rawName,
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

  List<T> _sortEntries(List<T> entries) {
    final sortedEntries = [...entries];
    sortedEntries.sort(
      (left, right) => NamedDirectoryEntry.sortKeyForName(left.name)
          .compareTo(NamedDirectoryEntry.sortKeyForName(right.name)),
    );
    return List<T>.unmodifiable(sortedEntries);
  }
}
