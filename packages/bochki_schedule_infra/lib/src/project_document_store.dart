import 'dart:convert';
import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'safe_file_writer.dart';

final class JsonProjectDocumentRepository implements ProjectDocumentRepository {
  JsonProjectDocumentRepository({
    required File projectFile,
    required SafeFileWriter safeFileWriter,
    JsonEncoder? encoder,
  })  : _projectFile = projectFile,
        _safeFileWriter = safeFileWriter,
        _encoder = encoder ?? const JsonEncoder.withIndent('  ');

  final File _projectFile;
  final SafeFileWriter _safeFileWriter;
  final JsonEncoder _encoder;

  @override
  Future<ProjectDocument> load() async {
    if (!await _projectFile.exists()) {
      return ProjectDocument.initial();
    }

    final raw = await _projectFile.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project document must be a JSON object.');
    }

    return ProjectDocument.fromJson(decoded);
  }

  @override
  Future<void> save(ProjectDocument document) {
    final serialized = _encoder.convert(document.toJson());
    return _safeFileWriter.writeString(_projectFile, serialized);
  }
}
