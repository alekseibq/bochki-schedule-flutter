import 'project_document.dart';

abstract interface class ProjectDocumentRepository {
  Future<ProjectDocument> load();

  Future<void> save(ProjectDocument document);
}
