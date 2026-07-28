import '../../domain/humans/human.dart';

final class HumanDto {
  const HumanDto({
    required this.id,
    required this.name,
    required this.shortName,
    required this.isParticipant,
    required this.isAssistant,
    required this.deleted,
  });

  factory HumanDto.fromJson(Map<String, Object?> json) {
    return HumanDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      shortName:
          (json['shortName'] as String?) ?? (json['name'] as String?) ?? '',
      isParticipant: json['isParticipant'] as bool? ?? false,
      isAssistant: json['isAssistant'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory HumanDto.fromDomain(
    Human human, {
    required bool deleted,
  }) {
    return HumanDto(
      id: int.parse(human.id),
      name: human.name,
      shortName: human.shortName,
      isParticipant: human.isParticipant,
      isAssistant: human.isAssistant,
      deleted: deleted,
    );
  }

  final int id;
  final String name;
  final String shortName;
  final bool isParticipant;
  final bool isAssistant;
  final bool deleted;

  Human toDomain() {
    return Human(
      id: id.toString(),
      name: name,
      shortName: shortName,
      isParticipant: isParticipant,
      isAssistant: isAssistant,
    );
  }

  HumanDto copyWith({
    int? id,
    String? name,
    String? shortName,
    bool? isParticipant,
    bool? isAssistant,
    bool? deleted,
  }) {
    return HumanDto(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      isParticipant: isParticipant ?? this.isParticipant,
      isAssistant: isAssistant ?? this.isAssistant,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'shortName': shortName,
      'isParticipant': isParticipant,
      'isAssistant': isAssistant,
      'deleted': deleted,
    };
  }
}
