import 'schema_version.dart';

final class ProjectDocument {
  const ProjectDocument({
    this.schemaVersion = SchemaVersion.current,
    this.nextId = 1,
    this.trainers = const [],
    this.participants = const [],
  })  : assert(schemaVersion > 0, 'schemaVersion must be positive'),
        assert(nextId > 0, 'nextId must be positive');

  final int schemaVersion;
  final int nextId;
  final List<Map<String, Object?>> trainers;
  final List<Map<String, Object?>> participants;

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
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'nextId': nextId,
      'trainers': trainers,
      'participants': participants,
    };
  }

  ProjectDocument copyWith({
    int? schemaVersion,
    int? nextId,
    List<Map<String, Object?>>? trainers,
    List<Map<String, Object?>>? participants,
  }) {
    return ProjectDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      nextId: nextId ?? this.nextId,
      trainers: trainers ?? this.trainers,
      participants: participants ?? this.participants,
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
