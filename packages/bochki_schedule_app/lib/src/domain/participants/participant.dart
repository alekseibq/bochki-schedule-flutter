import 'participants_validation_exception.dart';

final class Participant {
  Participant({
    required String id,
    required String name,
  })  : id = _normalizeId(id),
        name = _normalizeName(name) {
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

  final String id;
  final String name;

  static String normalizeId(String value) {
    return _normalizeId(value);
  }

  static String normalizeName(String value) {
    return _normalizeName(value);
  }

  static String sortKeyForName(String value) {
    return _normalizeName(value).toLowerCase();
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

  static String _normalizeId(String value) {
    return value.trim();
  }

  static String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
