import '../../domain/participants/create_participant_use_case.dart';
import '../../domain/participants/delete_participant_use_case.dart';
import '../../domain/participants/list_participants_use_case.dart';
import '../../domain/participants/participant.dart';
import '../../domain/participants/update_participant_use_case.dart';

/// Commands used exclusively by the participants UI.
abstract interface class ParticipantsOperations {
  Future<List<Participant>> list();
  Future<Participant> create(String name);
  Future<Participant> update(String id, String name);
  Future<int> countReferences(String id);
  Future<void> delete(String id);
}

final class UseCaseParticipantsOperations implements ParticipantsOperations {
  const UseCaseParticipantsOperations({
    required ListParticipantsUseCase listParticipantsUseCase,
    required CreateParticipantUseCase createParticipantUseCase,
    required UpdateParticipantUseCase updateParticipantUseCase,
    required DeleteParticipantUseCase deleteParticipantUseCase,
  })  : _list = listParticipantsUseCase,
        _create = createParticipantUseCase,
        _update = updateParticipantUseCase,
        _delete = deleteParticipantUseCase;

  final ListParticipantsUseCase _list;
  final CreateParticipantUseCase _create;
  final UpdateParticipantUseCase _update;
  final DeleteParticipantUseCase _delete;

  @override
  Future<List<Participant>> list() => _list.execute();
  @override
  Future<Participant> create(String name) => _create.execute(name);
  @override
  Future<Participant> update(String id, String name) =>
      _update.execute(participantId: id, rawName: name);
  @override
  Future<int> countReferences(String id) => _delete.countReferences(id);
  @override
  Future<void> delete(String id) => _delete.execute(id);
}
