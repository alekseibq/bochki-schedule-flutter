import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainersViewModel', () {
    late _InMemoryTrainersRepository repository;
    late TrainersViewModel viewModel;

    setUp(() {
      repository = _InMemoryTrainersRepository(
        trainers: [
          Trainer(id: '2', name: 'Борис'),
          Trainer(id: '1', name: 'Анна'),
        ],
      );
      viewModel = TrainersViewModel(
        listTrainersUseCase: ListTrainersUseCase(repository),
        createTrainerUseCase: CreateTrainerUseCase(repository),
        updateTrainerUseCase: UpdateTrainerUseCase(repository),
        deleteTrainerUseCase: DeleteTrainerUseCase(repository),
      );
    });

    test('loads trainers sorted by name', () async {
      await viewModel.loadTrainers();

      expect(viewModel.trainers.map((trainer) => trainer.name), [
        'Анна',
        'Борис',
      ]);
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('empty name sets validation error', () async {
      await viewModel.loadTrainers();

      final isSuccess = await viewModel.createTrainer('   ');

      expect(isSuccess, isFalse);
      expect(viewModel.formErrorMessage, 'Введите имя тренера.');
    });
  });
}

final class _InMemoryTrainersRepository implements TrainersRepository {
  _InMemoryTrainersRepository({
    List<Trainer>? trainers,
  }) : _trainers = [...?trainers] {
    if (_trainers.isNotEmpty) {
      final maxId = _trainers
          .map((trainer) => int.parse(trainer.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Trainer> _trainers;
  int _nextId = 1;

  @override
  Future<Trainer> create({
    required String name,
  }) async {
    final trainer = Trainer(
      id: (_nextId++).toString(),
      name: name,
    );
    _trainers.add(trainer);
    return trainer;
  }

  @override
  Future<void> delete(String trainerId) async {
    _trainers.removeWhere((trainer) => trainer.id == trainerId);
  }

  @override
  Future<List<Trainer>> list() async {
    return [..._trainers];
  }

  @override
  Future<Trainer> update(Trainer trainer) async {
    final index = _trainers.indexWhere(
      (candidate) => candidate.id == trainer.id,
    );
    if (index != -1) {
      _trainers[index] = trainer;
    }
    return trainer;
  }
}
