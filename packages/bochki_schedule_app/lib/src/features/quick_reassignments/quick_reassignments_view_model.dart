import 'package:flutter/foundation.dart';
import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';

import '../../domain/humans/human.dart';
import '../../domain/procedure_sessions/procedure_session_rich.dart';
import '../../domain/procedure_sessions/procedure_session_time.dart';
import '../../domain/procedure_sessions/procedure_session_raw.dart';
import '../../domain/procedure_sessions/quick_reassignments_use_case.dart';
import '../../domain/procedure_sessions/list_rich_procedure_sessions_use_case.dart';
import '../../domain/workdays/list_workdays_use_case.dart';
import '../../domain/workdays/workday.dart';
import '../../domain/humans/list_humans_use_case.dart';
import '../../domain/program_settings/get_program_settings_use_case.dart';

enum QuickPeopleFilter {
  all('Все'),
  participants('Только участники'),
  assistants('Только ассистенты');

  const QuickPeopleFilter(this.label);
  final String label;
}

enum QuickSort {
  time('По времени'),
  participants('По участникам'),
  assistants('По ассистентам');

  const QuickSort(this.label);
  final String label;
}

enum QuickPart {
  fullDay('Весь день'),
  beforeLunch('До обеда'),
  afterLunch('После обеда');

  const QuickPart(this.label);
  final String label;
}

final class QuickAssistantCandidate {
  const QuickAssistantCandidate(this.human, {this.swapSession});
  final Human human;
  final ProcedureSessionRich? swapSession;
  bool get isSwap => swapSession != null;
}

final class QuickReassignmentsViewModel extends ChangeNotifier {
  QuickReassignmentsViewModel(
      {required ListRichProcedureSessionsUseCase sessions,
      required ListWorkdaysUseCase workdays,
      required ListHumansUseCase humans,
      required GetProgramSettingsUseCase settings,
      required QuickReassignmentsUseCase mutations})
      : _sessions = sessions,
        _workdaysUseCase = workdays,
        _humansUseCase = humans,
        _settingsUseCase = settings,
        _mutations = mutations;
  final ListRichProcedureSessionsUseCase _sessions;
  final ListWorkdaysUseCase _workdaysUseCase;
  final ListHumansUseCase _humansUseCase;
  final GetProgramSettingsUseCase _settingsUseCase;
  final QuickReassignmentsUseCase _mutations;
  List<Workday> workdays = const [];
  List<Human> humans = const [];
  List<ProcedureSessionRich> _all = const [];
  ProgramSettings _settings = ProgramSettings.defaults;
  String? dayId;
  QuickPart part = QuickPart.fullDay;
  QuickPeopleFilter people = QuickPeopleFilter.all;
  QuickSort sort = QuickSort.time;
  bool loading = true;
  bool saving = false;
  String? error;
  List<ProcedureSessionRich> get entries {
    final r = _all
        .where((s) =>
            s.requiresAssistant &&
            s.dayId == dayId &&
            _partMatches(s) &&
            _peopleMatches(s))
        .toList();
    r.sort(_compare);
    return r;
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      workdays = await _workdaysUseCase.execute();
      humans = await _humansUseCase.execute();
      _settings = await _settingsUseCase.execute();
      _all = await _sessions.execute();
      dayId ??= workdays.isEmpty ? null : workdays.first.id;
      error = null;
    } catch (_) {
      error = 'Не удалось загрузить быстрые перестановки.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setDay(String? v) {
    dayId = v;
    notifyListeners();
  }

  void setPart(QuickPart v) {
    part = v;
    notifyListeners();
  }

  void setPeople(QuickPeopleFilter v) {
    people = v;
    notifyListeners();
  }

  void setSort(QuickSort v) {
    sort = v;
    notifyListeners();
  }

  List<Human> participantCandidates(ProcedureSessionRich s) => humans
      .where((h) =>
          h.id == s.participantId ||
          (h.isAssistant == (s.participant?.isAssistant ?? false) &&
              _free(h.id, s, s.id)))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  List<QuickAssistantCandidate> assistantCandidates(ProcedureSessionRich s) {
    final current = humans
        .where((h) => h.id == s.assistantId)
        .map(QuickAssistantCandidate.new)
        .toList();
    final free = <QuickAssistantCandidate>[];
    final swaps = <QuickAssistantCandidate>[];
    for (final human
        in humans.where((h) => h.isAssistant && h.id != s.assistantId)) {
      if (_free(human.id, s, s.id)) {
        free.add(QuickAssistantCandidate(human));
        continue;
      }
      final matches = _all
          .where((other) =>
              other.id != s.id &&
              other.assistantId == human.id &&
              other.dayId == s.dayId &&
              other.startTime == s.startTime &&
              other.assistantFinishTime == s.assistantFinishTime)
          .toList();
      if (matches.length == 1 && _canSwap(s, matches.single)) {
        swaps.add(QuickAssistantCandidate(human, swapSession: matches.single));
      }
    }
    int byName(QuickAssistantCandidate a, QuickAssistantCandidate b) =>
        a.human.name.compareTo(b.human.name);
    free.sort(byName);
    swaps.sort(byName);
    return [...current, ...free, ...swaps];
  }

  Future<void> changeParticipant(ProcedureSessionRich s, String id) =>
      _apply([s.raw.copyWith(participantId: id)]);
  Future<void> changeAssistant(ProcedureSessionRich s, String id) =>
      _apply([s.raw.copyWith(assistantId: id)]);
  Future<void> chooseAssistant(
      ProcedureSessionRich s, QuickAssistantCandidate candidate) async {
    final other = candidate.swapSession;
    if (other == null) return changeAssistant(s, candidate.human.id);
    await _apply([
      s.raw.copyWith(assistantId: candidate.human.id),
      other.raw.copyWith(assistantId: s.assistantId)
    ]);
  }

  Future<void> _apply(List<ProcedureSessionRaw> r) async {
    saving = true;
    notifyListeners();
    try {
      await _mutations.execute(r);
      await load();
    } catch (_) {
      error = 'Не удалось применить перестановку.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  bool _free(String id, ProcedureSessionRich target, String ignore) {
    if (target.participantId == id) return false;
    final a = ProcedureSessionTime.toMinutes(target.startTime),
        b = ProcedureSessionTime.toMinutes(
            target.finishTime ?? target.startTime);
    return !_all.any((s) {
      if (s.id == ignore || s.dayId != target.dayId) return false;
      if (s.participantId != id && s.assistantId != id) return false;
      final x = ProcedureSessionTime.toMinutes(s.startTime),
          y = ProcedureSessionTime.toMinutes(
              (s.participantId == id ? s.finishTime : s.assistantFinishTime) ??
                  s.startTime);
      return x < b && y > a;
    });
  }

  bool _canSwap(ProcedureSessionRich left, ProcedureSessionRich right) =>
      left.assistantId != null &&
      right.assistantId != null &&
      left.participantId != right.assistantId &&
      right.participantId != left.assistantId;

  bool _partMatches(ProcedureSessionRich s) {
    final m = ProcedureSessionTime.toMinutes(s.startTime),
        lunch = _settings.lunchStart.hour * 60 + _settings.lunchStart.minute;
    return part == QuickPart.fullDay ||
        (part == QuickPart.beforeLunch ? m < lunch : m >= lunch);
  }

  bool _peopleMatches(ProcedureSessionRich s) {
    final a = s.participant?.isAssistant ?? false;
    return people == QuickPeopleFilter.all ||
        (people == QuickPeopleFilter.assistants ? a : !a);
  }

  int _compare(ProcedureSessionRich a, ProcedureSessionRich b) {
    String key(ProcedureSessionRich x) => sort == QuickSort.time
        ? x.startTime
        : sort == QuickSort.participants
            ? (x.participant?.name ?? '')
            : (x.assistant?.name ?? '');
    final c = key(a).compareTo(key(b));
    return c != 0 ? c : a.id.compareTo(b.id);
  }
}
