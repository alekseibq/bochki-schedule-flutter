import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/trainers/trainer.dart';
import '../../domain/trainers/trainers_repository.dart';
import '../named_directory/project_document_named_directory_repository.dart';

final class ProjectDocumentTrainersRepository
    extends ProjectDocumentNamedDirectoryRepository<Trainer>
    implements TrainersRepository {
  ProjectDocumentTrainersRepository({
    required ProjectDocument initialDocument,
    required super.idAllocator,
    required super.onChanged,
  }) : super(
          initialEntries: initialDocument.trainers,
          entryFactory: _entryFactory,
          collectionWriter: _collectionWriter,
        );

  static Trainer _entryFactory({
    required String id,
    required String name,
  }) {
    return Trainer(
      id: id,
      name: name,
    );
  }

  static ProjectDocument _collectionWriter(
    ProjectDocument document,
    List<Map<String, Object?>> entries,
  ) {
    return document.copyWith(trainers: entries);
  }
}
