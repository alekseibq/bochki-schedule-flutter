import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/participants/participant.dart';
import '../../domain/participants/participants_repository.dart';
import '../named_directory/project_document_named_directory_repository.dart';

final class ProjectDocumentParticipantsRepository
    extends ProjectDocumentNamedDirectoryRepository<Participant>
    implements ParticipantsRepository {
  ProjectDocumentParticipantsRepository({
    required ProjectDocument initialDocument,
    required super.idAllocator,
    required super.onChanged,
  }) : super(
          initialEntries: initialDocument.participants,
          entryFactory: _entryFactory,
          collectionWriter: _collectionWriter,
        );

  static Participant _entryFactory({
    required String id,
    required String name,
  }) {
    return Participant(
      id: id,
      name: name,
    );
  }

  static ProjectDocument _collectionWriter(
    ProjectDocument document,
    List<Map<String, Object?>> entries,
  ) {
    return document.copyWith(participants: entries);
  }
}
