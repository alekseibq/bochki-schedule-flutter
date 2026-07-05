import '../named_directory/delete_named_directory_entry_use_case.dart';

import 'trainer.dart';
import 'trainers_repository.dart';
import 'trainers_validation_exception.dart';

final class DeleteTrainerUseCase {
  DeleteTrainerUseCase(TrainersRepository repository)
      : _delegate = DeleteNamedDirectoryEntryUseCase<Trainer>(
          repository,
          emptyIdMessage: 'Идентификатор тренера не должен быть пустым.',
          exceptionFactory: _validationException,
        );

  final DeleteNamedDirectoryEntryUseCase<Trainer> _delegate;

  Future<void> execute(String trainerId) {
    return _delegate.execute(trainerId);
  }

  static TrainersValidationException _validationException(String message) {
    return TrainersValidationException(message);
  }
}
