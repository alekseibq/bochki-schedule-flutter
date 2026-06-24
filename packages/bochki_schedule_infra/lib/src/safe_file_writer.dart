import 'dart:io';

import 'package:path/path.dart' as p;

abstract interface class SafeFileWriter {
  Future<void> writeString(File destination, String contents);
}

final class AtomicFileWriter implements SafeFileWriter {
  const AtomicFileWriter();

  @override
  Future<void> writeString(File destination, String contents) async {
    await destination.parent.create(recursive: true);
    final tempFile = File(
      p.join(
        destination.parent.path,
        '.${p.basename(destination.path)}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );

    try {
      await tempFile.writeAsString(contents, flush: true);
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
