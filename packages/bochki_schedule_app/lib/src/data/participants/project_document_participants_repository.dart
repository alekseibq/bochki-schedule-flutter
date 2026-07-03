import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_repository.dart';
import 'participants_dto.dart';
import 'participants_storage.dart';

final class ProjectDocumentParticipantsRepository
    implements ParticipantsRepository {
  const ProjectDocumentParticipantsRepository({
    required ParticipantsStorage storage,
  }) : _storage = storage;

  final ParticipantsStorage _storage;

  @override
  Future<List<Participant>> list() async {
    final document = await _storage.loadDocument();
    return document.participants
        .map(ParticipantDto.fromJson)
        .where((participant) => !participant.deleted)
        .map((participant) => participant.toDomain())
        .toList(growable: false);
  }

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final document = await _storage.loadDocument();
    final participants = _participantDtosFromDocument(document);
    final createdParticipant = Participant(
      id: document.nextId.toString(),
      name: name,
    );
    participants.add(
      ParticipantDto.fromDomain(createdParticipant, deleted: false),
    );

    await _storage.saveDocument(
      document.copyWith(
        nextId: document.nextId + 1,
        participants: _sortedParticipantJson(participants),
      ),
    );
    return createdParticipant;
  }

  @override
  Future<Participant> update(Participant participant) async {
    final document = await _storage.loadDocument();
    final participants = _participantDtosFromDocument(document);
    final participantId = int.parse(participant.id);
    final index = participants.indexWhere(
      (candidate) => candidate.id == participantId,
    );
    if (index != -1) {
      participants[index] = participants[index].copyWith(name: participant.name);
      await _storage.saveDocument(
        document.copyWith(
          participants: _sortedParticipantJson(participants),
        ),
      );
    }

    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    final document = await _storage.loadDocument();
    final participants = _participantDtosFromDocument(document);
    final parsedId = int.parse(participantId);
    final index = participants.indexWhere(
      (candidate) => candidate.id == parsedId,
    );
    if (index == -1) {
      return;
    }

    participants[index] = participants[index].copyWith(deleted: true);
    await _storage.saveDocument(
      document.copyWith(
        participants: _sortedParticipantJson(participants),
      ),
    );
  }

  List<ParticipantDto> _participantDtosFromDocument(ProjectDocument document) {
    return document.participants
        .map(ParticipantDto.fromJson)
        .toList(growable: true);
  }

  List<Map<String, Object?>> _sortedParticipantJson(
    List<ParticipantDto> participants,
  ) {
    participants.sort(
      (left, right) => Participant.sortKeyForName(left.name)
          .compareTo(Participant.sortKeyForName(right.name)),
    );
    return participants
        .map((participant) => participant.toJson())
        .toList(growable: false);
  }
}
