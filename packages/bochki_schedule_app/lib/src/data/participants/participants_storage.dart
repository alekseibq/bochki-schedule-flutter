import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

abstract interface class ParticipantsStorage {
  Future<ProjectDocument> loadDocument();

  Future<void> saveDocument(ProjectDocument document);
}

final class ProjectDocumentParticipantsStorage implements ParticipantsStorage {
  const ProjectDocumentParticipantsStorage(this._repository);

  final ProjectDocumentRepository _repository;

  @override
  Future<ProjectDocument> loadDocument() {
    return _repository.load();
  }

  @override
  Future<void> saveDocument(ProjectDocument document) {
    return _repository.save(document);
  }
}
