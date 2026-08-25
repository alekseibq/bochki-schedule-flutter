import '../named_directory/named_directory_entry.dart';

enum SeminarRole { participant, assistant }

enum ProcedureRole { client, companion }

final class Human extends NamedDirectoryEntry {
  Human({
    required String id,
    required String name,
    String? shortName,
    SeminarRole? seminarRole,
    Iterable<ProcedureRole>? procedureRoles,
    bool? isParticipant,
    bool? isAssistant,
  })  : shortName = _normalizeShortName(shortName, name),
        seminarRole = seminarRole ??
            (isAssistant == true
                ? SeminarRole.assistant
                : SeminarRole.participant),
        procedureRoles = List.unmodifiable(
          (procedureRoles ??
                  ((seminarRole ??
                              (isAssistant == true
                                  ? SeminarRole.assistant
                                  : SeminarRole.participant)) ==
                          SeminarRole.assistant
                      ? const [ProcedureRole.client, ProcedureRole.companion]
                      : const [ProcedureRole.client]))
              .toSet(),
        ),
        super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        );

  final String shortName;
  final SeminarRole seminarRole;
  final List<ProcedureRole> procedureRoles;

  bool get isParticipant => seminarRole == SeminarRole.participant;
  bool get isAssistant => seminarRole == SeminarRole.assistant;
  bool hasProcedureRole(ProcedureRole role) => procedureRoles.contains(role);

  Human copyWith({
    String? id,
    String? name,
    String? shortName,
    SeminarRole? seminarRole,
    Iterable<ProcedureRole>? procedureRoles,
    bool? isParticipant,
    bool? isAssistant,
  }) {
    return Human(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      seminarRole: seminarRole ??
          (isAssistant == true
              ? SeminarRole.assistant
              : isParticipant == true
                  ? SeminarRole.participant
                  : this.seminarRole),
      procedureRoles: procedureRoles ?? this.procedureRoles,
    );
  }

  static String _normalizeShortName(String? value, String name) {
    final normalizedName = NamedDirectoryEntry.normalizeName(name);
    final normalizedShortName = (value ?? '').trim();
    return normalizedShortName.isEmpty || normalizedShortName == normalizedName
        ? normalizedName
        : normalizedShortName;
  }
}
