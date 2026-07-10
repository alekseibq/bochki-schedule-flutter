import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assistants use cases', () {
    test('list loads sorted assistants', () async {
      final repository = _InMemoryAssistantsRepository(
        assistants: [
          Assistant(id: '2', name: 'Вася'),
          Assistant(id: '1', name: 'Анна'),
        ],
      );
      final useCase = ListAssistantsUseCase(repository);

      final assistants = await useCase.execute();

      expect(assistants.map((assistant) => assistant.name), [
        'Анна',
        'Вася',
      ]);
    });

    test('create adds normalized assistant', () async {
      final repository = _InMemoryAssistantsRepository();
      final useCase = CreateAssistantUseCase(repository);

      final assistant = await useCase.execute('  Иван   Иванов  ');

      expect(assistant.id, '1');
      expect(assistant.name, 'Иван Иванов');
      expect(repository.assistants.single.name, 'Иван Иванов');
    });

    test('empty name does not pass validation', () async {
      final repository = _InMemoryAssistantsRepository();
      final useCase = CreateAssistantUseCase(repository);

      expect(
        () => useCase.execute('   '),
        throwsA(
          isA<AssistantsValidationException>().having(
            (error) => error.message,
            'message',
            'Введите имя ассистента.',
          ),
        ),
      );
    });
  });
}

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  _InMemoryAssistantsRepository({
    List<Assistant>? assistants,
  }) : _assistants = [...?assistants];

  final List<Assistant> _assistants;
  int _nextId = 1;

  List<Assistant> get assistants => List<Assistant>.unmodifiable(_assistants);

  @override
  Future<Assistant> create({
    required String name,
  }) async {
    final assistant = Assistant(
      id: (_nextId++).toString(),
      name: name,
    );
    _assistants.add(assistant);
    return assistant;
  }

  @override
  Future<void> delete(String assistantId) async {
    _assistants.removeWhere((assistant) => assistant.id == assistantId);
  }

  @override
  Future<List<Assistant>> list() async {
    return [..._assistants];
  }

  @override
  Future<Assistant> update(Assistant assistant) async {
    final index = _assistants.indexWhere(
      (candidate) => candidate.id == assistant.id,
    );
    if (index != -1) {
      _assistants[index] = assistant;
    }
    return assistant;
  }
}
