import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class UpdateParticipantUseCase {
  UpdateParticipantUseCase(this._repository);
  final ParticipantsRepository _repository;

  Future<Participant> execute(
      {required String participantId, required String rawName}) async {
    final id = Participant.normalizeId(participantId);
    if (id.isEmpty) {
      throw const ParticipantsValidationException(
          'Идентификатор участника не должен быть пустым.');
    }
    final name = Participant.normalizeName(rawName);
    if (name.isEmpty) {
      throw const ParticipantsValidationException('Введите имя участника.');
    }
    final participants = await _repository.list();
    final key = Participant.sortKeyForName(name);
    if (participants.any((entry) =>
        entry.id != id && Participant.sortKeyForName(entry.name) == key)) {
      throw const ParticipantsValidationException(
          'Участник с таким именем уже есть.');
    }
    return _repository.update(Participant(id: id, name: name));
  }
}
