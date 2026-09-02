import 'dart:async';
import 'dart:convert';

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import '../features/procedure_kinds/ipc_procedure_kinds_operations.dart';
import '../features/procedure_kinds/procedure_kind_form_content.dart';
import '../features/procedure_kinds/procedure_kinds_dialog.dart';
import '../features/procedure_kinds/procedure_kinds_view_model.dart';
import '../features/directory/people_directory_table.dart';
import '../features/procedure_statistics/procedure_statistics_content.dart';

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

/// The main-window dispatcher exposes integration-test controls only in tests.
const desktopIntegrationTestEnabled = bool.fromEnvironment(
  'INTEGRATION_TEST',
);

WindowConfiguration childWindowConfiguration(String arguments) =>
    WindowConfiguration(arguments: arguments, hiddenAtLaunch: true);

DesktopWindowKind windowKindFromArguments(String value) {
  return windowDescriptorFromArguments(value).kind;
}

/// Whether a child window should prevent interaction with the main window.
///
/// A hidden procedure-session window deliberately remains alive, so it is
/// still returned by `WindowController.getAll()`. Its visibility therefore
/// needs to be considered separately from its existence.
bool isBlockingChildWindow({
  required DesktopWindowKind kind,
  required bool isProcedureSessionVisible,
}) =>
    kind != DesktopWindowKind.main &&
    (kind != DesktopWindowKind.procedureSession || isProcedureSessionVisible);

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

/// Keeps child-window geometry for the lifetime of the main-window engine.
///
/// The store deliberately has no persistence: window placement is a convenience
/// for the current application session, not part of a project document.
final class ChildWindowGeometryStore {
  final _boundsByKind = <DesktopWindowKind, Rect>{};

  Rect? operator [](DesktopWindowKind kind) => _boundsByKind[kind];

  void update(DesktopWindowKind kind, Rect bounds) {
    _boundsByKind[kind] = bounds;
  }
}

bool windowBoundsFitAnyDisplay({
  required Rect bounds,
  required Iterable<Display> displays,
}) =>
    displays.any((display) {
      final workArea = displayWorkArea(display);
      return bounds.left >= workArea.left &&
          bounds.top >= workArea.top &&
          bounds.right <= workArea.right &&
          bounds.bottom <= workArea.bottom;
    });

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

/// Starts a close request for every descendant without waiting for an IPC
/// response from any of them.
///
/// A child can be in the process of destroying its Flutter engine when its
/// parent is closed. Waiting for its method-channel response can therefore
/// indefinitely prevent the native close requested for the parent.
void requestDescendantWindowCloses({
  required Iterable<String> windowIds,
  required Future<void> Function(String windowId) requestClose,
  required void Function(
    String windowId,
    Object error,
    StackTrace stackTrace,
  ) onError,
}) {
  for (final windowId in windowIds) {
    unawaited(() async {
      try {
        await requestClose(windowId);
      } catch (error, stackTrace) {
        onError(windowId, error, stackTrace);
      }
    }());
  }
}

/// Schedules non-essential cross-window work, then closes the native window.
///
/// Closing the current native window is deliberately the only awaited action.
/// This keeps a stale or unresponsive peer window from vetoing a user's close
/// request.
Future<void> closeWindowAfterSchedulingCleanup({
  required Future<void> Function() requestDescendantCloses,
  Future<void> Function()? activateParent,
  required Future<void> Function() closeNativeWindow,
  required void Function(Object error, StackTrace stackTrace) onCleanupError,
}) async {
  void schedule(Future<void> Function() operation) {
    unawaited(() async {
      try {
        await operation();
      } catch (error, stackTrace) {
        onCleanupError(error, stackTrace);
      }
    }());
  }

  schedule(requestDescendantCloses);
  if (activateParent != null) {
    schedule(activateParent);
  }
  await closeNativeWindow();
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

/// Hides the procedure-session window without destroying its Flutter engine.
Future<void> hideCurrentProcedureSessionWindow() async {
  await windowManager.hide();
  try {
    await _mainChannel.invokeMethod<void>(
      'procedureSessionVisibilityChanged',
      false,
    );
  } catch (_) {
    // The main window may already be closing.
  }
}

/// Coordinates native close events in one Flutter engine.  The window list and
/// `parentWindowId` arguments are the shared source of truth across engines.
final class DesktopWindowLifecycle with WindowListener {
  WindowController? _current;
  bool _initialized = false;
  bool _closing = false;
  bool _savingGeometry = false;
  bool _geometrySavePending = false;

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
  void onWindowClose() {
    final current = _current;
    if (!_closing &&
        current != null &&
        windowKindFromArguments(current.arguments) ==
            DesktopWindowKind.procedureSession) {
      unawaited(hideCurrentProcedureSessionWindow());
      return;
    }
    unawaited(close());
  }

  @override
  void onWindowMove() => _scheduleGeometrySave();

  @override
  void onWindowResize() => _scheduleGeometrySave();

  void _scheduleGeometrySave() {
    _geometrySavePending = true;
    if (_savingGeometry) return;
    unawaited(_saveGeometry());
  }

  Future<void> _saveGeometry() async {
    _savingGeometry = true;
    try {
      while (_geometrySavePending) {
        _geometrySavePending = false;
        final current = _current;
        if (current == null) return;
        final descriptor = windowDescriptorFromArguments(current.arguments);
        if (descriptor.kind == DesktopWindowKind.main) return;
        try {
          await _mainChannel.invokeMethod<void>('childWindowGeometryChanged', {
            'kind': descriptor.kind.name,
            'bounds': await currentWindowBoundsMap(),
          });
        } catch (_) {
          // Geometry restoration is optional while the main window is closing.
        }
      }
    } finally {
      _savingGeometry = false;
    }
  }

  Future<void> close({bool cascade = false}) async {
    if (_closing) return;
    _closing = true;
    try {
      final current = _current;
      await closeWindowAfterSchedulingCleanup(
        requestDescendantCloses: current == null
            ? () async {}
            : () => _requestDescendantCloses(current.windowId),
        activateParent: current == null || cascade
            ? null
            : () => _activateParent(current.windowId),
        closeNativeWindow: _closeNativeWindow,
        onCleanupError: _reportCleanupError,
      );
    } catch (_) {
      _closing = false;
      rethrow;
    }
  }

  Future<void> _closeNativeWindow() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<void> _requestDescendantCloses(String parentWindowId) async {
    final windows = await WindowController.getAll();
    final byId = {for (final window in windows) window.windowId: window};
    final parentIds = {
      for (final window in windows)
        if (windowDescriptorFromArguments(window.arguments).parentWindowId
            case final parentId?)
          window.windowId: parentId,
    };
    requestDescendantWindowCloses(
      windowIds: descendantWindowIdsInCloseOrder(
        parentWindowId: parentWindowId,
        parentWindowIds: parentIds,
      ),
      requestClose: (id) =>
          byId[id]!.invokeMethod<void>('window_close', {'cascade': true}),
      onError: (windowId, error, stackTrace) => _reportCleanupError(
        error,
        stackTrace,
        context: 'while requesting close for descendant window $windowId',
      ),
    );
  }

  void _reportCleanupError(
    Object error,
    StackTrace stackTrace, {
    String context = 'while performing window close cleanup',
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'desktop windows',
        context: ErrorDescription(context),
      ),
    );
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
    required ValueChanged<bool> onProcedureSessionVisibilityChanged,
  })  : _services = services,
        _statistics = statistics,
        _scheduleGaps = scheduleGaps,
        _sessions = sessions,
        _onDirectoryChanged = onDirectoryChanged,
        _onProcedureSessionVisibilityChanged =
            onProcedureSessionVisibilityChanged;

  final AppServices _services;
  final BuildProcedureStatisticsTableUseCase _statistics;
  final BuildScheduleGapsUseCase _scheduleGaps;
  final ProcedureSessionsViewModel _sessions;
  final DirectoryChangedCallback _onDirectoryChanged;
  final ValueChanged<bool> _onProcedureSessionVisibilityChanged;
  final _childWindowGeometry = ChildWindowGeometryStore();
  ProcedureSessionRaw? _sessionDraft;
  String? _mainWindowId;
  bool _isProcedureSessionVisible = false;

  bool get isProcedureSessionVisible => _isProcedureSessionVisible;

  Future<void> start() async {
    _mainWindowId = (await WindowController.fromCurrentEngine()).windowId;
    await _mainChannel.setMethodCallHandler(_handleCall);
  }

  Future<void> dispose() => _mainChannel.setMethodCallHandler(null);

  Future<void> openStatistics() async {
    await _sessions.load();
    await _open(DesktopWindowKind.procedureStatistics);
  }

  Future<void> openSession({ProcedureSessionRaw? initialValue}) async {
    await _sessions.load();
    _sessionDraft = initialValue;
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
      if (kind == DesktopWindowKind.procedureSession &&
          !_isProcedureSessionVisible) {
        await existing.first.invokeMethod<void>('procedure_session_show');
        return;
      }
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
    if (kind == DesktopWindowKind.procedureSession) {
      _setProcedureSessionVisible(true);
    }
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
          initialValue: values == null
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
      case 'workdayReferences':
        return _services.deleteWorkdayUseCase
            .countReferences(call.arguments as String);
      case 'directoryReferences':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        return _directoryReferences(
          values['directory'] as String,
          values['id'] as String,
        );
      case 'openDirectoryEditor':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        await openDirectoryEditor(
          DesktopWindowKind.values.byName(values['kind'] as String),
          entryId: values['entryId'] as String?,
          parentWindowId: values['parentWindowId'] as String?,
        );
        return null;
      case 'childWindowGeometry':
        final kind = DesktopWindowKind.values.byName(call.arguments as String);
        final bounds = _childWindowGeometry[kind];
        return bounds == null
            ? null
            : {
                'left': bounds.left,
                'top': bounds.top,
                'width': bounds.width,
                'height': bounds.height,
              };
      case 'childWindowGeometryChanged':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        _childWindowGeometry.update(
          DesktopWindowKind.values.byName(values['kind'] as String),
          windowBoundsFromMap(values['bounds'] as Map),
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
          'operationId': result.operationId,
          'conflictMessages': result.conflictMessages,
          'errorMessage': result.errorMessage,
        };
      case 'procedureSessionRendered':
        final operationId = call.arguments as int;
        await WidgetsBinding.instance.endOfFrame;
        await _sessions.logRenderedSave(operationId);
        return null;
      case 'procedureSessionVisibilityChanged':
        _setProcedureSessionVisible(call.arguments as bool);
        if (call.arguments == false) await _focusMainWindow();
        return null;
      case 'integrationTestRunMultiWindowLifecycle':
        if (!desktopIntegrationTestEnabled) {
          throw MissingPluginException('Unknown main-window method');
        }
        return _runIntegrationTestMultiWindowLifecycle();
      case 'integrationTestReady':
        if (!desktopIntegrationTestEnabled) {
          throw MissingPluginException('Unknown main-window method');
        }
        return true;
      case 'integrationTestShutdownMultiWindowLifecycle':
        if (!desktopIntegrationTestEnabled) {
          throw MissingPluginException('Unknown main-window method');
        }
        final sessions = (await WindowController.getAll()).where(
          (window) =>
              windowKindFromArguments(window.arguments) ==
              DesktopWindowKind.procedureSession,
        );
        for (final session in sessions) {
          await session.invokeMethod<void>('window_close', {'cascade': true});
        }
        await _waitUntil(() async => !(await WindowController.getAll()).any(
              (window) =>
                  windowKindFromArguments(window.arguments) ==
                  DesktopWindowKind.procedureSession,
            ));
        return null;
      default:
        throw MissingPluginException(
            'Unknown main-window method ${call.method}');
    }
  }

  Future<Map<String, dynamic>> _runIntegrationTestMultiWindowLifecycle() async {
    await openSession();
    final session = await _singleWindow(DesktopWindowKind.procedureSession);
    final sessionId = session.windowId;
    await _waitForChildLifecycleReady(session);
    await session.invokeMethod<void>('integration_test_hide');
    await _waitUntil(() => !_isProcedureSessionVisible);

    await openSession();
    final reopenedSession =
        await _singleWindow(DesktopWindowKind.procedureSession);
    final sessionReused = reopenedSession.windowId == sessionId;
    await _waitForChildLifecycleReady(reopenedSession);
    await reopenedSession.invokeMethod<void>('integration_test_hide');
    await _waitUntil(() => !_isProcedureSessionVisible);

    await openFreeTime();
    final freeTime = await _singleWindow(DesktopWindowKind.freeTime);
    final freeTimeId = freeTime.windowId;
    await _waitForChildLifecycleReady(freeTime);
    await freeTime.invokeMethod<void>('window_close', {'cascade': true});
    await _waitUntil(() async => !(await WindowController.getAll())
        .any((window) => window.windowId == freeTimeId));

    return {
      'procedureWindowId': sessionId,
      'procedureWindowReused': sessionReused,
      'ordinaryWindowClosed': true,
    };
  }

  Future<WindowController> _singleWindow(DesktopWindowKind kind) async {
    await _waitUntil(() async => (await WindowController.getAll()).any(
          (window) => windowKindFromArguments(window.arguments) == kind,
        ));
    return (await WindowController.getAll()).firstWhere(
      (window) => windowKindFromArguments(window.arguments) == kind,
    );
  }

  Future<void> _waitForChildLifecycleReady(WindowController window) =>
      _waitUntil(() async {
        try {
          return await window.invokeMethod<bool>('integration_test_ready') ==
              true;
        } on WindowChannelException catch (error) {
          if (error.code == 'CHANNEL_UNREGISTERED') return false;
          rethrow;
        }
      });

  Future<void> _waitUntil(FutureOr<bool> Function() predicate) async {
    for (var attempt = 0; attempt < 100; attempt += 1) {
      if (await predicate()) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('Timed out waiting for desktop window lifecycle state');
  }

  void _setProcedureSessionVisible(bool value) {
    if (_isProcedureSessionVisible == value) return;
    _isProcedureSessionVisible = value;
    _onProcedureSessionVisibilityChanged(value);
  }

  Future<void> _focusMainWindow() async {
    final mainWindowId = _mainWindowId;
    if (mainWindowId == null) return;
    final windows = await WindowController.getAll();
    final main = windows.where((window) => window.windowId == mainWindowId);
    if (main.isEmpty) return;
    await main.first.show();
    await main.first.invokeMethod<void>('window_focus');
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

  Future<int> _directoryReferences(String directory, String id) =>
      switch (directory) {
        'participants' =>
          _services.deleteParticipantUseCase.countReferences(id),
        'assistants' => _services.deleteAssistantUseCase.countReferences(id),
        'procedureKinds' =>
          _services.deleteProcedureKindUseCase.countReferences(id),
        'workdays' => _services.deleteWorkdayUseCase.countReferences(id),
        _ => throw ArgumentError.value(directory, 'directory'),
      };

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
          await mutateProcedureKindDirectory(
            action: action,
            id: values['id'] as String?,
            entry: entry,
            create: _services.createProcedureKindUseCase.execute,
            update: _services.updateProcedureKindUseCase.execute,
            delete: _services.deleteProcedureKindUseCase.execute,
          );
          break;
        case 'workdays':
          if (action == 'delete') {
            await _services.deleteWorkdayUseCase
                .execute(values['id'] as String);
          } else if (action == 'create') {
            final day = _workdayFromMap({...entry, 'id': 'new'});
            await _services.createWorkdayUseCase.execute(day);
          } else if (action == 'update') {
            final day = _workdayFromMap(
              {...entry, 'id': values['id'] as String},
            );
            await _services.updateWorkdayUseCase.execute(day);
          }
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
    DesktopWindowKind.procedureSession => 'Назначенная процедура',
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
  final savedBounds = await _savedChildWindowBounds(kind);
  final displays = await screenRetriever.getAllDisplays();
  final restoredBounds = savedBounds != null &&
          windowBoundsFitAnyDisplay(bounds: savedBounds, displays: displays)
      ? savedBounds
      : null;
  await windowManager.waitUntilReadyToShow(options, () async {
    if (restoredBounds != null) {
      await windowManager.setSize(restoredBounds.size);
      await windowManager.setPosition(restoredBounds.topLeft);
    } else {
      await windowManager.setPosition(
        await childWindowPositionOnParentDisplay(options.size!),
      );
    }
    await windowManager.show();
    await windowManager.focus();
  });
  final current = await WindowController.fromCurrentEngine();
  Future<dynamic> handleInitialWindowMethod(MethodCall call) async {
    switch (call.method) {
      case 'integration_test_ready':
        return true;
      case 'integration_test_hide':
        if (kind == DesktopWindowKind.procedureSession) {
          return hideCurrentProcedureSessionWindow();
        }
        throw MissingPluginException('Unknown window method ${call.method}');
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
  }

  await current.setWindowMethodHandler(handleInitialWindowMethod);
}

Future<Rect?> _savedChildWindowBounds(DesktopWindowKind kind) async {
  try {
    final result = await _mainChannel.invokeMethod<Map>(
      'childWindowGeometry',
      kind.name,
    );
    return result == null ? null : windowBoundsFromMap(result);
  } catch (_) {
    // A child can be launched while the main window is closing.
    return null;
  }
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
            body: ProcedureStatisticsContent(
          workdays: _workdays,
          people: _humans,
          kinds: _kinds,
          countFor: (person, kind) => _counts['${person.id}/${kind.id}'] ?? 0,
          isLoading: _loading,
          error: _error,
          dayId: _dayId,
          peopleFilter: _people,
          mode: _mode,
          onDayChanged: (value) {
            _dayId = value;
            _load();
          },
          onPeopleChanged: (value) {
            _people = value;
            _load();
          },
          onModeChanged: (value) {
            _mode = value;
            _load();
          },
          onAdd: () => _mainChannel.invokeMethod<void>('openProcedureSession'),
        )),
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
  var _formVersion = 0;
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
      final cascade = (call.arguments as Map?)?['cascade'] == true;
      return cascade
          ? closeCurrentDesktopWindow(cascade: true)
          : hideCurrentProcedureSessionWindow();
    }
    if (call.method == 'procedure_session_show') {
      await _load();
      await windowManager.show();
      await windowManager.focus();
      await _mainChannel.invokeMethod<void>(
        'procedureSessionVisibilityChanged',
        true,
      );
      return null;
    }
    if (call.method == 'integration_test_hide') {
      return hideCurrentProcedureSessionWindow();
    }
    if (call.method == 'window_bounds') return currentWindowBoundsMap();
    if (call.method == 'window_focus') return windowManager.focus();
    throw MissingPluginException('Unknown procedure-session-window method');
  }

  Future<void> _load() async {
    final value =
        await _mainChannel.invokeMethod<Map>('procedureSessionSnapshot');
    if (mounted) {
      setState(() {
        _snapshot = Map<String, dynamic>.from(value!);
        _formVersion += 1;
      });
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
          key: ValueKey(_formVersion),
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
            return value['didSave'] as bool
                ? ProcedureSessionSubmitResult.saved(
                    value['operationId'] as int)
                : (value['conflictMessages'] as List).isNotEmpty
                    ? ProcedureSessionSubmitResult.conflicts(
                        (value['conflictMessages'] as List).cast<String>())
                    : ProcedureSessionSubmitResult.error(
                        value['errorMessage'] as String);
          },
          onSavedAndRendered: (operationId) => _mainChannel.invokeMethod<void>(
              'procedureSessionRendered', operationId),
          onClose: hideCurrentProcedureSessionWindow,
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

String _formatWorkdayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
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

/// Applies a procedure-directory command received from a child window.
///
/// Deletion deliberately does not decode an [entry]: the child only needs to
/// send an identifier, so optional form fields cannot turn into a null cast.
Future<void> mutateProcedureKindDirectory({
  required String action,
  required String? id,
  required Map<String, dynamic> entry,
  required Future<void> Function(ProcedureKind procedureKind) create,
  required Future<void> Function(ProcedureKind procedureKind) update,
  required Future<void> Function(String procedureKindId) delete,
}) async {
  switch (action) {
    case 'delete':
      await delete(_requiredProcedureKindId(id));
      return;
    case 'create':
      await create(_kindFromMap({...entry, 'id': 'new'}));
      return;
    case 'update':
      await update(
        _kindFromMap({...entry, 'id': _requiredProcedureKindId(id)}),
      );
      return;
    default:
      throw ArgumentError.value(action, 'action');
  }
}

String _requiredProcedureKindId(String? id) {
  if (id == null || id.trim().isEmpty) {
    throw ArgumentError.value(id, 'id');
  }
  return id;
}

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
class DirectoryChildWindowScaffold extends StatelessWidget {
  const DirectoryChildWindowScaffold({
    required this.title,
    required this.absorbing,
    required this.builder,
    super.key,
  });

  final String title;
  final bool absorbing;
  final Widget Function(BuildContext contentContext) builder;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [Locale('ru', 'RU')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: AbsorbPointer(
            absorbing: absorbing,
            child: Builder(builder: builder),
          ),
        ),
      );
}

class DirectoryChildWindow extends StatefulWidget {
  const DirectoryChildWindow({super.key});

  @override
  State<DirectoryChildWindow> createState() => _DirectoryChildWindowState();
}

class _DirectoryChildWindowState extends State<DirectoryChildWindow> {
  DesktopWindowKind? _kind;
  String? _entryId;
  List<Map<String, dynamic>> _entries = const [];
  bool _loading = true;
  bool _saving = false;
  bool _hasModalChild = false;
  StreamSubscription<void>? _windowsSubscription;
  String? _error;
  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _date = TextEditingController();
  ProcedureKindsViewModel? _procedureKindsViewModel;

  bool get _isEditor =>
      _kind == DesktopWindowKind.procedureKindEditor ||
      _kind == DesktopWindowKind.workdayEditor;
  bool get _isPeopleDirectory =>
      _kind == DesktopWindowKind.participants ||
      _kind == DesktopWindowKind.assistants;
  bool get _isWorkdaysDirectory => _kind == DesktopWindowKind.workdays;
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
    if (_kind == DesktopWindowKind.procedureKinds ||
        _kind == DesktopWindowKind.procedureKindEditor) {
      _procedureKindsViewModel = ProcedureKindsViewModel(
        operations: IpcProcedureKindsOperations(
          (method, arguments) => _mainChannel.invokeMethod(method, arguments),
        ),
      );
    }
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
          if (_procedureKindsViewModel case final viewModel?) {
            await viewModel.loadProcedureKinds();
          }
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
      if (_procedureKindsViewModel case final viewModel?) {
        await viewModel.loadProcedureKinds();
      }
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
    _date.text = entry?['date'] as String? ??
        (_kind == DesktopWindowKind.workdayEditor ? _nextWorkdayDate() : '');
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
    _procedureKindsViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kind == null || _loading)
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return DirectoryChildWindowScaffold(
      title: _title,
      absorbing: _hasModalChild,
      builder: (contentContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: _kind == DesktopWindowKind.procedureKinds
            ? ProcedureKindsContent(
                viewModel: _procedureKindsViewModel!,
                onOpenCreate: () =>
                    _openEditor(DesktopWindowKind.procedureKindEditor.name),
                onOpenEdit: (procedureKind) => _openEditor(
                  DesktopWindowKind.procedureKindEditor.name,
                  procedureKind.id,
                ),
              )
            : _kind == DesktopWindowKind.procedureKindEditor
                ? ProcedureKindFormContent(
                    viewModel: _procedureKindsViewModel!,
                    procedureKinds: _procedureKindsViewModel!.procedureKinds,
                    initialProcedureKind: _entryId == null
                        ? null
                        : _procedureKindsViewModel!.procedureKinds
                            .where((entry) => entry.id == _entryId)
                            .firstOrNull,
                    onSaved: (_) => closeCurrentDesktopWindow(),
                    onCancel: () => unawaited(closeCurrentDesktopWindow()),
                  )
                : _isEditor
                    ? _editor(contentContext)
                    : _directoryList(contentContext),
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

  Widget _directoryList(BuildContext contentContext) {
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
        onCountReferences: (id) => _mainChannel.invokeMethod<int>(
          'directoryReferences',
          {'directory': _directory, 'id': id},
        ).then((value) => value ?? 0),
        onChanged: _load,
      );
    }
    if (_isWorkdaysDirectory) return _workdaysList(contentContext);
    throw StateError('Unsupported directory window kind: $_kind');
  }

  Widget _workdaysList(BuildContext contentContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: _saving
                  ? null
                  : () => _openEditor(DesktopWindowKind.workdayEditor.name),
              child: const Text('Создать'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD0D7DE)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text('Название')),
                      Expanded(flex: 2, child: Text('Дата')),
                      SizedBox(width: 180),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final entry = _entries[index];
                        final id = entry['id'] as String;
                        return InkWell(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(children: [
                              Expanded(
                                flex: 3,
                                child: Text(entry['name'] as String),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatWorkdayDate(entry['date'] as String),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _saving
                                          ? null
                                          : () => _openEditor(
                                                DesktopWindowKind
                                                    .workdayEditor.name,
                                                id,
                                              ),
                                      child: const Text('Изменить'),
                                    ),
                                    TextButton(
                                      onPressed: _saving
                                          ? null
                                          : () => _deleteWorkday(
                                              contentContext, entry),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _deleteWorkday(
    BuildContext contentContext,
    Map<String, dynamic> entry,
  ) async {
    final name = entry['name'] as String;
    final confirmed = await showDialog<bool>(
      context: contentContext,
      builder: (context) => AlertDialog(
        title: const Text('Удалить день?'),
        content: Text('День "$name" будет скрыт из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final referencesCount = await _mainChannel.invokeMethod<int>(
          'workdayReferences',
          entry['id'] as String,
        ) ??
        0;
    if (!mounted) return;
    if (referencesCount > 0) {
      await showDialog<void>(
        context: contentContext,
        builder: (context) => AlertDialog(
          title: const Text('Невозможно удалить день'),
          content: Text(
            'День "$name" используется в $referencesCount '
            '${_assignedProcedureWord(referencesCount)}. '
            'Сначала удалите или переназначьте эти процедуры.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }
    await _mutate('delete', id: entry['id'] as String);
  }

  Future<void> _selectWorkdayDate(BuildContext contentContext) async {
    if (_saving) return;
    final initialDate = DateTime.tryParse(_date.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: contentContext,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selectedDate == null || !mounted) return;
    setState(() => _date.text = _formatCalendarDate(selectedDate));
  }

  String _nextWorkdayDate() {
    final dates = _entries
        .map((entry) => DateTime.tryParse(entry['date'] as String? ?? ''))
        .whereType<DateTime>();
    if (dates.isEmpty) {
      return _formatCalendarDate(
        DateTime.now().add(const Duration(days: 1)),
      );
    }
    final latest = dates.reduce(
      (left, right) => left.isAfter(right) ? left : right,
    );
    return _formatCalendarDate(latest.add(const Duration(days: 1)));
  }

  String _assignedProcedureWord(int count) {
    final remainder100 = count % 100;
    if (remainder100 >= 11 && remainder100 <= 14) {
      return 'назначенных процедур';
    }
    return switch (count % 10) {
      1 => 'назначенная процедура',
      2 || 3 || 4 => 'назначенные процедуры',
      _ => 'назначенных процедур',
    };
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

  Widget _editor(BuildContext contentContext) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: _name,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Название')),
        const SizedBox(height: 12),
        const Text('Дата'),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _selectWorkdayDate(contentContext),
          icon: const Icon(Icons.calendar_month),
          label: Text(
            _date.text.isEmpty
                ? 'Выберите дату'
                : _formatWorkdayDate(_date.text),
          ),
        ),
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
      {'name': _name.text, 'date': _date.text};
}
