import 'dart:convert';
import 'dart:io';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:path/path.dart' as p;

import 'safe_file_writer.dart';

final class TemplateFile {
  const TemplateFile({
    required this.file,
    required this.title,
    required this.workdays,
    required this.participants,
    required this.assistants,
  });

  final File file;
  final String title;
  final int workdays;
  final int participants;
  final int assistants;

  String get displayName => p.basenameWithoutExtension(file.path);
}

final class TemplateFileStore {
  TemplateFileStore({
    required Directory appDataDirectory,
    required SafeFileWriter safeFileWriter,
  })  : _directory = Directory(p.join(appDataDirectory.path, 'saved-patterns')),
        _safeFileWriter = safeFileWriter;

  static final RegExp _nameExpression = RegExp(
    r'^(.+) -- ([0-9]+)-([0-9]+)-([0-9]+)\.json$',
  );
  static final RegExp _invalidTitleCharacters =
      RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  final Directory _directory;
  final SafeFileWriter _safeFileWriter;

  Future<List<TemplateFile>> list() async {
    if (!await _directory.exists()) return const [];
    final templates = <TemplateFile>[];
    await for (final entity in _directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final parsed = _parse(p.basename(entity.path));
      if (parsed != null) templates.add(parsed.withFile(entity));
    }
    templates.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return templates;
  }

  String validateTitle(String value) {
    final title = value.trim();
    if (title.isEmpty) return 'Введите название шаблона.';
    if (title.contains(' -- ')) return 'Название не должно содержать « -- ».';
    if (_invalidTitleCharacters.hasMatch(title))
      return 'Название содержит недопустимые символы.';
    return '';
  }

  Future<TemplateFile?> findExisting(String fileName) async {
    final normalized = p.basename(fileName).toLowerCase();
    for (final template in await list()) {
      if (p.basename(template.file.path).toLowerCase() == normalized)
        return template;
    }
    return null;
  }

  Future<TemplateFile> save(
      {required String title, required ProjectDocument document}) async {
    final error = validateTitle(title);
    if (error.isNotEmpty) throw FormatException(error);
    final template = _fromDocument(title.trim(), document);
    final contents =
        const JsonEncoder.withIndent('  ').convert(document.toJson());
    await _safeFileWriter.writeString(template.file, contents);
    return template;
  }

  TemplateFile preview(
      {required String title, required ProjectDocument document}) {
    final error = validateTitle(title);
    if (error.isNotEmpty) throw FormatException(error);
    return _fromDocument(title.trim(), document);
  }

  Future<ProjectDocument> read(TemplateFile template) async {
    final decoded = jsonDecode(await template.file.readAsString());
    if (decoded is! Map)
      throw const FormatException('Файл шаблона должен содержать JSON-объект.');
    final json = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value
    };
    final version =
        (json['schemaVersion'] as num?)?.toInt() ?? SchemaVersion.current;
    if (version > SchemaVersion.current) {
      throw FormatException(
          'Шаблон создан более новой версией приложения (схема $version).');
    }
    return ProjectDocument.fromJson(json);
  }

  Future<void> delete(TemplateFile template) => template.file.delete();

  TemplateFile _fromDocument(String title, ProjectDocument document) {
    final workdays = _active(document.workdays).length;
    final humans = _active(document.humans);
    final participants =
        humans
            .where((entry) =>
                entry['seminarRole'] == 'participant' ||
                (entry['seminarRole'] == null &&
                    entry['isParticipant'] == true &&
                    entry['isAssistant'] != true))
            .length;
    final assistants =
        humans
            .where((entry) =>
                entry['seminarRole'] == 'assistant' || entry['isAssistant'] == true)
            .length;
    final name = '$title -- $workdays-$participants-$assistants.json';
    return TemplateFile(
        file: File(p.join(_directory.path, name)),
        title: title,
        workdays: workdays,
        participants: participants,
        assistants: assistants);
  }

  static List<Map<String, Object?>> _active(
          List<Map<String, Object?>> values) =>
      values.where((entry) => entry['deleted'] != true).toList(growable: false);

  static _ParsedTemplate? _parse(String name) {
    final match = _nameExpression.firstMatch(name);
    if (match == null) return null;
    return _ParsedTemplate(match.group(1)!, int.parse(match.group(2)!),
        int.parse(match.group(3)!), int.parse(match.group(4)!));
  }
}

final class _ParsedTemplate {
  const _ParsedTemplate(
      this.title, this.workdays, this.participants, this.assistants);
  final String title;
  final int workdays;
  final int participants;
  final int assistants;
  TemplateFile withFile(File file) => TemplateFile(
      file: file,
      title: title,
      workdays: workdays,
      participants: participants,
      assistants: assistants);
}
