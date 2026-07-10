import '../../domain/humans/human.dart';
import '../../domain/humans/humans_repository.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_repository.dart';

final class ProjectDocumentParticipantsRepository
    implements ParticipantsRepository {
  ProjectDocumentParticipantsRepository({
    required HumansRepository humansRepository,
  }) : _humansRepository = humansRepository;

  final HumansRepository _humansRepository;

  @override
  Future<List<Participant>> list() async {
    final humans = await _humansRepository.list();
    return humans
        .where((human) => human.isParticipant)
        .map(
          (human) => Participant(
            id: human.id,
            name: human.name,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final human = await _humansRepository.create(
      name: name,
      isParticipant: true,
      isAssistant: false,
    );
    return Participant(id: human.id, name: human.name);
  }

  @override
  Future<Participant> update(Participant entry) async {
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
        isParticipant: true,
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
        isParticipant: false,
        isAssistant: current.isAssistant,
      ),
    );

    if (!current.isAssistant) {
      await _humansRepository.delete(entryId);
    }
  }
}
