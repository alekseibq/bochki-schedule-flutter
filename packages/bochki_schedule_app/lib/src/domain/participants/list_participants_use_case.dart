import 'participant.dart';
import 'participants_repository.dart';

final class ListParticipantsUseCase {
  const ListParticipantsUseCase(this._repository);

  final ParticipantsRepository _repository;

  Future<List<Participant>> execute() async {
    final participants = await _repository.list();
    participants.sort(
      (left, right) => Participant.sortKeyForName(left.name)
          .compareTo(Participant.sortKeyForName(right.name)),
    );
    return List<Participant>.unmodifiable(participants);
  }
}
