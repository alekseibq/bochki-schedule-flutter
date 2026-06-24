import 'dart:convert';
import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'safe_file_writer.dart';

abstract interface class ProjectDocumentStore {
  Future<ProjectDocument?> read(File file);

  Future<void> write(File file, ProjectDocument document);
}

final class JsonProjectDocumentStore implements ProjectDocumentStore {
  JsonProjectDocumentStore({
    required SafeFileWriter safeFileWriter,
    JsonEncoder? encoder,
  })  : _safeFileWriter = safeFileWriter,
        _encoder = encoder ?? const JsonEncoder.withIndent('  ');

  final SafeFileWriter _safeFileWriter;
  final JsonEncoder _encoder;

  @override
  Future<ProjectDocument?> read(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project document must be a JSON object.');
    }

    return ProjectDocument.fromJson(decoded);
  }

  @override
  Future<void> write(File file, ProjectDocument document) {
    final serialized = _encoder.convert(document.toJson());
    return _safeFileWriter.writeString(file, serialized);
  }
}
