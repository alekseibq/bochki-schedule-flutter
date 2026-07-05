class NamedDirectoryEntry {
  const NamedDirectoryEntry({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static String normalizeId(String value) {
    return value.trim();
  }

  static String normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String sortKeyForName(String value) {
    return normalizeName(value).toLowerCase();
  }
}
