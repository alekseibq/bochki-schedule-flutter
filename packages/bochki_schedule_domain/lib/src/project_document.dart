import 'schema_version.dart';
import 'program_settings.dart';

final class ProjectDocument {
  const ProjectDocument({
    this.schemaVersion = SchemaVersion.current,
    this.nextId = 1,
    this.humans = const [],
    this.procedureKinds = const [],
    this.workdays = const [],
    this.procedureSessions = const [],
    this.programSettings = ProgramSettings.defaults,
  })  : assert(schemaVersion > 0, 'schemaVersion must be positive'),
        assert(nextId > 0, 'nextId must be positive');

  final int schemaVersion;
  final int nextId;
  final List<Map<String, Object?>> humans;
  final List<Map<String, Object?>> procedureKinds;
  final List<Map<String, Object?>> workdays;
  final List<Map<String, Object?>> procedureSessions;
  final ProgramSettings programSettings;

  factory ProjectDocument.initial() {
    return const ProjectDocument();
  }

  factory ProjectDocument.fromJson(Map<String, Object?> json) {
    final decodedHumans = _decodeCollection(json['humans']);
    return ProjectDocument(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? SchemaVersion.current,
      nextId: (json['nextId'] as num?)?.toInt() ?? 1,
      humans: decodedHumans.isNotEmpty
          ? decodedHumans
          : _migrateLegacyHumans(
              participants: _decodeCollection(json['participants']),
              assistants: _decodeCollection(
                json['assistants'] ?? json['trainers'],
              ),
            ),
      procedureKinds: _decodeCollection(json['procedureKinds']),
      workdays: _decodeCollection(json['workdays']),
      procedureSessions: _decodeCollection(json['procedureSessions']),
      programSettings: json.containsKey('programSettings')
          ? ProgramSettings.fromJson(json['programSettings'])
          : ProgramSettings.defaults,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'nextId': nextId,
      'humans': humans,
      'procedureKinds': procedureKinds,
      'workdays': workdays,
      'procedureSessions': procedureSessions,
      'programSettings': programSettings.toJson(),
    };
  }

  ProjectDocument copyWith({
    int? schemaVersion,
    int? nextId,
    List<Map<String, Object?>>? humans,
    List<Map<String, Object?>>? procedureKinds,
    List<Map<String, Object?>>? workdays,
    List<Map<String, Object?>>? procedureSessions,
    ProgramSettings? programSettings,
  }) {
    return ProjectDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      nextId: nextId ?? this.nextId,
      humans: humans ?? this.humans,
      procedureKinds: procedureKinds ?? this.procedureKinds,
      workdays: workdays ?? this.workdays,
      procedureSessions: procedureSessions ?? this.procedureSessions,
      programSettings: programSettings ?? this.programSettings,
    );
  }

  static List<Map<String, Object?>> _decodeCollection(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) => <String, Object?>{
            for (final mapEntry in entry.entries)
              mapEntry.key.toString(): mapEntry.value,
          },
        )
        .toList(growable: false);
  }

  static List<Map<String, Object?>> _migrateLegacyHumans({
    required List<Map<String, Object?>> participants,
    required List<Map<String, Object?>> assistants,
  }) {
    if (participants.isEmpty && assistants.isEmpty) {
      return const [];
    }

    final mergedById = <String, Map<String, Object?>>{};

    for (final entry in assistants) {
      final normalized = _normalizeLegacyHuman(
        entry,
        isParticipant: false,
        isAssistant: true,
      );
      mergedById[normalized['id'].toString()] = normalized;
    }

    for (final entry in participants) {
      final normalized = _normalizeLegacyHuman(
        entry,
        isParticipant: true,
        isAssistant: false,
      );
      final id = normalized['id'].toString();
      final current = mergedById[id];
      if (current == null) {
        mergedById[id] = normalized;
        continue;
      }

      mergedById[id] = <String, Object?>{
        'id': normalized['id'] ?? current['id'] ?? 0,
        'name': normalized['name'] ?? current['name'] ?? '',
        'isParticipant': true,
        'isAssistant': _asBool(current['isAssistant']),
        'deleted':
            _asBool(current['deleted']) && _asBool(normalized['deleted']),
      };
    }

    final migrated = mergedById.values.toList(growable: false)
      ..sort((left, right) => _compareHumanNames(left, right));
    return migrated;
  }

  static Map<String, Object?> _normalizeLegacyHuman(
    Map<String, Object?> entry, {
    required bool isParticipant,
    required bool isAssistant,
  }) {
    return <String, Object?>{
      'id': (entry['id'] as num?)?.toInt() ?? 0,
      'name': (entry['name'] as String?) ?? '',
      'isParticipant': isParticipant,
      'isAssistant': isAssistant,
      'deleted': entry['deleted'] as bool? ?? false,
    };
  }

  static bool _asBool(Object? value) => value as bool? ?? false;

  static int _compareHumanNames(
    Map<String, Object?> left,
    Map<String, Object?> right,
  ) {
    final leftName = ((left['name'] as String?) ?? '').toLowerCase();
    final rightName = ((right['name'] as String?) ?? '').toLowerCase();
    final byName = leftName.compareTo(rightName);
    if (byName != 0) {
      return byName;
    }

    final leftId = (left['id'] as num?)?.toInt() ?? 0;
    final rightId = (right['id'] as num?)?.toInt() ?? 0;
    return leftId.compareTo(rightId);
  }
}
