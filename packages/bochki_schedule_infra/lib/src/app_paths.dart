import 'dart:io';

import 'package:path/path.dart' as p;

abstract interface class AppDataDirectoryProvider {
  Future<Directory> getAppDataDirectory();
}

String resolveLaunchAppDataDirectoryPath({
  required String resolvedExecutable,
  required String operatingSystem,
}) {
  final pathContext = p.Context(
      style: operatingSystem == 'windows' ? p.Style.windows : p.Style.posix);
  final executableDirectory = pathContext.dirname(resolvedExecutable);

  if (operatingSystem == 'macos') {
    final contentsDirectory = pathContext.dirname(executableDirectory);
    final bundleDirectory = pathContext.dirname(contentsDirectory);
    if (pathContext.basename(bundleDirectory).endsWith('.app')) {
      return pathContext.dirname(bundleDirectory);
    }
  }

  return executableDirectory;
}

final class LaunchAppDataDirectoryProvider implements AppDataDirectoryProvider {
  LaunchAppDataDirectoryProvider({
    String? resolvedExecutable,
    String? operatingSystem,
  })  : _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable,
        _operatingSystem = operatingSystem ?? Platform.operatingSystem;

  final String _resolvedExecutable;
  final String _operatingSystem;

  @override
  Future<Directory> getAppDataDirectory() async {
    final baseDirectoryPath = resolveLaunchAppDataDirectoryPath(
      resolvedExecutable: _resolvedExecutable,
      operatingSystem: _operatingSystem,
    );
    final directory = Directory(baseDirectoryPath);
    await directory.create(recursive: true);
    return directory;
  }
}
