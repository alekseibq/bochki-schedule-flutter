import '../named_directory/named_directory_entry.dart';

import 'assistants_validation_exception.dart';

final class Assistant extends NamedDirectoryEntry {
  Assistant({
    required String id,
    required String name,
  }) : super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        ) {
    if (this.id.isEmpty) {
      throw const AssistantsValidationException(
        'Идентификатор ассистента не должен быть пустым.',
      );
    }
    if (this.name.isEmpty) {
      throw const AssistantsValidationException(
        'Введите имя ассистента.',
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

  Assistant copyWith({
    String? id,
    String? name,
  }) {
    return Assistant(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
