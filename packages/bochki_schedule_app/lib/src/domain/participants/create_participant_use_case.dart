import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class CreateParticipantUseCase {
  const CreateParticipantUseCase(this._repository);

  final ParticipantsRepository _repository;

  Future<Participant> execute(String rawName) async {
    final normalizedName = Participant.normalizeName(rawName);
    if (normalizedName.isEmpty) {
      throw const ParticipantsValidationException('Введите имя участника.');
    }

    final participants = await _repository.list();
    final normalizedCandidate = Participant.sortKeyForName(normalizedName);
    final hasDuplicate = participants.any(
      (participant) =>
          Participant.sortKeyForName(participant.name) == normalizedCandidate,
    );
    if (hasDuplicate) {
      throw const ParticipantsValidationException(
        'Участник с таким именем уже есть.',
      );
    }

    return _repository.create(name: normalizedName);
  }
}
