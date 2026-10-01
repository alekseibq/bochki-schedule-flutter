import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../assistants/assistant.dart';
import '../humans/human.dart';
import '../procedure_kinds/procedure_kind.dart';
import '../workdays/workday.dart';
import 'procedure_session_conflict_calculator.dart';
import 'procedure_session_raw.dart';
import 'procedure_session_rich.dart';
import 'procedure_session_rich_factory.dart';
import 'procedure_session_time.dart';

enum ProcedureSessionTooltipTone { normal, conflict, companion }

final class ProcedureSessionTooltipLine {
  const ProcedureSessionTooltipLine(this.text,
      [this.tone = ProcedureSessionTooltipTone.normal]);

  final String text;
  final ProcedureSessionTooltipTone tone;
}

final class ProcedureSessionTooltipData {
  const ProcedureSessionTooltipData({required this.title, required this.lines});

  final String title;
  final List<ProcedureSessionTooltipLine> lines;
}

/// Creates the schedule explanations displayed by the assignment editor.
final class ProcedureSessionTooltipBuilder {
  const ProcedureSessionTooltipBuilder({
    this.richFactory = const ProcedureSessionRichFactory(),
    this.conflictCalculator = const ProcedureSessionConflictCalculator(),
  });

  final ProcedureSessionRichFactory richFactory;
  final ProcedureSessionConflictCalculator conflictCalculator;

  ProcedureSessionTooltipData procedureAvailability({
    required String dayId,
    required String procedureKindId,
    required String editingSessionId,
    required Iterable<ProcedureSessionRaw> savedSessions,
    required Iterable<Workday> workdays,
    required Iterable<ProcedureKind> procedureKinds,
    required ProgramSettings programSettings,
  }) {
    final day = workdays.where((entry) => entry.id == dayId).firstOrNull;
    final kind = procedureKinds
        .where((entry) => entry.id == procedureKindId)
        .firstOrNull;
    final title = 'Свободные интервалы для процедуры в ${day?.name ?? dayId}';
    if (kind == null) {
      return ProcedureSessionTooltipData(title: title, lines: const []);
    }
    final start = programSettings.minimumTime.hour * 60 +
        programSettings.minimumTime.minute;
    final finish = programSettings.maximumTime.hour * 60 +
        programSettings.maximumTime.minute;
    final intervals = <({int start, int finish})>[];
    for (final session in savedSessions) {
      if (session.id == editingSessionId ||
          session.dayId != dayId ||
          session.procedureKindId != procedureKindId) {
        continue;
      }
      final sessionFinish = kind.resourceBusyTime == null
          ? ProcedureSessionTime.toMinutes(session.startTime)
          : ProcedureSessionTime.toMinutes(session.startTime) +
              kind.resourceBusyTime!;
      intervals.add((
        start: ProcedureSessionTime.toMinutes(session.startTime),
        finish: sessionFinish
      ));
    }
    final boundaries = <int>{start, finish};
    for (final interval in intervals) {
      boundaries.add(interval.start.clamp(start, finish));
      boundaries.add(interval.finish.clamp(start, finish));
    }
    final sorted = boundaries.toList()..sort();
    final free = <({int start, int finish})>[];
    for (var index = 0; index < sorted.length - 1; index++) {
      final segmentStart = sorted[index];
      final segmentFinish = sorted[index + 1];
      final occupied = intervals
          .where((entry) =>
              entry.start < segmentFinish && entry.finish > segmentStart)
          .length;
      if (occupied < kind.capacity) {
        if (free.isNotEmpty && free.last.finish == segmentStart) {
          free[free.length - 1] =
              (start: free.last.start, finish: segmentFinish);
        } else {
          free.add((start: segmentStart, finish: segmentFinish));
        }
      }
    }
    return ProcedureSessionTooltipData(
      title: title,
      lines: free.isEmpty
          ? const [ProcedureSessionTooltipLine('Свободных интервалов нет')]
          : [
              for (final interval in free)
                ProcedureSessionTooltipLine(
                    '${ProcedureSessionTime.fromMinutes(interval.start)}-${ProcedureSessionTime.fromMinutes(interval.finish)}')
            ],
    );
  }

  ProcedureSessionTooltipData personSchedule({
    required String humanId,
    required String humanName,
    required String dayId,
    required Iterable<ProcedureSessionRaw> savedSessions,
    required Iterable<Workday> workdays,
    required Iterable<Human> humans,
    required Iterable<ProcedureKind> procedureKinds,
    required Iterable<Assistant> assistants,
    required ProgramSettings programSettings,
  }) {
    final raws = savedSessions.toList();
    final rich = [
      for (final raw in raws)
        richFactory.create(
            raw: raw,
            workdays: workdays,
            humans: humans,
            procedureKinds: procedureKinds,
            assistants: assistants)
    ];
    final conflictIds = conflictCalculator
        .calculate(rich, programSettings: programSettings)
        .map((entry) => entry.procedureSessionId)
        .toSet();
    final companion = humans
            .where((entry) => entry.id == humanId)
            .firstOrNull
            ?.hasProcedureRole(ProcedureRole.companion) ??
        false;
    final entries = <_PersonScheduleEntry>[];
    for (final session in rich) {
      if (session.dayId != dayId || session.procedureKind == null) {
        continue;
      }
      if (session.participantId == humanId) {
        entries.add(_PersonScheduleEntry(session,
            isAssistant: false,
            hasConflict: conflictIds.contains(session.id),
            companion: companion));
      }
      if (session.assistantId == humanId) {
        entries.add(_PersonScheduleEntry(session,
            isAssistant: true,
            hasConflict: conflictIds.contains(session.id),
            companion: false));
      }
    }
    final collapsed = _collapseGrouped(entries);
    collapsed.sort((left, right) {
      final byTime = left.session.startTime.compareTo(right.session.startTime);
      if (byTime != 0) return byTime;
      final byKind = left.session.procedureKind!.name
          .compareTo(right.session.procedureKind!.name);
      if (byKind != 0) return byKind;
      return left.participantNames
          .join(', ')
          .compareTo(right.participantNames.join(', '));
    });
    return ProcedureSessionTooltipData(
      title: 'Расписание участника $humanName',
      lines: collapsed.isEmpty
          ? const [ProcedureSessionTooltipLine('Нет назначенных процедур')]
          : [for (final entry in collapsed) entry.toLine()],
    );
  }

  List<_PersonScheduleEntry> _collapseGrouped(
      List<_PersonScheduleEntry> entries) {
    final result = <_PersonScheduleEntry>[];
    final grouped = <String, List<_PersonScheduleEntry>>{};
    for (final entry in entries) {
      final kind = entry.session.procedureKind!;
      if (!entry.isAssistant || !kind.isGrouped) {
        result.add(entry);
        continue;
      }
      grouped
          .putIfAbsent(
              '${entry.session.dayId}|${entry.session.startTime}|${entry.session.assistantId}|${kind.id}',
              () => [])
          .add(entry);
    }
    for (final group in grouped.values) {
      final first = group.first;
      result.add(first.copyWith(
        participantNames: [
          for (final entry in group)
            entry.session.participant?.name ??
                entry.session.participantId ??
                'неизвестный участник'
        ]..sort(),
        hasConflict: group.any((entry) => entry.hasConflict),
      ));
    }
    return result;
  }
}

final class _PersonScheduleEntry {
  const _PersonScheduleEntry(this.session,
      {required this.isAssistant,
      required this.hasConflict,
      required this.companion,
      this.participantNames = const []});
  final ProcedureSessionRich session;
  final bool isAssistant;
  final bool hasConflict;
  final bool companion;
  final List<String> participantNames;
  _PersonScheduleEntry copyWith(
          {List<String>? participantNames, bool? hasConflict}) =>
      _PersonScheduleEntry(session,
          isAssistant: isAssistant,
          hasConflict: hasConflict ?? this.hasConflict,
          companion: companion,
          participantNames: participantNames ?? this.participantNames);
  ProcedureSessionTooltipLine toLine() {
    final kind = session.procedureKind!;
    final duration =
        isAssistant ? kind.assistantBusyTime : kind.participantBusyTime;
    final finish = duration == null
        ? session.startTime
        : ProcedureSessionTime.fromMinutes(
            ProcedureSessionTime.toMinutes(session.startTime) + duration);
    final suffix = isAssistant
        ? 'уч. ${(participantNames.isEmpty ? [
            session.participant?.name ??
                session.participantId ??
                'неизвестный участник'
          ] : participantNames).join(', ')}'
        : 'асс. ${session.assistant?.name ?? 'не назначен'}';
    final tone = hasConflict
        ? ProcedureSessionTooltipTone.conflict
        : (!isAssistant && companion
            ? ProcedureSessionTooltipTone.companion
            : ProcedureSessionTooltipTone.normal);
    return ProcedureSessionTooltipLine(
      '${session.startTime}-$finish ${kind.shortName}${isAssistant ? '-АССИСТЕНТ' : ''} — $suffix',
      tone,
    );
  }
}
