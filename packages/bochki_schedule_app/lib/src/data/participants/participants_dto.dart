import '../../domain/participants/participant.dart';

final class ParticipantDto {
  const ParticipantDto({
    required this.id,
    required this.name,
    required this.deleted,
  });

  factory ParticipantDto.fromJson(Map<String, Object?> json) {
    return ParticipantDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory ParticipantDto.fromDomain(
    Participant participant, {
    required bool deleted,
  }) {
    return ParticipantDto(
      id: int.parse(participant.id),
      name: participant.name,
      deleted: deleted,
    );
  }

  final int id;
  final String name;
  final bool deleted;

  Participant toDomain() {
    return Participant(
      id: id.toString(),
      name: name,
    );
  }

  ParticipantDto copyWith({
    int? id,
    String? name,
    bool? deleted,
  }) {
    return ParticipantDto(
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
