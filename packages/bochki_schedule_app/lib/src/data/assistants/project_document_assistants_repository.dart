import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/assistants/assistant.dart';
import '../../domain/assistants/assistants_repository.dart';
import '../named_directory/project_document_named_directory_repository.dart';

final class ProjectDocumentAssistantsRepository
    extends ProjectDocumentNamedDirectoryRepository<Assistant>
    implements AssistantsRepository {
  ProjectDocumentAssistantsRepository({
    required ProjectDocument initialDocument,
    required super.idAllocator,
    required super.onChanged,
  }) : super(
          initialEntries: initialDocument.assistants,
          entryFactory: _entryFactory,
          collectionWriter: _collectionWriter,
        );

  static Assistant _entryFactory({
    required String id,
    required String name,
  }) {
    return Assistant(
      id: id,
      name: name,
    );
  }

  static ProjectDocument _collectionWriter(
    ProjectDocument document,
    List<Map<String, Object?>> entries,
  ) {
    return document.copyWith(assistants: entries);
  }
}
