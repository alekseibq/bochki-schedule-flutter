import '../named_directory/named_directory_entry.dart';

final class Human extends NamedDirectoryEntry {
  Human({
    required String id,
    required String name,
    String? shortName,
    required this.isParticipant,
    required this.isAssistant,
  })  : shortName = _normalizeShortName(shortName, name),
        super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        );

  final String shortName;
  final bool isParticipant;
  final bool isAssistant;

  Human copyWith({
    String? id,
    String? name,
    String? shortName,
    bool? isParticipant,
    bool? isAssistant,
  }) {
    return Human(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      isParticipant: isParticipant ?? this.isParticipant,
      isAssistant: isAssistant ?? this.isAssistant,
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
