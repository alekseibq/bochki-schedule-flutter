import 'procedure_kind.dart';
import 'procedure_kind_pattern.dart';
import 'procedure_kinds_validation_exception.dart';

abstract final class ProcedureKindValidator {
  static ProcedureKind validateForSave(
    ProcedureKind procedureKind, {
    required Iterable<ProcedureKind> existingProcedureKinds,
  }) {
    final normalizedName = ProcedureKind.normalizeName(procedureKind.name);
    if (normalizedName.isEmpty) {
      throw const ProcedureKindsValidationException(
        'Введите название процедуры.',
      );
    }

    final normalizedCandidate = ProcedureKind.sortKeyForName(normalizedName);
    final hasDuplicate = existingProcedureKinds.any(
      (existingProcedureKind) =>
          existingProcedureKind.id != procedureKind.id &&
          ProcedureKind.sortKeyForName(existingProcedureKind.name) ==
              normalizedCandidate,
    );
    if (hasDuplicate) {
      throw const ProcedureKindsValidationException(
        'Вид процедуры с таким названием уже есть.',
      );
    }

    _validateRequiredRange(
      value: procedureKind.capacity,
      emptyMessage: 'Укажите емкость.',
      rangeMessage: 'Емкость должна быть от 1 до 999.',
    );
    _validateRequiredRange(
      value: procedureKind.participantBusyTime,
      emptyMessage: 'Укажите время участника.',
      rangeMessage: 'Время участника должно быть от 1 до 999 минут.',
    );

    if (procedureKind.patternId == ProcedureKindPatterns.curated.patternId) {
      _validateOptionalRange(
        value: procedureKind.assistantBusyTime,
        rangeMessage: 'Время ассистента должно быть от 1 до 999 минут.',
      );
      _validateOptionalRange(
        value: procedureKind.resourceBusyTime,
        rangeMessage: 'Время ресурса должно быть от 1 до 999 минут.',
      );
      return procedureKind.copyWith(name: normalizedName);
    }

    return procedureKind
        .copyWith(name: normalizedName)
        .sanitizedForPersistence();
  }

  static void validateId(String procedureKindId) {
    if (procedureKindId.trim().isEmpty) {
      throw const ProcedureKindsValidationException(
        'Идентификатор вида процедуры не должен быть пустым.',
      );
    }
  }

  static void _validateRequiredRange({
    required int value,
    required String emptyMessage,
    required String rangeMessage,
  }) {
    if (value <= 0) {
      throw ProcedureKindsValidationException(emptyMessage);
    }
    if (value < 1 || value > 999) {
      throw ProcedureKindsValidationException(rangeMessage);
    }
  }

  static void _validateOptionalRange({
    required int? value,
    required String rangeMessage,
  }) {
    if (value == null) {
      return;
    }
    if (value < 1 || value > 999) {
      throw ProcedureKindsValidationException(rangeMessage);
    }
  }
}
