import '../../features/directory/named_directory_view_model.dart';
import '../../domain/participants/create_participant_use_case.dart';
import '../../domain/participants/delete_participant_use_case.dart';
import '../../domain/participants/list_participants_use_case.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/update_participant_use_case.dart';

final class ParticipantsViewModel extends NamedDirectoryViewModel<Participant> {
  ParticipantsViewModel({
    required ListParticipantsUseCase listParticipantsUseCase,
    required CreateParticipantUseCase createParticipantUseCase,
    required UpdateParticipantUseCase updateParticipantUseCase,
    required DeleteParticipantUseCase deleteParticipantUseCase,
  }) : super(
          loadEntries: listParticipantsUseCase.execute,
          createEntry: createParticipantUseCase.execute,
          updateEntry: ({
            required String entryId,
            required String rawName,
          }) {
            return updateParticipantUseCase.execute(
              participantId: entryId,
              rawName: rawName,
            );
          },
          deleteEntry: deleteParticipantUseCase.execute,
          loadErrorMessageText: 'Не удалось загрузить участников.',
          saveErrorMessageText: 'Не удалось сохранить изменения.',
          deleteErrorMessageText: 'Не удалось удалить участника.',
        );

  List<Participant> get participants => entries;

  Future<void> loadParticipants() {
    return loadEntries();
  }

  Future<bool> createParticipant(String rawName) {
    return createEntry(rawName);
  }

  Future<bool> updateParticipant({
    required String participantId,
    required String rawName,
  }) {
    return updateEntry(
      entryId: participantId,
      rawName: rawName,
    );
  }

  Future<bool> deleteParticipant(String participantId) {
    return deleteEntry(participantId);
  }
}
