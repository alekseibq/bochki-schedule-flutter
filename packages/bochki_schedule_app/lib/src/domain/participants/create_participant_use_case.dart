import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class CreateParticipantUseCase {
  CreateParticipantUseCase(this._repository);
  final ParticipantsRepository _repository;

  Future<Participant> execute(String rawName) async {
    final name = Participant.normalizeName(rawName);
    if (name.isEmpty) {
      throw const ParticipantsValidationException('Введите имя участника.');
    }
    final participants = await _repository.list();
    final key = Participant.sortKeyForName(name);
    if (participants
        .any((entry) => Participant.sortKeyForName(entry.name) == key)) {
      throw const ParticipantsValidationException(
          'Участник с таким именем уже есть.');
    }
    return _repository.create(name: name);
  }
}
