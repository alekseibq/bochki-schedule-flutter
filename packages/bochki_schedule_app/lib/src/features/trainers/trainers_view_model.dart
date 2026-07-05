import '../../domain/trainers/create_trainer_use_case.dart';
import '../../domain/trainers/delete_trainer_use_case.dart';
import '../../domain/trainers/list_trainers_use_case.dart';
import '../../domain/trainers/trainer.dart';
import '../../domain/trainers/update_trainer_use_case.dart';
import '../directory/named_directory_view_model.dart';

final class TrainersViewModel extends NamedDirectoryViewModel<Trainer> {
  TrainersViewModel({
    required ListTrainersUseCase listTrainersUseCase,
    required CreateTrainerUseCase createTrainerUseCase,
    required UpdateTrainerUseCase updateTrainerUseCase,
    required DeleteTrainerUseCase deleteTrainerUseCase,
  }) : super(
          loadEntries: listTrainersUseCase.execute,
          createEntry: createTrainerUseCase.execute,
          updateEntry: ({
            required String entryId,
            required String rawName,
          }) {
            return updateTrainerUseCase.execute(
              trainerId: entryId,
              rawName: rawName,
            );
          },
          deleteEntry: deleteTrainerUseCase.execute,
          loadErrorMessageText: 'Не удалось загрузить тренеров.',
          saveErrorMessageText: 'Не удалось сохранить изменения.',
          deleteErrorMessageText: 'Не удалось удалить тренера.',
        );

  List<Trainer> get trainers => entries;

  Future<void> loadTrainers() {
    return loadEntries();
  }

  Future<bool> createTrainer(String rawName) {
    return createEntry(rawName);
  }

  Future<bool> updateTrainer({
    required String trainerId,
    required String rawName,
  }) {
    return updateEntry(
      entryId: trainerId,
      rawName: rawName,
    );
  }

  Future<bool> deleteTrainer(String trainerId) {
    return deleteEntry(trainerId);
  }
}
