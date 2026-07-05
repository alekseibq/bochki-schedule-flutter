import '../named_directory/update_named_directory_entry_use_case.dart';

import 'trainer.dart';
import 'trainers_repository.dart';
import 'trainers_validation_exception.dart';

final class UpdateTrainerUseCase {
  UpdateTrainerUseCase(TrainersRepository repository)
      : _delegate = UpdateNamedDirectoryEntryUseCase<Trainer>(
          repository,
          entryFactory: _entryFactory,
          emptyIdMessage: 'Идентификатор тренера не должен быть пустым.',
          emptyNameMessage: 'Введите имя тренера.',
          duplicateNameMessage: 'Тренер с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final UpdateNamedDirectoryEntryUseCase<Trainer> _delegate;

  Future<Trainer> execute({
    required String trainerId,
    required String rawName,
  }) {
    return _delegate.execute(
      entryId: trainerId,
      rawName: rawName,
    );
  }

  static Trainer _entryFactory({
    required String id,
    required String name,
  }) {
    return Trainer(
      id: id,
      name: name,
    );
  }

  static TrainersValidationException _validationException(String message) {
    return TrainersValidationException(message);
  }
}
