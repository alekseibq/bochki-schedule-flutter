import 'participant.dart';

abstract interface class ParticipantsRepository {
  Future<List<Participant>> list();

  Future<Participant> create({
    required String name,
  });

  Future<Participant> update(Participant participant);

  Future<void> delete(String participantId);
}
