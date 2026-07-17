import 'dart:io';

import '../../domain/print_schedule/document_opener.dart';

final class ProcessDocumentOpener implements DocumentOpener {
  const ProcessDocumentOpener();

  @override
  Future<void> open(File file) async {
    ProcessResult result;
    if (Platform.isMacOS) {
      result = await Process.run('open', [file.path]);
    } else if (Platform.isWindows) {
      result = await Process.run(
        'cmd',
        ['/c', 'start', '', file.path],
        runInShell: true,
      );
    } else if (Platform.isLinux) {
      result = await Process.run('xdg-open', [file.path]);
    } else {
      throw UnsupportedError(
        'Unsupported platform for opening documents: ${Platform.operatingSystem}',
      );
    }

    if (result.exitCode != 0) {
      throw ProcessException(
        Platform.operatingSystem,
        const <String>[],
        result.stderr?.toString() ?? 'Failed to open ${file.path}',
        result.exitCode,
      );
    }
  }
}
