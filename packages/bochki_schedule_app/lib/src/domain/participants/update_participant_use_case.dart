import '../named_directory/update_named_directory_entry_use_case.dart';

import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class UpdateParticipantUseCase {
  UpdateParticipantUseCase(ParticipantsRepository repository)
      : _delegate = UpdateNamedDirectoryEntryUseCase<Participant>(
          repository,
          entryFactory: _entryFactory,
          emptyIdMessage: 'Идентификатор участника не должен быть пустым.',
          emptyNameMessage: 'Введите имя участника.',
          duplicateNameMessage: 'Участник с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final UpdateNamedDirectoryEntryUseCase<Participant> _delegate;

  Future<Participant> execute({
    required String participantId,
    required String rawName,
  }) {
    return _delegate.execute(
      entryId: participantId,
      rawName: rawName,
    );
  }

  static Participant _entryFactory({
    required String id,
    required String name,
  }) {
    return Participant(
      id: id,
      name: name,
    );
  }

  static ParticipantsValidationException _validationException(String message) {
    return ParticipantsValidationException(message);
  }
}
