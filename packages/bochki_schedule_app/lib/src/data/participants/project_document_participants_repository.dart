import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_repository.dart';
import '../project_document/project_document_id_allocator.dart';
import '../project_document/project_document_sync_part.dart';
import 'participants_dto.dart';

final class ProjectDocumentParticipantsRepository
    with DirtyTrackingProjectDocumentSyncPart
    implements ParticipantsRepository, ProjectDocumentSyncPart {
  ProjectDocumentParticipantsRepository({
    required ProjectDocument initialDocument,
    required ProjectDocumentIdAllocator idAllocator,
    required void Function() onChanged,
  })  : _idAllocator = idAllocator,
        _onChanged = onChanged,
        _participants = initialDocument.participants
            .map(ParticipantDto.fromJson)
            .toList(growable: true);

  final ProjectDocumentIdAllocator _idAllocator;
  final void Function() _onChanged;
  final List<ParticipantDto> _participants;

  @override
  Future<List<Participant>> list() async {
    return _participants
        .where((participant) => !participant.deleted)
        .map((participant) => participant.toDomain())
        .toList(growable: false);
  }

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final createdParticipant = Participant(
      id: _idAllocator.nextId().toString(),
      name: name,
    );
    _participants.add(
      ParticipantDto.fromDomain(createdParticipant, deleted: false),
    );
    _markRepositoryChanged();
    return createdParticipant;
  }

  @override
  Future<Participant> update(Participant participant) async {
    final participantId = int.parse(participant.id);
    final index = _participants.indexWhere(
      (candidate) => candidate.id == participantId,
    );
    if (index != -1) {
      final current = _participants[index];
      if (current.name != participant.name || current.deleted) {
        _participants[index] = current.copyWith(
          name: participant.name,
          deleted: false,
        );
        _markRepositoryChanged();
      }
    }

    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    final parsedId = int.parse(participantId);
    final index = _participants.indexWhere(
      (candidate) => candidate.id == parsedId,
    );
    if (index == -1 || _participants[index].deleted) {
      return;
    }

    _participants[index] = _participants[index].copyWith(deleted: true);
    _markRepositoryChanged();
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return document.copyWith(
      participants: _sortedParticipantJson(_participants),
    );
  }

  List<Map<String, Object?>> _sortedParticipantJson(
    List<ParticipantDto> participants,
  ) {
    final sortedParticipants = [...participants]..sort(
        (left, right) => Participant.sortKeyForName(left.name)
            .compareTo(Participant.sortKeyForName(right.name)),
      );
    return sortedParticipants
        .map((participant) => participant.toJson())
        .toList(growable: false);
  }

  void _markRepositoryChanged() {
    markChanged();
    _onChanged();
  }
}
