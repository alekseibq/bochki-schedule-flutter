import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class UpdateParticipantUseCase {
  const UpdateParticipantUseCase(this._repository);

  final ParticipantsRepository _repository;

  Future<Participant> execute({
    required String participantId,
    required String rawName,
  }) async {
    final normalizedId = Participant.normalizeId(participantId);
    if (normalizedId.isEmpty) {
      throw const ParticipantsValidationException(
        'Идентификатор участника не должен быть пустым.',
      );
    }

    final normalizedName = Participant.normalizeName(rawName);
    if (normalizedName.isEmpty) {
      throw const ParticipantsValidationException('Введите имя участника.');
    }

    final participants = await _repository.list();
    final normalizedCandidate = Participant.sortKeyForName(normalizedName);
    final hasDuplicate = participants.any(
      (participant) =>
          participant.id != normalizedId &&
          Participant.sortKeyForName(participant.name) == normalizedCandidate,
    );
    if (hasDuplicate) {
      throw const ParticipantsValidationException(
        'Участник с таким именем уже есть.',
      );
    }

    return _repository.update(
      Participant(
        id: normalizedId,
        name: normalizedName,
      ),
    );
  }
}
