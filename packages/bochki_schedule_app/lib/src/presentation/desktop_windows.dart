import 'dart:convert';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../domain/assistants/assistant.dart';
import '../domain/humans/human.dart';
import '../domain/procedure_kinds/procedure_kind.dart';
import '../domain/procedure_sessions/procedure_session_raw.dart';
import '../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../domain/procedure_statistics/procedure_statistics_table.dart';
import '../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../domain/schedule_gaps/schedule_gap.dart';
import '../domain/workdays/workday.dart';
import '../features/procedure_sessions/procedure_session_dialog.dart';
import '../features/procedure_sessions/procedure_session_submit_result.dart';
import '../features/procedure_sessions/procedure_sessions_view_model.dart';

enum DesktopWindowKind { main, procedureStatistics, procedureSession, freeTime }

const _mainChannel = WindowMethodChannel(
  'bochki_schedule/main_window',
  mode: ChannelMode.unidirectional,
);

String _arguments(DesktopWindowKind kind) => jsonEncode({'kind': kind.name});

DesktopWindowKind windowKindFromArguments(String value) {
  try {
    return DesktopWindowKind.values.byName(
      (jsonDecode(value) as Map<String, dynamic>)['kind'] as String,
    );
  } catch (_) {
    return DesktopWindowKind.main;
  }
}

/// Runs only in the main window. Child windows never initialize repositories.
final class DesktopWindowCoordinator {
  DesktopWindowCoordinator({
    required BuildProcedureStatisticsTableUseCase statistics,
    required BuildScheduleGapsUseCase scheduleGaps,
    required ProcedureSessionsViewModel sessions,
  })  : _statistics = statistics,
        _scheduleGaps = scheduleGaps,
        _sessions = sessions;

  final BuildProcedureStatisticsTableUseCase _statistics;
  final BuildScheduleGapsUseCase _scheduleGaps;
  final ProcedureSessionsViewModel _sessions;
  ProcedureSessionRaw? _sessionDraft;

  Future<void> start() => _mainChannel.setMethodCallHandler(_handleCall);

  Future<void> dispose() => _mainChannel.setMethodCallHandler(null);

  Future<void> closeChildren() async {
    for (final controller in await WindowController.getAll()) {
      if (windowKindFromArguments(controller.arguments) !=
          DesktopWindowKind.main) {
        await controller.invokeMethod<void>('window_close');
      }
    }
  }

  Future<void> openStatistics() async {
    await _sessions.load();
    await _open(DesktopWindowKind.procedureStatistics);
  }

  Future<void> openSession({ProcedureSessionRaw? draft}) async {
    await _sessions.load();
    _sessionDraft = draft;
    await _open(DesktopWindowKind.procedureSession);
  }

  Future<void> openFreeTime() async {
    await _sessions.load();
    await _open(DesktopWindowKind.freeTime);
  }

  Future<void> _open(DesktopWindowKind kind) async {
    final existing = (await WindowController.getAll()).where(
      (controller) => windowKindFromArguments(controller.arguments) == kind,
    );
    if (existing.isNotEmpty) {
      await existing.first.show();
      await existing.first.invokeMethod<void>('window_focus');
      return;
    }
    final controller = await WindowController.create(
      WindowConfiguration(arguments: _arguments(kind)),
    );
    await controller.show();
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'statistics':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final table = await _statistics.execute(
          dayId: values['dayId'] as String?,
          peopleFilter: ProcedureStatisticsPeopleFilter.values.byName(
            values['peopleFilter'] as String,
          ),
          mode: ProcedureStatisticsMode.values.byName(values['mode'] as String),
        );
        return _statisticsMap(table);
      case 'openProcedureSession':
        final values = call.arguments as Map?;
        await openSession(
          draft: values == null
              ? null
              : _sessions.createDraft().copyWith(
                    dayId: values['dayId'] as String,
                    participantId: values['participantId'] as String,
                    startTime: values['startTime'] as String,
                  ),
        );
        return null;
      case 'freeTime':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final gaps = await _scheduleGaps.execute(ScheduleGapsQuery(
          dayId: values['dayId'] as String?,
          fromMinutes: values['fromMinutes'] as int,
          toMinutes: values['toMinutes'] as int,
          peopleFilter: ScheduleGapPeopleFilter.values
              .byName(values['peopleFilter'] as String),
          minimumDurationMinutes: values['minimumDurationMinutes'] as int,
        ));
        return {
          'workdays': _sessions.workdays.map(_workdayMap).toList(),
          'gaps': gaps.map(_gapMap).toList()
        };
      case 'procedureSessionSnapshot':
        return _sessionSnapshot();
      case 'submitProcedureSession':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final result = await _sessions.submitProcedureSession(
          _sessionFromMap(Map<String, dynamic>.from(values['session'] as Map)),
          allowConflicts: values['allowConflicts'] as bool,
        );
        if (result.didSave) {
          for (final controller in await WindowController.getAll()) {
            if (windowKindFromArguments(controller.arguments) ==
                DesktopWindowKind.procedureStatistics) {
              await controller.invokeMethod<void>('statistics_changed');
            }
            if (windowKindFromArguments(controller.arguments) ==
                DesktopWindowKind.freeTime) {
              await controller.invokeMethod<void>('free_time_changed');
            }
          }
        }
        return {
          'didSave': result.didSave,
          'conflictMessages': result.conflictMessages,
          'errorMessage': result.errorMessage,
        };
      default:
        throw MissingPluginException(
            'Unknown main-window method ${call.method}');
    }
  }

  Map<String, dynamic> _statisticsMap(ProcedureStatisticsTable table) => {
        'workdays': _sessions.workdays.map(_workdayMap).toList(),
        'people': table.people.map(_humanMap).toList(),
        'kinds': table.kinds.map(_kindMap).toList(),
        'counts': table.counts,
      };

  Map<String, dynamic> _gapMap(ScheduleGap gap) => {
        'day': _workdayMap(gap.workday),
        'human': _humanMap(gap.human),
        'start': gap.startTime,
        'end': gap.endTime,
        'duration': gap.durationLabel
      };

  Map<String, dynamic> _sessionSnapshot() => {
        'draft': _sessionMap(_sessionDraft ?? _sessions.createDraft()),
        'workdays': _sessions.workdays.map(_workdayMap).toList(),
        'humans': _sessions.humans.map(_humanMap).toList(),
        'procedureKinds': _sessions.procedureKinds.map(_kindMap).toList(),
        'assistants': _sessions.assistants.map(_assistantMap).toList(),
        'settings': {
          'minimumHour': _sessions.programSettings.minimumHour,
          'maximumHour': _sessions.programSettings.maximumHour,
          'lunchStart': _sessions.programSettings.lunchStart.toJson(),
          'lunchEnd': _sessions.programSettings.lunchEnd.toJson(),
        },
      };
}

Future<void> configureChildWindow(DesktopWindowKind kind) async {
  await windowManager.ensureInitialized();
  final isStatistics = kind == DesktopWindowKind.procedureStatistics;
  final isFreeTime = kind == DesktopWindowKind.freeTime;
  final options = WindowOptions(
    title: isStatistics
        ? 'Статистика процедур'
        : isFreeTime
            ? 'Свободное время'
            : 'Назначить процедуру',
    size: isStatistics || isFreeTime
        ? const Size(1065, 514)
        : const Size(900, 680),
    minimumSize: isStatistics ? const Size(820, 420) : const Size(850, 600),
    center: true,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  final current = await WindowController.fromCurrentEngine();
  await current.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'window_focus':
        await windowManager.focus();
        return null;
      case 'window_close':
        await windowManager.close();
        return null;
      default:
        throw MissingPluginException('Unknown window method ${call.method}');
    }
  });
}

class ProcedureStatisticsWindow extends StatefulWidget {
  const ProcedureStatisticsWindow({super.key});
  @override
  State<ProcedureStatisticsWindow> createState() =>
      _ProcedureStatisticsWindowState();
}

class _ProcedureStatisticsWindowState extends State<ProcedureStatisticsWindow> {
  String? _dayId;
  var _people = ProcedureStatisticsPeopleFilter.all;
  var _mode = ProcedureStatisticsMode.participation;
  bool _loading = true;
  String? _error;
  List<Workday> _workdays = const [];
  List<Human> _humans = const [];
  List<ProcedureKind> _kinds = const [];
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _listenForChanges();
    _load();
  }

  Future<void> _listenForChanges() async {
    final controller = await WindowController.fromCurrentEngine();
    await controller.setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_focus':
          await windowManager.focus();
          return null;
        case 'window_close':
          await windowManager.close();
          return null;
        case 'statistics_changed':
          await _load();
          return null;
        default:
          throw MissingPluginException('Unknown statistics-window method');
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = Map<String, dynamic>.from(
          await _mainChannel.invokeMethod<Map>('statistics', {
                'dayId': _dayId,
                'peopleFilter': _people.name,
                'mode': _mode.name,
              }) ??
              const {});
      setState(() {
        _workdays = _maps(result['workdays']).map(_workdayFromMap).toList();
        _humans = _maps(result['people']).map(_humanFromMap).toList();
        _kinds = _maps(result['kinds']).map(_kindFromMap).toList();
        _counts = Map<String, int>.from(result['counts'] as Map? ?? const {});
      });
    } catch (_) {
      setState(() => _error = 'Не удалось загрузить статистику процедур.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Column(children: [
          Container(
              height: 56,
              color: const Color(0xFFE9EEF2),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              child: FilledButton.tonal(
                onPressed: () =>
                    _mainChannel.invokeMethod<void>('openProcedureSession'),
                child: const Text('Добавить запись'),
              )),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String?>(
                        value: _dayId,
                        decoration: const InputDecoration(labelText: 'День'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Все дни')),
                          ..._workdays.map((d) => DropdownMenuItem(
                              value: d.id, child: Text(d.name)))
                        ],
                        onChanged: (v) {
                          _dayId = v;
                          _load();
                        })),
                const SizedBox(width: 12),
                Expanded(
                    child: DropdownButtonFormField(
                        value: _people,
                        decoration:
                            const InputDecoration(labelText: 'Участники'),
                        items: const [
                          DropdownMenuItem(
                              value: ProcedureStatisticsPeopleFilter.all,
                              child: Text('Все')),
                          DropdownMenuItem(
                              value:
                                  ProcedureStatisticsPeopleFilter.participants,
                              child: Text('Участники')),
                          DropdownMenuItem(
                              value: ProcedureStatisticsPeopleFilter.assistants,
                              child: Text('Ассистенты'))
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            _people = v;
                            _load();
                          }
                        })),
                const SizedBox(width: 12),
                Expanded(
                    child: DropdownButtonFormField(
                        value: _mode,
                        decoration: const InputDecoration(labelText: 'Режим'),
                        items: const [
                          DropdownMenuItem(
                              value: ProcedureStatisticsMode.participation,
                              child: Text('Участие')),
                          DropdownMenuItem(
                              value: ProcedureStatisticsMode.assisting,
                              child: Text('Ассистирование'))
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            _mode = v;
                            _load();
                          }
                        })),
              ])),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _humans.isEmpty
                          ? const Center(
                              child: Text('Нет данных по выбранным фильтрам'))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                  child: DataTable(columns: [
                                const DataColumn(label: Text('Человек')),
                                ..._kinds
                                    .map((k) => DataColumn(label: Text(k.name)))
                              ], rows: [
                                for (final human in _humans)
                                  DataRow(cells: [
                                    DataCell(Text(human.shortName)),
                                    ..._kinds.map((kind) => DataCell(Text(
                                        '${_counts['${human.id}/${kind.id}'] ?? 0}')))
                                  ])
                              ])))),
        ])),
      );
}

class FreeTimeWindow extends StatefulWidget {
  const FreeTimeWindow({super.key});
  @override
  State<FreeTimeWindow> createState() => _FreeTimeWindowState();
}

class _FreeTimeWindowState extends State<FreeTimeWindow> {
  String? _dayId;
  var _people = ScheduleGapPeopleFilter.all;
  var _from = 480;
  var _to = 1200;
  var _minimum = 30;
  List<Workday> _workdays = const [];
  List<Map<String, dynamic>> _gaps = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listen();
    _load();
  }

  Future<void> _listen() async {
    final controller = await WindowController.fromCurrentEngine();
    await controller.setWindowMethodHandler((call) async {
      if (call.method == 'free_time_changed') {
        await _load();
        return null;
      }
      if (call.method == 'window_close') {
        await windowManager.close();
        return null;
      }
      if (call.method == 'window_focus') {
        await windowManager.focus();
        return null;
      }
      throw MissingPluginException('Unknown free-time-window method');
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final value = await _mainChannel.invokeMethod<Map>('freeTime', {
      'dayId': _dayId,
      'fromMinutes': _from,
      'toMinutes': _to,
      'peopleFilter': _people.name,
      'minimumDurationMinutes': _minimum
    });
    if (mounted) {
      setState(() {
        _workdays = _maps(value?['workdays']).map(_workdayFromMap).toList();
        _gaps = _maps(value?['gaps']);
        _loading = false;
      });
    }
  }

  List<int> get _times =>
      [for (var value = 480; value <= 1200; value += 30) value];
  String _time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: DropdownButtonFormField<String?>(
                      value: _dayId,
                      decoration: const InputDecoration(labelText: 'День'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Все дни')),
                        ..._workdays.map((d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)))
                      ],
                      onChanged: (v) {
                        _dayId = v;
                        _load();
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: DropdownButtonFormField<int>(
                      value: _from,
                      decoration: const InputDecoration(labelText: 'Время с'),
                      items: _times
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(_time(v))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          _from = v;
                          if (_from > _to) {
                            final x = _from;
                            _from = _to;
                            _to = x;
                          }
                          _load();
                        }
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: DropdownButtonFormField<int>(
                      value: _to,
                      decoration: const InputDecoration(labelText: 'Время до'),
                      items: _times
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(_time(v))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          _to = v;
                          if (_from > _to) {
                            final x = _from;
                            _from = _to;
                            _to = x;
                          }
                          _load();
                        }
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: DropdownButtonFormField<ScheduleGapPeopleFilter>(
                      value: _people,
                      decoration:
                          const InputDecoration(labelText: 'Искать для'),
                      items: const [
                        DropdownMenuItem(
                            value: ScheduleGapPeopleFilter.all,
                            child: Text('Участники и Ассистенты')),
                        DropdownMenuItem(
                            value: ScheduleGapPeopleFilter.participants,
                            child: Text('Участники')),
                        DropdownMenuItem(
                            value: ScheduleGapPeopleFilter.assistants,
                            child: Text('Ассистенты'))
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _people = v;
                          _load();
                        }
                      })),
              const SizedBox(width: 12),
              Expanded(
                  child: DropdownButtonFormField<int>(
                      value: _minimum,
                      decoration: const InputDecoration(
                          labelText: 'Показывать интервалы более'),
                      items: [
                        for (var v = 30; v <= 300; v += 30)
                          DropdownMenuItem(
                              value: v,
                              child: Text(v == 30
                                  ? '30 мин'
                                  : '${v ~/ 60}ч ${(v % 60).toString().padLeft(2, '0')}мин'))
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _minimum = v;
                          _load();
                        }
                      })),
            ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _gaps.isEmpty
                    ? const Center(
                        child: Text('Нет данных по выбранным фильтрам'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                            columns: const [
                              DataColumn(label: Text('День')),
                              DataColumn(label: Text('Человек')),
                              DataColumn(label: Text('Начало')),
                              DataColumn(label: Text('Конец')),
                              DataColumn(label: Text('Длительность')),
                              DataColumn(label: Text('')),
                            ],
                            rows: _gaps.map((g) {
                              final day = _workdayFromMap(
                                  Map<String, dynamic>.from(g['day'] as Map));
                              final human = _humanFromMap(
                                  Map<String, dynamic>.from(g['human'] as Map));
                              return DataRow(cells: [
                                DataCell(Text(day.name)),
                                DataCell(Text(human.name)),
                                DataCell(Text(g['start'] as String)),
                                DataCell(Text(g['end'] as String)),
                                DataCell(Text(g['duration'] as String)),
                                DataCell(FilledButton.tonal(
                                    onPressed: () => _mainChannel
                                            .invokeMethod<void>(
                                                'openProcedureSession', {
                                          'dayId': day.id,
                                          'participantId': human.id,
                                          'startTime': g['start'] as String
                                        }),
                                    child: const Text('Занять участника'))),
                              ]);
                            }).toList()))),
      ])));
}

class ProcedureSessionWindow extends StatefulWidget {
  const ProcedureSessionWindow({super.key});
  @override
  State<ProcedureSessionWindow> createState() => _ProcedureSessionWindowState();
}

class _ProcedureSessionWindowState extends State<ProcedureSessionWindow> {
  Map<String, dynamic>? _snapshot;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value =
        await _mainChannel.invokeMethod<Map>('procedureSessionSnapshot');
    if (mounted) {
      setState(() => _snapshot = Map<String, dynamic>.from(value!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    final settings = Map<String, dynamic>.from(snapshot['settings'] as Map);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: Center(
                child: ProcedureSessionDialog(
          initialValue: _sessionFromMap(
              Map<String, dynamic>.from(snapshot['draft'] as Map)),
          workdays: _maps(snapshot['workdays']).map(_workdayFromMap).toList(),
          humans: _maps(snapshot['humans']).map(_humanFromMap).toList(),
          procedureKinds:
              _maps(snapshot['procedureKinds']).map(_kindFromMap).toList(),
          assistants:
              _maps(snapshot['assistants']).map(_assistantFromMap).toList(),
          programSettings: ProgramSettings(
              minimumHour: settings['minimumHour'] as int,
              maximumHour: settings['maximumHour'] as int,
              lunchStart: ProgramSettingsTime.fromJson(settings['lunchStart']),
              lunchEnd: ProgramSettingsTime.fromJson(settings['lunchEnd'])),
          onSubmit: (session, allowConflicts) async {
            final response = await _mainChannel.invokeMethod<Map>(
                'submitProcedureSession', {
              'session': _sessionMap(session),
              'allowConflicts': allowConflicts
            });
            if (response == null) {
              return const ProcedureSessionSubmitResult.error(
                  'Не удалось сохранить назначенную процедуру.');
            }
            final value = Map<String, dynamic>.from(response);
            if (value['didSave'] as bool) {
              await windowManager.close();
            }
            return value['didSave'] as bool
                ? const ProcedureSessionSubmitResult.saved()
                : (value['conflictMessages'] as List).isNotEmpty
                    ? ProcedureSessionSubmitResult.conflicts(
                        (value['conflictMessages'] as List).cast<String>())
                    : ProcedureSessionSubmitResult.error(
                        value['errorMessage'] as String);
          },
        ))));
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();
Map<String, dynamic> _humanMap(Human h) => {
      'id': h.id,
      'name': h.name,
      'shortName': h.shortName,
      'isParticipant': h.isParticipant,
      'isAssistant': h.isAssistant
    };
Human _humanFromMap(Map<String, dynamic> m) => Human(
    id: m['id'] as String,
    name: m['name'] as String,
    shortName: m['shortName'] as String,
    isParticipant: m['isParticipant'] as bool,
    isAssistant: m['isAssistant'] as bool);
Map<String, dynamic> _assistantMap(Assistant a) =>
    {'id': a.id, 'name': a.name, 'shortName': a.shortName};
Assistant _assistantFromMap(Map<String, dynamic> m) => Assistant(
    id: m['id'] as String,
    name: m['name'] as String,
    shortName: m['shortName'] as String);
Map<String, dynamic> _workdayMap(Workday d) =>
    {'id': d.id, 'name': d.name, 'date': d.calendarDate.toIso8601String()};
Workday _workdayFromMap(Map<String, dynamic> m) => Workday(
    id: m['id'] as String,
    name: m['name'] as String,
    calendarDate: DateTime.parse(m['date'] as String));
Map<String, dynamic> _kindMap(ProcedureKind k) => {
      'id': k.id,
      'patternId': k.patternId,
      'name': k.name,
      'shortName': k.shortName,
      'capacity': k.capacity,
      'participantBusyTime': k.participantBusyTime,
      'assistantBusyTime': k.assistantBusyTime,
      'resourceBusyTime': k.resourceBusyTime
    };
ProcedureKind _kindFromMap(Map<String, dynamic> m) => ProcedureKind(
    id: m['id'] as String,
    patternId: m['patternId'] as String,
    name: m['name'] as String,
    shortName: m['shortName'] as String,
    capacity: m['capacity'] as int,
    participantBusyTime: m['participantBusyTime'] as int,
    assistantBusyTime: m['assistantBusyTime'] as int?,
    resourceBusyTime: m['resourceBusyTime'] as int?);
Map<String, dynamic> _sessionMap(ProcedureSessionRaw s) => {
      'id': s.id,
      'dayId': s.dayId,
      'participantId': s.participantId,
      'startTime': s.startTime,
      'procedureKindId': s.procedureKindId,
      'assistantId': s.assistantId
    };
ProcedureSessionRaw _sessionFromMap(Map<String, dynamic> m) =>
    ProcedureSessionRaw(
        id: m['id'] as String,
        dayId: m['dayId'] as String,
        participantId: m['participantId'] as String,
        startTime: m['startTime'] as String,
        procedureKindId: m['procedureKindId'] as String,
        assistantId: m['assistantId'] as String?);
