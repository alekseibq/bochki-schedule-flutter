import 'schema_version.dart';

final class ProjectDocument {
  const ProjectDocument({
    this.schemaVersion = SchemaVersion.current,
    this.nextId = 1,
    this.trainers = const [],
    this.participants = const [],
    this.procedureKinds = const [],
    this.workdays = const [],
  })  : assert(schemaVersion > 0, 'schemaVersion must be positive'),
        assert(nextId > 0, 'nextId must be positive');

  final int schemaVersion;
  final int nextId;
  final List<Map<String, Object?>> trainers;
  final List<Map<String, Object?>> participants;
  final List<Map<String, Object?>> procedureKinds;
  final List<Map<String, Object?>> workdays;

  factory ProjectDocument.initial() {
    return const ProjectDocument();
  }

  factory ProjectDocument.fromJson(Map<String, Object?> json) {
    return ProjectDocument(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? SchemaVersion.current,
      nextId: (json['nextId'] as num?)?.toInt() ?? 1,
      trainers: _decodeCollection(json['trainers']),
      participants: _decodeCollection(json['participants']),
      procedureKinds: _decodeCollection(json['procedureKinds']),
      workdays: _decodeCollection(json['workdays']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'nextId': nextId,
      'trainers': trainers,
      'participants': participants,
      'procedureKinds': procedureKinds,
      'workdays': workdays,
    };
  }

  ProjectDocument copyWith({
    int? schemaVersion,
    int? nextId,
    List<Map<String, Object?>>? trainers,
    List<Map<String, Object?>>? participants,
    List<Map<String, Object?>>? procedureKinds,
    List<Map<String, Object?>>? workdays,
  }) {
    return ProjectDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      nextId: nextId ?? this.nextId,
      trainers: trainers ?? this.trainers,
      participants: participants ?? this.participants,
      procedureKinds: procedureKinds ?? this.procedureKinds,
      workdays: workdays ?? this.workdays,
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
}
