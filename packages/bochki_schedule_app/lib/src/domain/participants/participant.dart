import '../named_directory/named_directory_entry.dart';

import 'participants_validation_exception.dart';

final class Participant extends NamedDirectoryEntry {
  Participant({
    required String id,
    required String name,
  }) : super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        ) {
    if (this.id.isEmpty) {
      throw const ParticipantsValidationException(
        'Идентификатор участника не должен быть пустым.',
      );
    }
    if (this.name.isEmpty) {
      throw const ParticipantsValidationException(
        'Введите имя участника.',
      );
    }
  }

  static String normalizeId(String value) {
    return NamedDirectoryEntry.normalizeId(value);
  }

  static String normalizeName(String value) {
    return NamedDirectoryEntry.normalizeName(value);
  }

  static String sortKeyForName(String value) {
    return NamedDirectoryEntry.sortKeyForName(value);
  }

  Participant copyWith({
    String? id,
    String? name,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
