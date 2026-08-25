import '../named_directory/delete_named_directory_entry_use_case.dart';
import '../humans/humans_repository.dart';
import '../procedure_sessions/procedure_session_raw.dart';
import '../procedure_sessions/procedure_sessions_repository.dart';

import 'participant.dart';
import 'participants_repository.dart';
import 'participants_validation_exception.dart';

final class DeleteParticipantUseCase {
  DeleteParticipantUseCase(
    ParticipantsRepository repository, {
    HumansRepository? humansRepository,
    ProcedureSessionsRepository? procedureSessionsRepository,
  })  : _humansRepository = humansRepository,
        _procedureSessionsRepository = procedureSessionsRepository,
        _delegate = DeleteNamedDirectoryEntryUseCase<Participant>(
          repository,
          emptyIdMessage: 'Идентификатор участника не должен быть пустым.',
          exceptionFactory: _validationException,
        );

  final DeleteNamedDirectoryEntryUseCase<Participant> _delegate;
  final HumansRepository? _humansRepository;
  final ProcedureSessionsRepository? _procedureSessionsRepository;

  Future<int> countReferences(String participantId) async {
    final repository = _procedureSessionsRepository;
    if (repository == null) return 0;
    return _affectedSessions(await repository.list(), participantId).length;
  }

  Future<void> execute(String participantId) async {
    final sessionsRepository = _procedureSessionsRepository;
    final humansRepository = _humansRepository;
    if (sessionsRepository == null || humansRepository == null) {
      return _delegate.execute(participantId);
    }
    await _deleteHumanAndClearReferences(
      participantId,
      sessionsRepository: sessionsRepository,
      humansRepository: humansRepository,
    );
  }

  static List<ProcedureSessionRaw> _affectedSessions(
    List<ProcedureSessionRaw> sessions,
    String humanId,
  ) =>
      sessions
          .where((session) =>
              session.participantId == humanId ||
              session.assistantId == humanId)
          .toList(growable: false);

  static Future<void> _deleteHumanAndClearReferences(
    String humanId, {
    required ProcedureSessionsRepository sessionsRepository,
    required HumansRepository humansRepository,
  }) async {
    final current = _affectedSessions(await sessionsRepository.list(), humanId);
    final replacements = [
      for (final session in current)
        session.copyWith(
          clearParticipantId: session.participantId == humanId,
          clearAssistantId: session.assistantId == humanId,
        ),
    ];
    try {
      if (replacements.isNotEmpty) {
        await sessionsRepository.updateMany(replacements);
      }
      await humansRepository.delete(humanId);
    } catch (_) {
      if (replacements.isNotEmpty) {
        await sessionsRepository.updateMany(current);
      }
      rethrow;
    }
  }

  static ParticipantsValidationException _validationException(String message) {
    return ParticipantsValidationException(message);
  }
}
