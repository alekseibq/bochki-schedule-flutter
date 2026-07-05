import 'dart:async';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import 'project_document_sync_part.dart';

final class ProjectDocumentSyncCoordinator {
  ProjectDocumentSyncCoordinator({
    required ProjectDocumentRepository repository,
    required ProjectDocument initialDocument,
    required AppLogger logger,
    this.debounceDuration = const Duration(milliseconds: 400),
  })  : _repository = repository,
        _lastPersistedDocument = initialDocument,
        _logger = logger;

  final ProjectDocumentRepository _repository;
  final AppLogger _logger;
  final Duration debounceDuration;
  final List<ProjectDocumentSyncPart> _parts = <ProjectDocumentSyncPart>[];

  ProjectDocument _lastPersistedDocument;
  Timer? _debounceTimer;
  Future<void>? _activeFlush;
  bool _flushQueued = false;
  bool _isShutdown = false;

  void registerPart(ProjectDocumentSyncPart part) {
    _parts.add(part);
  }

  void markChanged() {
    if (_isShutdown) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _flushDebounced);
  }

  Future<void> flushPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    return _queueFlush();
  }

  Future<void> shutdown() async {
    if (_isShutdown) {
      return _activeFlush ?? Future<void>.value();
    }

    _isShutdown = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _queueFlush();
  }

  void _flushDebounced() {
    unawaited(_flushDebouncedSafely());
  }

  Future<void> _flushDebouncedSafely() async {
    try {
      await _queueFlush();
    } catch (error, stackTrace) {
      await _logger.error(
        'Project document flush failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _queueFlush() {
    if (!_parts.any((part) => part.isDirty)) {
      return _activeFlush ?? Future<void>.value();
    }

    _flushQueued = true;
    final activeFlush = _activeFlush;
    if (activeFlush != null) {
      return activeFlush;
    }

    final flushFuture = _runFlushQueue();
    _activeFlush = flushFuture;
    return flushFuture;
  }

  Future<void> _runFlushQueue() async {
    try {
      while (_flushQueued) {
        _flushQueued = false;
        await _flushOnce();
      }
    } finally {
      _activeFlush = null;
    }
  }

  Future<void> _flushOnce() async {
    final snapshots = <_PartSnapshot>[
      for (final part in _parts)
        if (part.isDirty) _PartSnapshot(part: part, revision: part.revision),
    ];
    if (snapshots.isEmpty) {
      return;
    }

    var document = _lastPersistedDocument;
    for (final snapshot in snapshots) {
      document = snapshot.part.applyToDocument(document);
    }

    await _repository.save(document);
    _lastPersistedDocument = document;

    for (final snapshot in snapshots) {
      snapshot.part.markPersisted(snapshot.revision);
    }

    if (_parts.any((part) => part.isDirty)) {
      _flushQueued = true;
    }
  }
}

final class _PartSnapshot {
  const _PartSnapshot({
    required this.part,
    required this.revision,
  });

  final ProjectDocumentSyncPart part;
  final int revision;
}
