final class ProcedureKindPattern {
  const ProcedureKindPattern({
    required this.patternId,
    required this.name,
    required this.shortName,
    required this.longName,
  });

  final String patternId;
  final String name;
  final String shortName;
  final String longName;
}

abstract final class ProcedureKindPatterns {
  static const ProcedureKindPattern curated = ProcedureKindPattern(
    patternId: 'curated',
    name: 'Основная процедура',
    shortName: 'Основная',
    longName: 'Основная (ванна, бочка и т.д.)',
  );

  static const ProcedureKindPattern single = ProcedureKindPattern(
    patternId: 'single',
    name: 'Одиночная процедура',
    shortName: 'Одиночная',
    longName: 'Одиночная (бег, банный зал и т.д.)',
  );

  static const ProcedureKindPattern grouped = ProcedureKindPattern(
    patternId: 'grouped',
    name: 'Работа в группе',
    shortName: 'Групповая',
    longName: 'Групповая (медитация)',
  );

  static const List<ProcedureKindPattern> values = [
    curated,
    single,
    grouped,
  ];

  static ProcedureKindPattern? tryById(String patternId) {
    for (final pattern in values) {
      if (pattern.patternId == patternId) {
        return pattern;
      }
    }
    return null;
  }
}
