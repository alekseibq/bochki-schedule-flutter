import '../named_directory/delete_named_directory_entry_use_case.dart';
import '../humans/humans_repository.dart';
import '../procedure_sessions/procedure_session_raw.dart';
import '../procedure_sessions/procedure_sessions_repository.dart';

import 'assistant.dart';
import 'assistants_repository.dart';
import 'assistants_validation_exception.dart';

final class DeleteAssistantUseCase {
  DeleteAssistantUseCase(
    AssistantsRepository repository, {
    HumansRepository? humansRepository,
    ProcedureSessionsRepository? procedureSessionsRepository,
  })  : _humansRepository = humansRepository,
        _procedureSessionsRepository = procedureSessionsRepository,
        _delegate = DeleteNamedDirectoryEntryUseCase<Assistant>(
          repository,
          emptyIdMessage: 'Идентификатор ассистента не должен быть пустым.',
          exceptionFactory: _validationException,
        );

  final DeleteNamedDirectoryEntryUseCase<Assistant> _delegate;
  final HumansRepository? _humansRepository;
  final ProcedureSessionsRepository? _procedureSessionsRepository;

  Future<int> countReferences(String assistantId) async {
    final repository = _procedureSessionsRepository;
    if (repository == null) return 0;
    return _affectedSessions(await repository.list(), assistantId).length;
  }

  Future<void> execute(String assistantId) async {
    final sessionsRepository = _procedureSessionsRepository;
    final humansRepository = _humansRepository;
    if (sessionsRepository == null || humansRepository == null) {
      return _delegate.execute(assistantId);
    }
    final current =
        _affectedSessions(await sessionsRepository.list(), assistantId);
    final replacements = [
      for (final session in current)
        session.copyWith(
          clearParticipantId: session.participantId == assistantId,
          clearAssistantId: session.assistantId == assistantId,
        ),
    ];
    try {
      if (replacements.isNotEmpty) {
        await sessionsRepository.updateMany(replacements);
      }
      await humansRepository.delete(assistantId);
    } catch (_) {
      if (replacements.isNotEmpty) {
        await sessionsRepository.updateMany(current);
      }
      rethrow;
    }
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

  static AssistantsValidationException _validationException(String message) {
    return AssistantsValidationException(message);
  }
}
