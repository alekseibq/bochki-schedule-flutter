import 'dart:async';

import 'package:bochki_schedule_app/src/data/project_document/project_document_sync_coordinator.dart';
import 'package:bochki_schedule_app/src/data/project_document/project_document_sync_part.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debounces multiple changes into a single save', () async {
    final repository = _RecordingProjectDocumentRepository();
    final coordinator = ProjectDocumentSyncCoordinator(
      repository: repository,
      initialDocument: ProjectDocument.initial(),
      logger: const _NoopLogger(),
      debounceDuration: const Duration(milliseconds: 40),
    );
    final part = _MutableSyncPart(
      apply: (document, revision) => document.copyWith(
        humans: [
          <String, Object?>{
            'id': revision,
            'name': 'P$revision',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': false,
          },
        ],
      ),
    );
    coordinator.registerPart(part);

    part.bumpRevision();
    coordinator.markChanged();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    part.bumpRevision();
    coordinator.markChanged();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    part.bumpRevision();
    coordinator.markChanged();

    expect(repository.savedDocuments, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(repository.savedDocuments, hasLength(1));
    expect(repository.savedDocuments.single.humans.single['id'], 3);
    expect(part.isDirty, isFalse);
  });

  test('flushPending writes immediately and preserves untouched sections',
      () async {
    final repository = _RecordingProjectDocumentRepository();
    final coordinator = ProjectDocumentSyncCoordinator(
      repository: repository,
      initialDocument: const ProjectDocument(
        nextId: 4,
        humans: <Map<String, Object?>>[
          <String, Object?>{
            'id': 7,
            'name': 'Assistant One',
            'isParticipant': false,
            'isAssistant': true,
            'deleted': false,
          },
        ],
      ),
      logger: const _NoopLogger(),
      debounceDuration: const Duration(milliseconds: 400),
    );
    final part = _MutableSyncPart(
      apply: (document, revision) => document.copyWith(
        humans: [
          ...document.humans,
          <String, Object?>{
            'id': revision,
            'name': 'Participant',
            'isParticipant': true,
            'isAssistant': false,
            'deleted': false,
          },
        ],
      ),
    );
    coordinator.registerPart(part);

    part.bumpRevision();
    await coordinator.flushPending();

    expect(repository.savedDocuments, hasLength(1));
    expect(
        repository.savedDocuments.single.humans.first['name'], 'Assistant One');
    expect(repository.savedDocuments.single.humans.last['name'], 'Participant');
    expect(part.isDirty, isFalse);
  });

  test('keeps section dirty when it changes during active save', () async {
    final saveStarted = Completer<void>();
    final releaseSave = Completer<void>();
    final repository = _RecordingProjectDocumentRepository(
      onSave: (document) async {
        if (!saveStarted.isCompleted) {
          saveStarted.complete();
          await releaseSave.future;
        }
      },
    );
    final coordinator = ProjectDocumentSyncCoordinator(
      repository: repository,
      initialDocument: ProjectDocument.initial(),
      logger: const _NoopLogger(),
      debounceDuration: Duration.zero,
    );
    final part = _MutableSyncPart(
      apply: (document, revision) => document.copyWith(
        nextId: revision + 1,
      ),
    );
    coordinator.registerPart(part);

    part.bumpRevision();
    final firstFlush = coordinator.flushPending();
    await saveStarted.future;

    part.bumpRevision();
    final secondFlush = coordinator.flushPending();
    releaseSave.complete();

    await firstFlush;
    await secondFlush;

    expect(repository.savedDocuments, hasLength(2));
    expect(repository.savedDocuments.last.nextId, 3);
    expect(part.isDirty, isFalse);
  });
}

final class _MutableSyncPart
    with DirtyTrackingProjectDocumentSyncPart
    implements ProjectDocumentSyncPart {
  _MutableSyncPart({
    required ProjectDocument Function(ProjectDocument document, int revision)
        apply,
  }) : _apply = apply;

  final ProjectDocument Function(ProjectDocument document, int revision) _apply;

  @override
  ProjectDocument applyToDocument(ProjectDocument document) {
    return _apply(document, revision);
  }

  void bumpRevision() {
    super.markChanged();
  }
}

final class _RecordingProjectDocumentRepository
    implements ProjectDocumentRepository {
  _RecordingProjectDocumentRepository({
    Future<void> Function(ProjectDocument document)? onSave,
  }) : _onSave = onSave;

  final Future<void> Function(ProjectDocument document)? _onSave;
  final List<ProjectDocument> savedDocuments = <ProjectDocument>[];

  @override
  Future<ProjectDocument> load() async {
    return ProjectDocument.initial();
  }

  @override
  Future<void> save(ProjectDocument document) async {
    savedDocuments.add(document);
    await _onSave?.call(document);
  }
}

final class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {}

  @override
  Future<void> info(String message) async {}
}
