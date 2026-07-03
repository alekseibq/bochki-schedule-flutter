import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class DeleteParticipantUseCase {
  const DeleteParticipantUseCase(this._repository);

  final ParticipantsRepository _repository;

  Future<void> execute(String participantId) async {
    final normalizedId = Participant.normalizeId(participantId);
    if (normalizedId.isEmpty) {
      throw const ParticipantsValidationException(
        'Идентификатор участника не должен быть пустым.',
      );
    }

    await _repository.delete(normalizedId);
  }
}
