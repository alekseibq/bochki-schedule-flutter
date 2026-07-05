import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import 'project_document_sync_part.dart';

final class ProjectDocumentIdAllocator
    with DirtyTrackingProjectDocumentSyncPart
    implements ProjectDocumentSyncPart {
  ProjectDocumentIdAllocator({
    required int nextId,
    required void Function() onChanged,
  })  : _generator = SequentialIdGenerator(startAt: nextId),
        _onChanged = onChanged;

  final SequentialIdGenerator _generator;
  final void Function() _onChanged;

  int nextId() {
    final nextId = _generator.nextId();
    markChanged();
    _onChanged();
    return nextId;
  }

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return document.copyWith(nextId: _generator.currentValue + 1);
  }
}
