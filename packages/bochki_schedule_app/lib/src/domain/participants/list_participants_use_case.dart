import '../named_directory/list_named_directory_entries_use_case.dart';

import 'participant.dart';
import 'participants_repository.dart';

final class ListParticipantsUseCase {
  ListParticipantsUseCase(ParticipantsRepository repository)
      : _delegate = ListNamedDirectoryEntriesUseCase<Participant>(repository);

  final ListNamedDirectoryEntriesUseCase<Participant> _delegate;

  Future<List<Participant>> execute() {
    return _delegate.execute();
  }
}
