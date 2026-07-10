import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssistantsViewModel', () {
    late _InMemoryAssistantsRepository repository;
    late AssistantsViewModel viewModel;

    setUp(() {
      repository = _InMemoryAssistantsRepository(
        assistants: [
          Assistant(id: '2', name: 'Борис'),
          Assistant(id: '1', name: 'Анна'),
        ],
      );
      viewModel = AssistantsViewModel(
        listAssistantsUseCase: ListAssistantsUseCase(repository),
        createAssistantUseCase: CreateAssistantUseCase(repository),
        updateAssistantUseCase: UpdateAssistantUseCase(repository),
        deleteAssistantUseCase: DeleteAssistantUseCase(repository),
      );
    });

    test('loads assistants sorted by name', () async {
      await viewModel.loadAssistants();

      expect(viewModel.assistants.map((assistant) => assistant.name), [
        'Анна',
        'Борис',
      ]);
      expect(viewModel.loadErrorMessage, isNull);
    });

    test('empty name sets validation error', () async {
      await viewModel.loadAssistants();

      final isSuccess = await viewModel.createAssistant('   ');

      expect(isSuccess, isFalse);
      expect(viewModel.formErrorMessage, 'Введите имя ассистента.');
    });
  });
}

final class _InMemoryAssistantsRepository implements AssistantsRepository {
  _InMemoryAssistantsRepository({
    List<Assistant>? assistants,
  }) : _assistants = [...?assistants] {
    if (_assistants.isNotEmpty) {
      final maxId = _assistants
          .map((assistant) => int.parse(assistant.id))
          .reduce((left, right) => left > right ? left : right);
      _nextId = maxId + 1;
    }
  }

  final List<Assistant> _assistants;
  int _nextId = 1;

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
