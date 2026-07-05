import '../named_directory/named_directory_entry.dart';

import 'trainers_validation_exception.dart';

final class Trainer extends NamedDirectoryEntry {
  Trainer({
    required String id,
    required String name,
  }) : super(
          id: NamedDirectoryEntry.normalizeId(id),
          name: NamedDirectoryEntry.normalizeName(name),
        ) {
    if (this.id.isEmpty) {
      throw const TrainersValidationException(
        'Идентификатор тренера не должен быть пустым.',
      );
    }
    if (this.name.isEmpty) {
      throw const TrainersValidationException(
        'Введите имя тренера.',
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

  Trainer copyWith({
    String? id,
    String? name,
  }) {
    return Trainer(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
