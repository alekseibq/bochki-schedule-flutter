import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/assistants_repository.dart';
import '../../domain/humans/human.dart';
import '../../domain/humans/humans_repository.dart';

final class ProjectDocumentAssistantsRepository
    implements AssistantsRepository {
  ProjectDocumentAssistantsRepository({
    required HumansRepository humansRepository,
  }) : _humansRepository = humansRepository;

  final HumansRepository _humansRepository;

  @override
  Future<List<Assistant>> list() async {
    final humans = await _humansRepository.list();
    return humans
        .where((human) => human.isAssistant)
        .map(
          (human) => Assistant(
            id: human.id,
            name: human.name,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Assistant> create({
    required String name,
  }) async {
    final human = await _humansRepository.create(
      name: name,
      isParticipant: false,
      isAssistant: true,
    );
    return Assistant(id: human.id, name: human.name);
  }

  @override
  Future<Assistant> update(Assistant entry) async {
    final humans = await _humansRepository.list();
    Human? current;
    for (final human in humans) {
      if (human.id == entry.id) {
        current = human;
        break;
      }
    }
    if (current == null) {
      return entry;
    }

    await _humansRepository.update(
      current.copyWith(
        name: entry.name,
        isAssistant: true,
      ),
    );
    return entry;
  }

  @override
  Future<void> delete(String entryId) async {
    final humans = await _humansRepository.list();
    Human? current;
    for (final human in humans) {
      if (human.id == entryId) {
        current = human;
        break;
      }
    }
    if (current == null) {
      return;
    }

    await _humansRepository.update(
      current.copyWith(
        isParticipant: current.isParticipant,
        isAssistant: false,
      ),
    );

    if (!current.isParticipant) {
      await _humansRepository.delete(entryId);
    }
  }
}
