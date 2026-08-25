import 'dart:async';
import 'dart:convert';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
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
import '../app_services.dart';
import '../features/procedure_sessions/procedure_session_dialog.dart';
import '../features/procedure_sessions/procedure_session_submit_result.dart';
import '../features/procedure_sessions/procedure_sessions_view_model.dart';
import '../features/directory/people_directory_table.dart';

enum DesktopWindowKind {
  main,
  procedureStatistics,
  procedureSession,
  freeTime,
  participants,
  assistants,
  procedureKinds,
  workdays,
  procedureKindEditor,
  workdayEditor,
}

typedef DirectoryChangedCallback = Future<void> Function(String directory);

const _mainChannel = WindowMethodChannel(
  'bochki_schedule/main_window',
  mode: ChannelMode.unidirectional,
);

WindowConfiguration childWindowConfiguration(String arguments) =>
    WindowConfiguration(arguments: arguments, hiddenAtLaunch: true);

DesktopWindowKind windowKindFromArguments(String value) {
  return windowDescriptorFromArguments(value).kind;
}

final class DesktopWindowDescriptor {
  const DesktopWindowDescriptor({
    required this.kind,
    this.parentWindowId,
    this.ancestorWindowIds = const [],
  });

  final DesktopWindowKind kind;
  final String? parentWindowId;
  final List<String> ancestorWindowIds;
}

DesktopWindowDescriptor windowDescriptorFromArguments(String value) {
  try {
    final values = Map<String, dynamic>.from(jsonDecode(value) as Map);
    return DesktopWindowDescriptor(
      kind: DesktopWindowKind.values.byName(values['kind'] as String),
      parentWindowId: values['parentWindowId'] as String?,
      ancestorWindowIds: List<String>.from(
        values['ancestorWindowIds'] as List? ?? const [],
      ),
    );
  } catch (_) {
    return const DesktopWindowDescriptor(kind: DesktopWindowKind.main);
  }
}

Future<Map<String, double>> currentWindowBoundsMap() async {
  final bounds = await windowManager.getBounds();
  return {
    'left': bounds.left,
    'top': bounds.top,
    'width': bounds.width,
    'height': bounds.height,
  };
}

Rect windowBoundsFromMap(Map<dynamic, dynamic> values) => Rect.fromLTWH(
      (values['left'] as num).toDouble(),
      (values['top'] as num).toDouble(),
      (values['width'] as num).toDouble(),
      (values['height'] as num).toDouble(),
    );

Offset centeredWindowPosition({
  required Rect workArea,
  required Size windowSize,
}) =>
    Offset(
      workArea.left + (workArea.width - windowSize.width) / 2,
      workArea.top + (workArea.height - windowSize.height) / 2,
    );

/// Returns descendants in close order: deepest windows first.
List<String> descendantWindowIdsInCloseOrder({
  required String parentWindowId,
  required Map<String, String> parentWindowIds,
}) {
  final result = <String>[];
  final visited = <String>{};
  void visit(String parentId) {
    for (final entry
        in parentWindowIds.entries.where((entry) => entry.value == parentId)) {
      if (!visited.add(entry.key)) continue;
      visit(entry.key);
      result.add(entry.key);
    }
  }

  visit(parentWindowId);
  return result;
}

DesktopWindowLifecycle? _windowLifecycle;

Future<void> initializeDesktopWindowLifecycle() async {
  _windowLifecycle ??= DesktopWindowLifecycle();
  await _windowLifecycle!.initialize();
}

Future<void> closeCurrentDesktopWindow({bool cascade = false}) async {
  final lifecycle = _windowLifecycle;
  if (lifecycle == null) return windowManager.close();
  await lifecycle.close(cascade: cascade);
}

/// Coordinates native close events in one Flutter engine.  The window list and
/// `parentWindowId` arguments are the shared source of truth across engines.
final class DesktopWindowLifecycle with WindowListener {
  WindowController? _current;
  bool _initialized = false;
  bool _closing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _current = await WindowController.fromCurrentEngine();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    await _current!.setWindowMethodHandler(_handleControlCall);
    _initialized = true;
  }

  Future<dynamic> _handleControlCall(MethodCall call) async {
    switch (call.method) {
      case 'window_focus':
        await windowManager.focus();
        return;
      case 'window_close':
        await close(cascade: (call.arguments as Map?)?['cascade'] == true);
        return;
      case 'window_bounds':
        return currentWindowBoundsMap();
      default:
        throw MissingPluginException('Unknown window lifecycle method');
    }
  }

  @override
  void onWindowClose() => unawaited(close());

  Future<void> close({bool cascade = false}) async {
    if (_closing) return;
    _closing = true;
    try {
      final current = _current;
      if (current != null) {
        await _closeDescendants(current.windowId);
        if (!cascade) await _activateParent(current.windowId);
      }
      await windowManager.setPreventClose(false);
      await windowManager.close();
    } catch (_) {
      _closing = false;
      rethrow;
    }
  }

  Future<void> _closeDescendants(String parentWindowId) async {
    final windows = await WindowController.getAll();
    final byId = {for (final window in windows) window.windowId: window};
    final parentIds = {
      for (final window in windows)
        if (windowDescriptorFromArguments(window.arguments).parentWindowId
            case final parentId?)
          window.windowId: parentId,
    };
    for (final id in descendantWindowIdsInCloseOrder(
      parentWindowId: parentWindowId,
      parentWindowIds: parentIds,
    )) {
      await byId[id]?.invokeMethod<void>('window_close', {'cascade': true});
    }
  }

  Future<void> _activateParent(String currentWindowId) async {
    final windows = await WindowController.getAll();
    final byId = {for (final window in windows) window.windowId: window};
    final current = byId[currentWindowId];
    final descriptor = current == null
        ? null
        : windowDescriptorFromArguments(current.arguments);
    final parentIds = [
      if (descriptor?.parentWindowId case final parentId?) parentId,
      if (descriptor != null) ...descriptor.ancestorWindowIds,
    ];
    final parent = parentIds
        .map((parentId) => byId[parentId])
        .whereType<WindowController>()
        .firstOrNull;
    final fallback = windows.where((window) =>
        windowDescriptorFromArguments(window.arguments).kind ==
        DesktopWindowKind.main);
    final target = parent ?? (fallback.isEmpty ? null : fallback.first);
    if (target == null) return;
    await target.show();
    await target.invokeMethod<void>('window_focus');
  }
}

/// Runs only in the main window. Child windows never initialize repositories.
final class DesktopWindowCoordinator {
  DesktopWindowCoordinator({
    required AppServices services,
    required BuildProcedureStatisticsTableUseCase statistics,
    required BuildScheduleGapsUseCase scheduleGaps,
    required ProcedureSessionsViewModel sessions,
    required DirectoryChangedCallback onDirectoryChanged,
  })  : _services = services,
        _statistics = statistics,
        _scheduleGaps = scheduleGaps,
        _sessions = sessions,
        _onDirectoryChanged = onDirectoryChanged;

  final AppServices _services;
  final BuildProcedureStatisticsTableUseCase _statistics;
  final BuildScheduleGapsUseCase _scheduleGaps;
  final ProcedureSessionsViewModel _sessions;
  final DirectoryChangedCallback _onDirectoryChanged;
  ProcedureSessionRaw? _sessionDraft;
  String? _mainWindowId;

  Future<void> start() async {
    _mainWindowId = (await WindowController.fromCurrentEngine()).windowId;
    await _mainChannel.setMethodCallHandler(_handleCall);
  }

  Future<void> dispose() => _mainChannel.setMethodCallHandler(null);

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

  Future<void> openDirectory(DesktopWindowKind kind) => _open(kind);

  Future<void> openDirectoryEditor(
    DesktopWindowKind kind, {
    String? entryId,
    String? parentWindowId,
  }) =>
      _open(kind, entryId: entryId, parentWindowId: parentWindowId);

  Future<void> _open(
    DesktopWindowKind kind, {
    String? entryId,
    String? parentWindowId,
  }) async {
    final existing = (await WindowController.getAll()).where(
      (controller) => windowKindFromArguments(controller.arguments) == kind,
    );
    if (existing.isNotEmpty) {
      await existing.first.show();
      await existing.first.invokeMethod<void>('window_focus');
      return;
    }
    await WindowController.create(
      childWindowConfiguration(
        jsonEncode(await _windowArguments(
          kind: kind,
          entryId: entryId,
          parentWindowId: parentWindowId ?? _mainWindowId,
        )),
      ),
    );
  }

  Future<Map<String, dynamic>> _windowArguments({
    required DesktopWindowKind kind,
    required String? entryId,
    required String? parentWindowId,
  }) async {
    final parent = parentWindowId == null
        ? null
        : (await WindowController.getAll())
            .where((window) => window.windowId == parentWindowId)
            .firstOrNull;
    final ancestors = parent == null
        ? const <String>[]
        : windowDescriptorFromArguments(parent.arguments).ancestorWindowIds;
    return {
      'kind': kind.name,
      if (parentWindowId != null) 'parentWindowId': parentWindowId,
      'ancestorWindowIds': [
        if (parentWindowId != null) parentWindowId,
        ...ancestors,
      ],
      if (entryId != null) 'entryId': entryId,
    };
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
      case 'directorySnapshot':
        return _directorySnapshot(call.arguments as String);
      case 'directoryMutate':
        return _directoryMutate(
            Map<String, dynamic>.from(call.arguments as Map));
      case 'openDirectoryEditor':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        await openDirectoryEditor(
          DesktopWindowKind.values.byName(values['kind'] as String),
          entryId: values['entryId'] as String?,
          parentWindowId: values['parentWindowId'] as String?,
        );
        return null;
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
          'minimumTime': _sessions.programSettings.minimumTime.toJson(),
          'maximumTime': _sessions.programSettings.maximumTime.toJson(),
          'lunchStart': _sessions.programSettings.lunchStart.toJson(),
          'lunchEnd': _sessions.programSettings.lunchEnd.toJson(),
        },
      };

  Future<Map<String, dynamic>> _directorySnapshot(String directory) async {
    switch (directory) {
      case 'participants':
        return {
          'entries': (await _services.listParticipantsUseCase.execute())
              .map((entry) => {'id': entry.id, 'name': entry.name})
              .toList()
        };
      case 'assistants':
        return {
          'entries': (await _services.listAssistantsUseCase.execute())
              .map(_assistantMap)
              .toList()
        };
      case 'procedureKinds':
        return {
          'entries': (await _services.listProcedureKindsUseCase.execute())
              .map(_kindMap)
              .toList()
        };
      case 'workdays':
        return {
          'entries': (await _services.listWorkdaysUseCase.execute())
              .map(_workdayMap)
              .toList()
        };
      default:
        throw ArgumentError.value(directory, 'directory');
    }
  }

  Future<Map<String, dynamic>> _directoryMutate(
      Map<String, dynamic> values) async {
    final directory = values['directory'] as String;
    final action = values['action'] as String;
    final entry =
        Map<String, dynamic>.from(values['entry'] as Map? ?? const {});
    try {
      switch (directory) {
        case 'participants':
          if (action == 'delete')
            await _services.deleteParticipantUseCase
                .execute(values['id'] as String);
          if (action == 'create')
            await _services.createParticipantUseCase
                .execute(entry['name'] as String);
          if (action == 'update')
            await _services.updateParticipantUseCase.execute(
                participantId: values['id'] as String,
                rawName: entry['name'] as String);
          break;
        case 'assistants':
          if (action == 'delete')
            await _services.deleteAssistantUseCase
                .execute(values['id'] as String);
          if (action == 'create')
            await _services.createAssistantUseCase.execute(
              entry['name'] as String,
              rawShortName: entry['shortName'] as String?,
            );
          if (action == 'update')
            await _services.updateAssistantUseCase.execute(
                assistantId: values['id'] as String,
                rawName: entry['name'] as String,
                rawShortName: entry['shortName'] as String?);
          break;
        case 'procedureKinds':
          final kind =
              _kindFromMap({...entry, 'id': values['id'] as String? ?? 'new'});
          if (action == 'delete')
            await _services.deleteProcedureKindUseCase
                .execute(values['id'] as String);
          if (action == 'create')
            await _services.createProcedureKindUseCase.execute(kind);
          if (action == 'update')
            await _services.updateProcedureKindUseCase.execute(kind);
          break;
        case 'workdays':
          final day = _workdayFromMap(
              {...entry, 'id': values['id'] as String? ?? 'new'});
          if (action == 'delete')
            await _services.deleteWorkdayUseCase
                .execute(values['id'] as String);
          if (action == 'create')
            await _services.createWorkdayUseCase.execute(day);
          if (action == 'update')
            await _services.updateWorkdayUseCase.execute(day);
          break;
        default:
          throw ArgumentError.value(directory, 'directory');
      }
      await _notifyDirectoryChanged(directory);
      return {'ok': true};
    } catch (error) {
      return {'ok': false, 'error': error.toString()};
    }
  }

  Future<void> _notifyDirectoryChanged(String directory) async {
    await _onDirectoryChanged(directory);
    await _sessions.load();
    for (final controller in await WindowController.getAll()) {
      if (windowKindFromArguments(controller.arguments) !=
          DesktopWindowKind.main) {
        await controller.invokeMethod<void>('directory_changed', directory);
      }
    }
  }
}

Future<void> configureChildWindow(DesktopWindowKind kind) async {
  await windowManager.ensureInitialized();
  await initializeDesktopWindowLifecycle();
  final isStatistics = kind == DesktopWindowKind.procedureStatistics;
  final isFreeTime = kind == DesktopWindowKind.freeTime;
  final title = switch (kind) {
    DesktopWindowKind.procedureStatistics => 'Статистика процедур',
    DesktopWindowKind.freeTime => 'Свободное время',
    DesktopWindowKind.procedureSession => 'Назначить процедуру',
    DesktopWindowKind.participants => 'Участники',
    DesktopWindowKind.assistants => 'Ассистенты',
    DesktopWindowKind.procedureKinds => 'Процедуры',
    DesktopWindowKind.workdays => 'Дни',
    DesktopWindowKind.procedureKindEditor => 'Процедура',
    DesktopWindowKind.workdayEditor => 'День',
    DesktopWindowKind.main => 'ПО Расписание Бочки',
  };
  final isDirectory = switch (kind) {
    DesktopWindowKind.participants ||
    DesktopWindowKind.assistants ||
    DesktopWindowKind.procedureKinds ||
    DesktopWindowKind.workdays =>
      true,
    _ => false,
  };
  final isEditor = kind == DesktopWindowKind.procedureKindEditor ||
      kind == DesktopWindowKind.workdayEditor;
  final options = WindowOptions(
    title: title,
    size: isStatistics || isFreeTime
        ? const Size(1080, 514)
        : isDirectory
            ? const Size(920, 640)
            : isEditor
                ? const Size(650, 500)
                : const Size(900, 680),
    minimumSize: isStatistics || isFreeTime
        ? const Size(1080, 420)
        : isEditor
            ? const Size(600, 420)
            : const Size(700, 500),
    center: false,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPosition(
      await childWindowPositionOnParentDisplay(options.size!),
    );
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
        await closeCurrentDesktopWindow(
          cascade: (call.arguments as Map?)?['cascade'] == true,
        );
        return null;
      case 'window_bounds':
        return currentWindowBoundsMap();
      default:
        throw MissingPluginException('Unknown window method ${call.method}');
    }
  });
}

Future<Offset> childWindowPositionOnParentDisplay(Size windowSize) async {
  final current = await WindowController.fromCurrentEngine();
  final descriptor = windowDescriptorFromArguments(current.arguments);
  final windows = await WindowController.getAll();
  final parent = descriptor.parentWindowId == null
      ? null
      : windows
          .where((window) => window.windowId == descriptor.parentWindowId)
          .firstOrNull;
  Rect? parentBounds;
  if (parent != null) {
    try {
      final result = await parent.invokeMethod<Map>('window_bounds');
      if (result != null) parentBounds = windowBoundsFromMap(result);
    } catch (_) {
      // Fall back to the primary display if the parent is no longer available.
    }
  }
  final primary = await screenRetriever.getPrimaryDisplay();
  final displays = await screenRetriever.getAllDisplays();
  final display = displayForParentBounds(
    primaryDisplay: primary,
    displays: displays,
    parentBounds: parentBounds,
  );
  return centeredWindowPosition(
    workArea: displayWorkArea(display),
    windowSize: windowSize,
  );
}

Display displayForParentBounds({
  required Display primaryDisplay,
  required List<Display> displays,
  required Rect? parentBounds,
}) {
  final parentCenter = parentBounds?.center;
  if (parentCenter == null) return primaryDisplay;
  return displays.firstWhere(
    (display) => displayWorkArea(display).contains(parentCenter),
    orElse: () => primaryDisplay,
  );
}

Rect displayWorkArea(Display display) {
  final position = display.visiblePosition ?? Offset.zero;
  final size = display.visibleSize ?? display.size;
  return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
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
          await closeCurrentDesktopWindow(
            cascade: (call.arguments as Map?)?['cascade'] == true,
          );
          return null;
        case 'window_bounds':
          return currentWindowBoundsMap();
        case 'statistics_changed':
        case 'directory_changed':
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
      if (call.method == 'free_time_changed' ||
          call.method == 'directory_changed') {
        await _load();
        return null;
      }
      if (call.method == 'window_close') {
        await closeCurrentDesktopWindow(
          cascade: (call.arguments as Map?)?['cascade'] == true,
        );
        return null;
      }
      if (call.method == 'window_bounds') return currentWindowBoundsMap();
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
                    : FreeTimeResultsTable(
                        gaps: _gaps,
                        onOccupy: (gap) {
                          final day = _workdayFromMap(
                              Map<String, dynamic>.from(gap['day'] as Map));
                          final human = _humanFromMap(
                              Map<String, dynamic>.from(gap['human'] as Map));
                          return _mainChannel
                              .invokeMethod<void>('openProcedureSession', {
                            'dayId': day.id,
                            'participantId': human.id,
                            'startTime': gap['start'] as String,
                          });
                        },
                      )),
      ])));
}

class FreeTimeResultsTable extends StatefulWidget {
  const FreeTimeResultsTable({
    required this.gaps,
    required this.onOccupy,
    super.key,
  });

  final List<Map<String, dynamic>> gaps;
  final Future<void> Function(Map<String, dynamic> gap) onOccupy;

  @override
  State<FreeTimeResultsTable> createState() => _FreeTimeResultsTableState();
}

class _FreeTimeResultsTableState extends State<FreeTimeResultsTable> {
  final _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
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
              rows: widget.gaps.map((gap) {
                final day = _workdayFromMap(
                    Map<String, dynamic>.from(gap['day'] as Map));
                final human = _humanFromMap(
                    Map<String, dynamic>.from(gap['human'] as Map));
                return DataRow(cells: [
                  DataCell(Text(day.name)),
                  DataCell(Text(human.name)),
                  DataCell(Text(gap['start'] as String)),
                  DataCell(Text(gap['end'] as String)),
                  DataCell(Text(gap['duration'] as String)),
                  DataCell(FilledButton.tonal(
                    onPressed: () => widget.onOccupy(gap),
                    child: const Text('Занять участника'),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      );
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
    _listen();
    _load();
  }

  Future<void> _listen() async {
    final controller = await WindowController.fromCurrentEngine();
    await controller.setWindowMethodHandler(_handleWindowMethod);
  }

  Future<dynamic> _handleWindowMethod(MethodCall call) async {
    if (call.method == 'directory_changed') {
      await _load();
      return null;
    }
    if (call.method == 'window_close') {
      return closeCurrentDesktopWindow(
        cascade: (call.arguments as Map?)?['cascade'] == true,
      );
    }
    if (call.method == 'window_bounds') return currentWindowBoundsMap();
    if (call.method == 'window_focus') return windowManager.focus();
    throw MissingPluginException('Unknown procedure-session-window method');
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
              minimumTime:
                  ProgramSettingsTime.fromJson(settings['minimumTime']),
              maximumTime:
                  ProgramSettingsTime.fromJson(settings['maximumTime']),
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
              await closeCurrentDesktopWindow();
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
    {'id': d.id, 'name': d.name, 'date': _formatCalendarDate(d.calendarDate)};
Workday _workdayFromMap(Map<String, dynamic> m) => Workday(
    id: m['id'] as String,
    name: m['name'] as String,
    calendarDate: DateTime.parse(m['date'] as String));

String _formatCalendarDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

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
        participantId: m['participantId'] as String?,
        startTime: m['startTime'] as String,
        procedureKindId: m['procedureKindId'] as String,
        assistantId: m['assistantId'] as String?);

/// A lightweight IPC client for directory windows.  Data and mutations stay in
/// the main engine, which owns the project document and its synchronizer.
class DirectoryChildWindow extends StatefulWidget {
  const DirectoryChildWindow({super.key});

  @override
  State<DirectoryChildWindow> createState() => _DirectoryChildWindowState();
}

class _DirectoryChildWindowState extends State<DirectoryChildWindow> {
  DesktopWindowKind? _kind;
  String? _entryId;
  List<Map<String, dynamic>> _entries = const [];
  String? _selectedId;
  bool _loading = true;
  bool _saving = false;
  bool _hasModalChild = false;
  StreamSubscription<void>? _windowsSubscription;
  String? _error;
  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _date = TextEditingController();
  final _capacity = TextEditingController(text: '1');
  final _participantTime = TextEditingController();
  String _patternId = 'curated';

  bool get _isEditor =>
      _kind == DesktopWindowKind.procedureKindEditor ||
      _kind == DesktopWindowKind.workdayEditor;
  bool get _isPeopleDirectory =>
      _kind == DesktopWindowKind.participants ||
      _kind == DesktopWindowKind.assistants;
  String get _directory => switch (_kind) {
        DesktopWindowKind.participants => 'participants',
        DesktopWindowKind.assistants => 'assistants',
        DesktopWindowKind.procedureKinds ||
        DesktopWindowKind.procedureKindEditor =>
          'procedureKinds',
        DesktopWindowKind.workdays ||
        DesktopWindowKind.workdayEditor =>
          'workdays',
        _ => throw StateError('Not a directory window'),
      };

  @override
  void initState() {
    super.initState();
    _initialize();
    _windowsSubscription = onWindowsChanged.listen((_) => _refreshModalChild());
  }

  Future<void> _initialize() async {
    final controller = await WindowController.fromCurrentEngine();
    final args =
        Map<String, dynamic>.from(jsonDecode(controller.arguments) as Map);
    _kind = DesktopWindowKind.values.byName(args['kind'] as String);
    _entryId = args['entryId'] as String?;
    await _refreshModalChild();
    await controller.setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_focus':
          await windowManager.focus();
          return null;
        case 'window_close':
          await closeCurrentDesktopWindow(
            cascade: (call.arguments as Map?)?['cascade'] == true,
          );
          return null;
        case 'window_bounds':
          return currentWindowBoundsMap();
        case 'directory_changed':
          await _load();
          return null;
        default:
          throw MissingPluginException('Unknown directory-window method');
      }
    });
    await _load();
  }

  Future<void> _load() async {
    if (_kind == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = Map<String, dynamic>.from(await _mainChannel.invokeMethod(
          'directorySnapshot', _directory) as Map);
      _entries = _maps(result['entries']);
      if (_isEditor) {
        final entry = _entryId == null
            ? null
            : _entries.where((item) => item['id'] == _entryId).firstOrNull;
        _fillEditor(entry);
      }
    } catch (_) {
      _error = 'Не удалось загрузить данные.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshModalChild() async {
    if (_isEditor) return;
    final windows = await WindowController.getAll();
    final active = windows.any((window) {
      final kind = windowKindFromArguments(window.arguments);
      return (_kind == DesktopWindowKind.procedureKinds &&
              kind == DesktopWindowKind.procedureKindEditor) ||
          (_kind == DesktopWindowKind.workdays &&
              kind == DesktopWindowKind.workdayEditor);
    });
    if (mounted && active != _hasModalChild)
      setState(() => _hasModalChild = active);
  }

  void _fillEditor(Map<String, dynamic>? entry) {
    _name.text = entry?['name'] as String? ?? '';
    _shortName.text = entry?['shortName'] as String? ?? '';
    _date.text = entry?['date'] as String? ?? '';
    _capacity.text = '${entry?['capacity'] ?? 1}';
    _participantTime.text = '${entry?['participantBusyTime'] ?? ''}';
    _patternId = entry?['patternId'] as String? ?? 'curated';
  }

  Future<void> _mutate(String action,
      {String? id, Map<String, dynamic>? entry}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = Map<String, dynamic>.from(
          await _mainChannel.invokeMethod('directoryMutate', {
        'directory': _directory,
        'action': action,
        if (id != null) 'id': id,
        'entry': entry ?? <String, dynamic>{},
      }) as Map);
      if (result['ok'] != true) throw StateError(result['error']);
      if (_isEditor) {
        await closeCurrentDesktopWindow();
        return;
      }
      _selectedId = id;
      await _load();
    } catch (error) {
      if (mounted)
        setState(
            () => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditor(String editorKind, [String? id]) async {
    final current = await WindowController.fromCurrentEngine();
    await _mainChannel.invokeMethod('openDirectoryEditor', {
      'kind': editorKind,
      'parentWindowId': current.windowId,
      if (id != null) 'entryId': id,
    });
  }

  @override
  void dispose() {
    _windowsSubscription?.cancel();
    _name.dispose();
    _shortName.dispose();
    _date.dispose();
    _capacity.dispose();
    _participantTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kind == null || _loading)
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: AbsorbPointer(
          absorbing: _hasModalChild,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isEditor ? _editor() : _directoryList(),
          ),
        ),
      ),
    );
  }

  String get _title => switch (_kind) {
        DesktopWindowKind.participants => 'Участники',
        DesktopWindowKind.assistants => 'Ассистенты',
        DesktopWindowKind.procedureKinds => 'Процедуры',
        DesktopWindowKind.workdays => 'Дни',
        DesktopWindowKind.procedureKindEditor =>
          _entryId == null ? 'Новая процедура' : 'Редактирование процедуры',
        DesktopWindowKind.workdayEditor =>
          _entryId == null ? 'Новый день' : 'Редактирование дня',
        _ => '',
      };

  Widget _directoryList() {
    if (_isPeopleDirectory) {
      return PeopleDirectoryTable(
        type: _kind == DesktopWindowKind.participants
            ? PeopleDirectoryType.participants
            : PeopleDirectoryType.assistants,
        entries: _entries
            .map(
              (entry) => PeopleDirectoryEntry(
                id: entry['id'] as String,
                name: entry['name'] as String,
                shortName: entry['shortName'] as String?,
              ),
            )
            .toList(growable: false),
        onMutate: _mutatePeople,
        onChanged: _load,
      );
    }
    return _legacyDirectoryList();
  }

  Future<String?> _mutatePeople(
    String action, {
    String? id,
    String? name,
    String? shortName,
  }) async {
    try {
      final result = Map<String, dynamic>.from(
        await _mainChannel.invokeMethod('directoryMutate', {
          'directory': _directory,
          'action': action,
          if (id != null) 'id': id,
          'entry': {
            if (name != null) 'name': name,
            if (shortName != null) 'shortName': shortName,
          },
        }) as Map,
      );
      return result['ok'] == true
          ? null
          : result['error'] as String? ?? 'Не удалось сохранить изменения.';
    } catch (_) {
      return 'Не удалось сохранить изменения.';
    }
  }

  Widget _legacyDirectoryList() => Column(children: [
        Row(children: [
          FilledButton.tonal(
              onPressed: _saving
                  ? null
                  : () {
                      if (_kind == DesktopWindowKind.procedureKinds) {
                        _openEditor(DesktopWindowKind.procedureKindEditor.name);
                      } else if (_kind == DesktopWindowKind.workdays) {
                        _openEditor(DesktopWindowKind.workdayEditor.name);
                      } else {
                        _name.clear();
                        _shortName.clear();
                        _showInlineEditor();
                      }
                    },
              child: Text(_kind == DesktopWindowKind.workdays
                  ? 'Создать'
                  : 'Добавить')),
        ]),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
        Expanded(
            child: ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final entry = _entries[i];
                  final id = entry['id'] as String;
                  return ListTile(
                    selected: _selectedId == id,
                    title: Text(entry['name'] as String),
                    subtitle: Text(_subtitle(entry)),
                    onTap: () => setState(() => _selectedId = id),
                    trailing: Wrap(children: [
                      TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_kind == DesktopWindowKind.procedureKinds)
                                    _openEditor(
                                        DesktopWindowKind
                                            .procedureKindEditor.name,
                                        id);
                                  else if (_kind == DesktopWindowKind.workdays)
                                    _openEditor(
                                        DesktopWindowKind.workdayEditor.name,
                                        id);
                                  else {
                                    _name.text = entry['name'] as String;
                                    _shortName.text =
                                        entry['shortName'] as String? ?? '';
                                    _selectedId = id;
                                    _showInlineEditor();
                                  }
                                },
                          child: const Text('Изменить')),
                      TextButton(
                          onPressed:
                              _saving ? null : () => _mutate('delete', id: id),
                          child: const Text('Удалить')),
                    ]),
                  );
                })),
      ]);

  String _subtitle(Map<String, dynamic> entry) => switch (_kind) {
        DesktopWindowKind.assistants => 'Краткое имя: ${entry['shortName']}',
        DesktopWindowKind.procedureKinds =>
          'Емкость: ${entry['capacity']}; время участника: ${entry['participantBusyTime']} мин.',
        DesktopWindowKind.workdays => entry['date'] as String,
        _ => '',
      };

  Future<void> _showInlineEditor() async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title:
                  Text(_selectedId == null ? 'Новая запись' : 'Редактирование'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Имя')),
                if (_kind == DesktopWindowKind.assistants)
                  TextField(
                      controller: _shortName,
                      decoration:
                          const InputDecoration(labelText: 'Краткое имя')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Отмена')),
                FilledButton(
                    onPressed: () async {
                      await _mutate(_selectedId == null ? 'create' : 'update',
                          id: _selectedId,
                          entry: {
                            'name': _name.text,
                            'shortName': _shortName.text
                          });
                      if (mounted && _error == null)
                        Navigator.pop(dialogContext);
                    },
                    child: const Text('Сохранить'))
              ],
            ));
  }

  Widget _editor() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: _name,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Название')),
        const SizedBox(height: 12),
        if (_kind == DesktopWindowKind.procedureKindEditor) ...[
          DropdownButtonFormField<String>(
            value: _patternId,
            decoration: const InputDecoration(labelText: 'Тип процедуры'),
            items: const [
              DropdownMenuItem(
                value: 'curated',
                child: Text('С сопровождением'),
              ),
              DropdownMenuItem(value: 'single', child: Text('Одиночная')),
              DropdownMenuItem(value: 'grouped', child: Text('Групповая')),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _patternId = value ?? _patternId),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _shortName,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Краткое название')),
          const SizedBox(height: 12),
          TextField(
              controller: _capacity,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Емкость')),
          const SizedBox(height: 12),
          TextField(
              controller: _participantTime,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Время участника, мин')),
        ] else
          TextField(
              controller: _date,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Дата (ISO 8601)')),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
              onPressed: _saving ? null : () => closeCurrentDesktopWindow(),
              child: const Text('Отмена')),
          const SizedBox(width: 12),
          FilledButton(
              onPressed: _saving
                  ? null
                  : () => _mutate(_entryId == null ? 'create' : 'update',
                      id: _entryId, entry: _editorEntry),
              child: Text(_entryId == null ? 'Создать' : 'Сохранить')),
        ]),
      ]);

  Map<String, dynamic> get _editorEntry =>
      _kind == DesktopWindowKind.procedureKindEditor
          ? {
              'name': _name.text,
              'shortName': _shortName.text,
              'patternId': _patternId,
              'capacity': int.tryParse(_capacity.text) ?? 0,
              'participantBusyTime': int.tryParse(_participantTime.text) ?? 0,
              'assistantBusyTime': null,
              'resourceBusyTime': null
            }
          : {'name': _name.text, 'date': _date.text};
}
