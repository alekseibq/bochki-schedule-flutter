import 'dart:io';

Directory? resolveAppDataDirectoryOverride(List<String> args) {
  const prefix = '--app-data-dir=';
  for (var index = 0; index < args.length; index += 1) {
    final arg = args[index];
    if (arg.startsWith(prefix)) {
      final value = arg.substring(prefix.length);
      if (value.isEmpty) {
        throw ArgumentError.value(arg, 'args', 'Missing app data directory');
      }
      return Directory(value);
    }

    if (arg == '--app-data-dir') {
      final nextIndex = index + 1;
      if (nextIndex >= args.length) {
        throw ArgumentError.value(arg, 'args', 'Missing app data directory');
      }

      final value = args[nextIndex];
      if (value.startsWith('--')) {
        throw ArgumentError.value(arg, 'args', 'Missing app data directory');
      }

      return Directory(value);
    }
  }

  return null;
}
