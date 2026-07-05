import '../named_directory/delete_named_directory_entry_use_case.dart';

import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class DeleteParticipantUseCase {
  DeleteParticipantUseCase(ParticipantsRepository repository)
      : _delegate = DeleteNamedDirectoryEntryUseCase<Participant>(
          repository,
          emptyIdMessage: 'Идентификатор участника не должен быть пустым.',
          exceptionFactory: _validationException,
        );

  final DeleteNamedDirectoryEntryUseCase<Participant> _delegate;

  Future<void> execute(String participantId) {
    return _delegate.execute(participantId);
  }

  static ParticipantsValidationException _validationException(String message) {
    return ParticipantsValidationException(message);
  }
}
