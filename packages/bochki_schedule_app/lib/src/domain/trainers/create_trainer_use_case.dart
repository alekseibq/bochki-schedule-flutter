import '../named_directory/create_named_directory_entry_use_case.dart';

import 'trainer.dart';
import 'trainers_repository.dart';
import 'trainers_validation_exception.dart';

final class CreateTrainerUseCase {
  CreateTrainerUseCase(TrainersRepository repository)
      : _delegate = CreateNamedDirectoryEntryUseCase<Trainer>(
          repository,
          emptyNameMessage: 'Введите имя тренера.',
          duplicateNameMessage: 'Тренер с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final CreateNamedDirectoryEntryUseCase<Trainer> _delegate;

  Future<Trainer> execute(String rawName) {
    return _delegate.execute(rawName);
  }

  static TrainersValidationException _validationException(String message) {
    return TrainersValidationException(message);
  }
}
