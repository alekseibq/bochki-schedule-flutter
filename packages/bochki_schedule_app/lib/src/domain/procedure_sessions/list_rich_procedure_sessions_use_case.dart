import '../assistants/list_assistants_use_case.dart';
import '../humans/list_humans_use_case.dart';
import '../procedure_kinds/list_procedure_kinds_use_case.dart';
import '../workdays/list_workdays_use_case.dart';

import 'list_procedure_sessions_use_case.dart';
import 'procedure_session_rich.dart';
import 'procedure_session_rich_factory.dart';

final class ListRichProcedureSessionsUseCase {
  ListRichProcedureSessionsUseCase({
    required ListProcedureSessionsUseCase listProcedureSessionsUseCase,
    required ListWorkdaysUseCase listWorkdaysUseCase,
    required ListHumansUseCase listHumansUseCase,
    required ListProcedureKindsUseCase listProcedureKindsUseCase,
    required ListAssistantsUseCase listAssistantsUseCase,
    ProcedureSessionRichFactory? factory,
  })  : _listProcedureSessionsUseCase = listProcedureSessionsUseCase,
        _listWorkdaysUseCase = listWorkdaysUseCase,
        _listHumansUseCase = listHumansUseCase,
        _listProcedureKindsUseCase = listProcedureKindsUseCase,
        _listAssistantsUseCase = listAssistantsUseCase,
        _factory = factory ?? const ProcedureSessionRichFactory();

  final ListProcedureSessionsUseCase _listProcedureSessionsUseCase;
  final ListWorkdaysUseCase _listWorkdaysUseCase;
  final ListHumansUseCase _listHumansUseCase;
  final ListProcedureKindsUseCase _listProcedureKindsUseCase;
  final ListAssistantsUseCase _listAssistantsUseCase;
  final ProcedureSessionRichFactory _factory;

  Future<List<ProcedureSessionRich>> execute() async {
    final procedureSessions = await _listProcedureSessionsUseCase.execute();
    final workdays = await _listWorkdaysUseCase.execute();
    final humans = await _listHumansUseCase.execute();
    final procedureKinds = await _listProcedureKindsUseCase.execute();
    final assistants = await _listAssistantsUseCase.execute();

    final richSessions = [
      for (final procedureSession in procedureSessions)
        _factory.create(
          raw: procedureSession,
          workdays: workdays,
          humans: humans,
          procedureKinds: procedureKinds,
          assistants: assistants,
        ),
    ];

    richSessions.sort((left, right) {
      final leftDayName = left.day?.name ?? left.dayId;
      final rightDayName = right.day?.name ?? right.dayId;
      final byDay = leftDayName.compareTo(rightDayName);
      if (byDay != 0) {
        return byDay;
      }

      final byStartTime = left.startTime.compareTo(right.startTime);
      if (byStartTime != 0) {
        return byStartTime;
      }

      final leftProcedureName =
          left.procedureKind?.name ?? left.procedureKindId;
      final rightProcedureName =
          right.procedureKind?.name ?? right.procedureKindId;
      final byProcedure = leftProcedureName.compareTo(rightProcedureName);
      if (byProcedure != 0) {
        return byProcedure;
      }

      return left.id.compareTo(right.id);
    });

    return List<ProcedureSessionRich>.unmodifiable(richSessions);
  }
}
