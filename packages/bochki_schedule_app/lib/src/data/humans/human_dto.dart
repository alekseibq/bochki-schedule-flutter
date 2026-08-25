import '../../domain/humans/human.dart';

final class HumanDto {
  const HumanDto({
    required this.id,
    required this.name,
    required this.shortName,
    required this.seminarRole,
    required this.procedureRoles,
    required this.deleted,
  });

  factory HumanDto.fromJson(Map<String, Object?> json) {
    return HumanDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      shortName:
          (json['shortName'] as String?) ?? (json['name'] as String?) ?? '',
      seminarRole: _seminarRoleFromJson(json),
      procedureRoles: _procedureRolesFromJson(json),
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
      seminarRole: human.seminarRole,
      procedureRoles: human.procedureRoles,
      deleted: deleted,
    );
  }

  final int id;
  final String name;
  final String shortName;
  final SeminarRole seminarRole;
  final List<ProcedureRole> procedureRoles;
  final bool deleted;

  Human toDomain() {
    return Human(
      id: id.toString(),
      name: name,
      shortName: shortName,
      seminarRole: seminarRole,
      procedureRoles: procedureRoles,
    );
  }

  HumanDto copyWith({
    int? id,
    String? name,
    String? shortName,
    SeminarRole? seminarRole,
    Iterable<ProcedureRole>? procedureRoles,
    bool? deleted,
  }) {
    return HumanDto(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      seminarRole: seminarRole ?? this.seminarRole,
      procedureRoles: (procedureRoles ?? this.procedureRoles).toList(),
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'shortName': shortName,
      'seminarRole': seminarRole.name,
      'procedureRoles': procedureRoles.map((role) => role.name).toList(),
      'deleted': deleted,
    };
  }

  static SeminarRole _seminarRoleFromJson(Map<String, Object?> json) {
    final value = json['seminarRole'];
    if (value == SeminarRole.participant.name) return SeminarRole.participant;
    if (value == SeminarRole.assistant.name) return SeminarRole.assistant;
    return json['isAssistant'] == true
        ? SeminarRole.assistant
        : SeminarRole.participant;
  }

  static List<ProcedureRole> _procedureRolesFromJson(
    Map<String, Object?> json,
  ) {
    final values = json['procedureRoles'];
    if (values is List) {
      final roles = values
          .whereType<String>()
          .map((value) => switch (value) {
                'client' => ProcedureRole.client,
                'companion' => ProcedureRole.companion,
                _ => null,
              })
          .whereType<ProcedureRole>()
          .toList();
      if (roles.isNotEmpty) return roles;
    }
    return _seminarRoleFromJson(json) == SeminarRole.assistant
        ? const [ProcedureRole.client, ProcedureRole.companion]
        : const [ProcedureRole.client];
  }
}
