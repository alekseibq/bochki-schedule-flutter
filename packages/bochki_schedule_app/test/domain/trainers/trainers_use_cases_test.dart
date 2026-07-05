import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trainers use cases', () {
    test('list loads sorted trainers', () async {
      final repository = _InMemoryTrainersRepository(
        trainers: [
          Trainer(id: '2', name: 'Вася'),
          Trainer(id: '1', name: 'Анна'),
        ],
      );
      final useCase = ListTrainersUseCase(repository);

      final trainers = await useCase.execute();

      expect(trainers.map((trainer) => trainer.name), [
        'Анна',
        'Вася',
      ]);
    });

    test('create adds normalized trainer', () async {
      final repository = _InMemoryTrainersRepository();
      final useCase = CreateTrainerUseCase(repository);

      final trainer = await useCase.execute('  Иван   Иванов  ');

      expect(trainer.id, '1');
      expect(trainer.name, 'Иван Иванов');
      expect(repository.trainers.single.name, 'Иван Иванов');
    });

    test('empty name does not pass validation', () async {
      final repository = _InMemoryTrainersRepository();
      final useCase = CreateTrainerUseCase(repository);

      expect(
        () => useCase.execute('   '),
        throwsA(
          isA<TrainersValidationException>().having(
            (error) => error.message,
            'message',
            'Введите имя тренера.',
          ),
        ),
      );
    });
  });
}

final class _InMemoryTrainersRepository implements TrainersRepository {
  _InMemoryTrainersRepository({
    List<Trainer>? trainers,
  }) : _trainers = [...?trainers];

  final List<Trainer> _trainers;
  int _nextId = 1;

  List<Trainer> get trainers => List<Trainer>.unmodifiable(_trainers);

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
