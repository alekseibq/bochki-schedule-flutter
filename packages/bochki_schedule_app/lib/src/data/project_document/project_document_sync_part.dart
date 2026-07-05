import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

abstract interface class ProjectDocumentSyncPart {
  bool get isDirty;

  int get revision;

  ProjectDocument applyToDocument(ProjectDocument document);

  void markPersisted(int revision);
}

mixin DirtyTrackingProjectDocumentSyncPart implements ProjectDocumentSyncPart {
  int _revision = 0;
  int _persistedRevision = 0;

  @override
  bool get isDirty => _revision != _persistedRevision;

  @override
  int get revision => _revision;

  void markChanged() {
    _revision += 1;
  }

  @override
  void markPersisted(int revision) {
    if (_revision == revision) {
      _persistedRevision = revision;
    }
  }
}
