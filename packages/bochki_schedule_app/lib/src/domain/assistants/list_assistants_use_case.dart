import '../named_directory/list_named_directory_entries_use_case.dart';

import 'assistant.dart';
import 'assistants_repository.dart';

final class ListAssistantsUseCase {
  ListAssistantsUseCase(AssistantsRepository repository)
      : _delegate = ListNamedDirectoryEntriesUseCase<Assistant>(repository);

  final ListNamedDirectoryEntriesUseCase<Assistant> _delegate;

  Future<List<Assistant>> execute() {
    return _delegate.execute();
  }
}
