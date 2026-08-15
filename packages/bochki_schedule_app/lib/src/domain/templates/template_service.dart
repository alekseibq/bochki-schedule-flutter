import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

final class TemplateService {
  TemplateService({
    required TemplateFileStore store,
    required ProjectDocumentRepository projectRepository,
    required Future<void> Function() flushPending,
  })  : _store = store,
        _projectRepository = projectRepository,
        _flushPending = flushPending;

  final TemplateFileStore _store;
  final ProjectDocumentRepository _projectRepository;
  final Future<void> Function() _flushPending;

  Future<List<TemplateFile>> list() => _store.list();
  String validateTitle(String value) => _store.validateTitle(value);
  Future<TemplateFile?> existing(String name) => _store.findExisting(name);

  Future<TemplateFile?> existingForTitle(String title) async {
    await _flushPending();
    final preview = _store.preview(
      title: title,
      document: await _projectRepository.load(),
    );
    return _store.findExisting(preview.file.path.split('/').last);
  }

  Future<TemplateFile> save(String title) async {
    await _flushPending();
    return _store.save(title: title, document: await _projectRepository.load());
  }

  Future<void> load(TemplateFile template) async {
    final document = await _store.read(template);
    await _flushPending();
    await _projectRepository.save(document);
  }

  Future<void> delete(TemplateFile template) => _store.delete(template);
}
