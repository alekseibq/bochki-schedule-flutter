import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

final class ParticipantsDirectoryUseCase {
  ParticipantsDirectoryUseCase({
    required ProjectDocumentRepository repository,
  }) : _repository = repository;

  final ProjectDocumentRepository _repository;

  Future<ProjectDocument> loadDocument() {
    return _repository.load();
  }

  List<Map<String, Object?>> activeParticipants(ProjectDocument document) {
    final activeParticipants = _participantsFromDocument(document)
        .where((participant) => !participant.deleted)
        .toList(growable: false);
    activeParticipants.sort(_compareParticipantsByName);
    return activeParticipants
        .map((participant) => participant.toJson())
        .toList(growable: false);
  }

  Future<ParticipantsDirectoryMutationResult> addParticipant(
    ProjectDocument document,
    String rawName,
  ) {
    return _upsertParticipant(
      document: document,
      rawName: rawName,
      editingParticipantId: null,
    );
  }

  Future<ParticipantsDirectoryMutationResult> editParticipant(
    ProjectDocument document,
    int participantId,
    String rawName,
  ) {
    return _upsertParticipant(
      document: document,
      rawName: rawName,
      editingParticipantId: participantId,
    );
  }

  Future<ParticipantsDirectoryMutationResult> deleteParticipant(
    ProjectDocument document,
    int participantId,
  ) async {
    final participants = _participantsFromDocument(document);
    final index = participants.indexWhere(
      (candidate) => candidate.id == participantId,
    );
    if (index != -1) {
      participants[index] = participants[index].copyWith(deleted: true);
    }

    final updatedDocument = document.copyWith(
      participants: _sortedParticipantJson(participants),
    );
    return _persist(updatedDocument);
  }

  Future<ParticipantsDirectoryMutationResult> _upsertParticipant({
    required ProjectDocument document,
    required String rawName,
    required int? editingParticipantId,
  }) async {
    final normalizedName = _normalizeName(rawName);
    if (normalizedName.isEmpty) {
      return const ParticipantsDirectoryMutationResult.failure(
        'Введите имя участника.',
      );
    }

    if (_hasDuplicateName(
      document: document,
      normalizedName: normalizedName,
      editingParticipantId: editingParticipantId,
    )) {
      return const ParticipantsDirectoryMutationResult.failure(
        'Участник с таким именем уже есть.',
      );
    }

    final participants = _participantsFromDocument(document);
    if (editingParticipantId == null) {
      participants.add(
        _ParticipantRecord(
          id: document.nextId,
          name: normalizedName,
          deleted: false,
        ),
      );
    } else {
      final index = participants.indexWhere(
        (participant) => participant.id == editingParticipantId,
      );
      if (index != -1) {
        participants[index] = participants[index].copyWith(
          name: normalizedName,
        );
      }
    }

    final updatedDocument = document.copyWith(
      nextId:
          editingParticipantId == null ? document.nextId + 1 : document.nextId,
      participants: _sortedParticipantJson(participants),
    );
    return _persist(updatedDocument);
  }

  Future<ParticipantsDirectoryMutationResult> _persist(
    ProjectDocument document,
  ) async {
    try {
      await _repository.save(document);
      return ParticipantsDirectoryMutationResult.success(document);
    } catch (_) {
      return const ParticipantsDirectoryMutationResult.failure(
        'Не удалось сохранить изменения.',
      );
    }
  }

  bool _hasDuplicateName({
    required ProjectDocument document,
    required String normalizedName,
    required int? editingParticipantId,
  }) {
    final normalizedCandidate = normalizedName.toLowerCase();
    return _participantsFromDocument(document).any((participant) {
      if (participant.deleted) {
        return false;
      }
      if (participant.id == editingParticipantId) {
        return false;
      }
      return _normalizedSortKey(participant.name) == normalizedCandidate;
    });
  }

  List<_ParticipantRecord> _participantsFromDocument(
    ProjectDocument document,
  ) {
    return document.participants
        .map(_ParticipantRecord.fromJson)
        .toList(growable: true);
  }

  List<Map<String, Object?>> _sortedParticipantJson(
    List<_ParticipantRecord> participants,
  ) {
    participants.sort(_compareParticipantsByName);
    return participants
        .map((participant) => participant.toJson())
        .toList(growable: false);
  }

  static int _compareParticipantsByName(
    _ParticipantRecord left,
    _ParticipantRecord right,
  ) {
    return _normalizedSortKey(left.name)
        .compareTo(_normalizedSortKey(right.name));
  }

  static String _normalizedSortKey(String value) {
    return _normalizeName(value).toLowerCase();
  }

  static String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

final class ParticipantsDirectoryMutationResult {
  const ParticipantsDirectoryMutationResult._({
    this.document,
    this.errorMessage,
  });

  const ParticipantsDirectoryMutationResult.success(ProjectDocument document)
      : this._(document: document);

  const ParticipantsDirectoryMutationResult.failure(String errorMessage)
      : this._(errorMessage: errorMessage);

  final ProjectDocument? document;
  final String? errorMessage;

  bool get isSuccess => document != null;
}

final class _ParticipantRecord {
  const _ParticipantRecord({
    required this.id,
    required this.name,
    required this.deleted,
  });

  factory _ParticipantRecord.fromJson(Map<String, Object?> json) {
    return _ParticipantRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final bool deleted;

  _ParticipantRecord copyWith({
    int? id,
    String? name,
    bool? deleted,
  }) {
    return _ParticipantRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'deleted': deleted,
    };
  }
}
