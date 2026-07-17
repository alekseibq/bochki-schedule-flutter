import 'dart:io';

import 'package:path/path.dart' as p;

abstract interface class SafeFileWriter {
  Future<void> writeString(File destination, String contents);

  Future<void> writeBytes(File destination, List<int> contents);
}

final class AtomicFileWriter implements SafeFileWriter {
  const AtomicFileWriter();

  @override
  Future<void> writeString(File destination, String contents) async {
    await _write(
      destination,
      (tempFile) => tempFile.writeAsString(contents, flush: true),
    );
  }

  @override
  Future<void> writeBytes(File destination, List<int> contents) async {
    await _write(
      destination,
      (tempFile) => tempFile.writeAsBytes(contents, flush: true),
    );
  }

  Future<void> _write(
    File destination,
    Future<void> Function(File tempFile) writeContents,
  ) async {
    await destination.parent.create(recursive: true);
    final tempFile = File(
      p.join(
        destination.parent.path,
        '.${p.basename(destination.path)}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );

    try {
      await writeContents(tempFile);
      if (await destination.exists()) {
        await destination.delete();
      }
      await tempFile.rename(destination.path);
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
