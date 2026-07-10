import '../named_directory/named_directory_entry.dart';

final class Human extends NamedDirectoryEntry {
  Human({
    required String id,
    required String name,
    required this.isParticipant,
    required this.isAssistant,
  }) : super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        );

  final bool isParticipant;
  final bool isAssistant;

  Human copyWith({
    String? id,
    String? name,
    bool? isParticipant,
    bool? isAssistant,
  }) {
    return Human(
      id: id ?? this.id,
      name: name ?? this.name,
      isParticipant: isParticipant ?? this.isParticipant,
      isAssistant: isAssistant ?? this.isAssistant,
    );
  }
}
