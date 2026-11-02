import '../named_directory/create_named_directory_entry_use_case.dart';

import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class CreateParticipantUseCase {
  CreateParticipantUseCase(ParticipantsRepository repository)
      : _delegate = CreateNamedDirectoryEntryUseCase<Participant>(
          repository,
          emptyNameMessage: 'Введите имя участника.',
          duplicateNameMessage: 'Участник с таким именем уже есть.',
          exceptionFactory: _validationException,
        );

  final CreateNamedDirectoryEntryUseCase<Participant> _delegate;

  Future<Participant> execute(String rawName) {
    return _delegate.execute(rawName);
  }

  static ParticipantsValidationException _validationException(String message) {
    return ParticipantsValidationException(message);
  }
}
