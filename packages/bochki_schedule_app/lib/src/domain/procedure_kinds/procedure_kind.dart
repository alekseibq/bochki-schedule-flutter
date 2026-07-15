import '../named_directory/named_directory_entry.dart';

import 'procedure_kind_pattern.dart';
import 'procedure_kinds_validation_exception.dart';

final class ProcedureKind {
  ProcedureKind({
    required String id,
    required String patternId,
    required String name,
    required this.capacity,
    required this.participantBusyTime,
    this.assistantBusyTime,
    this.resourceBusyTime,
  })  : id = NamedDirectoryEntry.normalizeId(id),
        patternId = patternId.trim(),
        name = NamedDirectoryEntry.normalizeName(name) {
    if (this.id.isEmpty) {
      throw const ProcedureKindsValidationException(
        'Идентификатор вида процедуры не должен быть пустым.',
      );
    }
    if (ProcedureKindPatterns.tryById(this.patternId) == null) {
      throw const ProcedureKindsValidationException(
        'Выберите тип процедуры.',
      );
    }
    if (this.name.isEmpty) {
      throw const ProcedureKindsValidationException(
        'Введите название процедуры.',
      );
    }
  }

  final String id;
  final String patternId;
  final String name;
  final int capacity;
  final int participantBusyTime;
  final int? assistantBusyTime;
  final int? resourceBusyTime;

  ProcedureKindPattern get pattern => ProcedureKindPatterns.tryById(patternId)!;

  bool get isCurated => patternId == ProcedureKindPatterns.curated.patternId;

  bool get usesAssistant => assistantBusyTime != null;

  static String normalizeName(String value) {
    return NamedDirectoryEntry.normalizeName(value);
  }

  static String sortKeyForName(String value) {
    return NamedDirectoryEntry.sortKeyForName(value);
  }

  ProcedureKind sanitizedForPersistence() {
    if (isCurated) {
      return this;
    }

    return copyWith(
      resourceBusyTime: participantBusyTime,
      clearAssistantBusyTime: true,
    );
  }

  ProcedureKind copyWith({
    String? id,
    String? patternId,
    String? name,
    int? capacity,
    int? participantBusyTime,
    int? assistantBusyTime,
    bool clearAssistantBusyTime = false,
    int? resourceBusyTime,
    bool clearResourceBusyTime = false,
  }) {
    return ProcedureKind(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      participantBusyTime: participantBusyTime ?? this.participantBusyTime,
      assistantBusyTime: clearAssistantBusyTime
          ? null
          : assistantBusyTime ?? this.assistantBusyTime,
      resourceBusyTime: clearResourceBusyTime
          ? null
          : resourceBusyTime ?? this.resourceBusyTime,
    );
  }
}
