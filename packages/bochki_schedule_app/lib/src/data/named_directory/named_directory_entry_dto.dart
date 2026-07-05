import '../../domain/named_directory/named_directory_entry.dart';

typedef NamedDirectoryEntryFactory<T extends NamedDirectoryEntry> = T Function({
  required String id,
  required String name,
});

final class NamedDirectoryEntryDto {
  const NamedDirectoryEntryDto({
    required this.id,
    required this.name,
    required this.deleted,
  });

  factory NamedDirectoryEntryDto.fromJson(Map<String, Object?> json) {
    return NamedDirectoryEntryDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  factory NamedDirectoryEntryDto.fromDomain(
    NamedDirectoryEntry entry, {
    required bool deleted,
  }) {
    return NamedDirectoryEntryDto(
      id: int.parse(entry.id),
      name: entry.name,
      deleted: deleted,
    );
  }

  final int id;
  final String name;
  final bool deleted;

  T toDomain<T extends NamedDirectoryEntry>(
    NamedDirectoryEntryFactory<T> entryFactory,
  ) {
    return entryFactory(
      id: id.toString(),
      name: name,
    );
  }

  NamedDirectoryEntryDto copyWith({
    int? id,
    String? name,
    bool? deleted,
  }) {
    return NamedDirectoryEntryDto(
      id: id ?? this.id,
      name: name ?? this.name,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'deleted': deleted,
    };
  }
}
