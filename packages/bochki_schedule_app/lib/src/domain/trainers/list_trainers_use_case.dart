import '../named_directory/list_named_directory_entries_use_case.dart';

import 'trainer.dart';
import 'trainers_repository.dart';

final class ListTrainersUseCase {
  ListTrainersUseCase(TrainersRepository repository)
      : _delegate = ListNamedDirectoryEntriesUseCase<Trainer>(repository);

  final ListNamedDirectoryEntriesUseCase<Trainer> _delegate;

  Future<List<Trainer>> execute() {
    return _delegate.execute();
  }
}
