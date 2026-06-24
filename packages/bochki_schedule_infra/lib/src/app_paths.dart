import 'dart:io';

import 'package:path/path.dart' as p;

abstract interface class AppDataDirectoryProvider {
  Future<Directory> getAppDataDirectory();
}

final class PlatformAppDataDirectoryProvider
    implements AppDataDirectoryProvider {
  PlatformAppDataDirectoryProvider({
    required this.appDirectoryName,
    Map<String, String>? environment,
    String? operatingSystem,
  })  : _environment = environment ?? Platform.environment,
        _operatingSystem = operatingSystem ?? Platform.operatingSystem;

  final String appDirectoryName;
  final Map<String, String> _environment;
  final String _operatingSystem;

  @override
  Future<Directory> getAppDataDirectory() async {
    final baseDirectoryPath = _resolveBaseDirectoryPath();
    final directory = Directory(p.join(baseDirectoryPath, appDirectoryName));
    await directory.create(recursive: true);
    return directory;
  }

  String _resolveBaseDirectoryPath() {
    switch (_operatingSystem) {
      case 'windows':
        final appData = _environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          return appData;
        }

        return p.join(
            _requiredEnvironmentValue('USERPROFILE'), 'AppData', 'Roaming');
      case 'macos':
        return p.join(
          _requiredEnvironmentValue('HOME'),
          'Library',
          'Application Support',
        );
      default:
        final xdgDataHome = _environment['XDG_DATA_HOME'];
        if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
          return xdgDataHome;
        }

        return p.join(_requiredEnvironmentValue('HOME'), '.local', 'share');
    }
  }

  String _requiredEnvironmentValue(String key) {
    final value = _environment[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }

    return value;
  }
}
