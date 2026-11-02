import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../domain/assistants/assistant.dart';
import '../domain/assistants/assistants_validation_exception.dart';
import '../domain/humans/human.dart';
import '../domain/participants/participants_validation_exception.dart';
import '../domain/procedure_kinds/procedure_kind.dart';
import '../domain/procedure_sessions/procedure_session_raw.dart';
import '../domain/procedure_statistics/build_procedure_statistics_table_use_case.dart';
import '../domain/procedure_statistics/procedure_statistics_table.dart';
import '../domain/schedule_gaps/build_schedule_gaps_use_case.dart';
import '../domain/schedule_gaps/schedule_gap.dart';
import '../domain/workdays/workday.dart';
import '../domain/workdays/workdays_validation_exception.dart';
import '../app_services.dart';
import 'app_tooltips.dart';
import '../features/procedure_sessions/procedure_session_dialog.dart';
import '../features/procedure_sessions/ipc_procedure_session_editor_operations.dart';
import '../features/procedure_sessions/procedure_session_editor_view_model.dart';
import '../features/procedure_sessions/procedure_sessions_view_model.dart';
import '../features/procedure_kinds/ipc_procedure_kinds_operations.dart';
import '../features/procedure_kinds/procedure_kind_form_content.dart';
import '../features/procedure_kinds/procedure_kinds_dialog.dart';
import '../features/procedure_kinds/procedure_kinds_view_model.dart';
import '../features/assistants/ipc_assistants_operations.dart';
import '../features/assistants/assistants_content.dart';
import '../features/assistants/assistants_dialog.dart';
import '../features/assistants/assistants_view_model.dart';
import '../features/participants/ipc_participants_operations.dart';
import '../features/participants/participants_content.dart';
import '../features/participants/participants_dialog.dart';
import '../features/participants/participants_view_model.dart';
import '../features/procedure_statistics/procedure_statistics_dialog.dart';
import '../features/procedure_statistics/ipc_procedure_statistics_operations.dart';
import '../features/procedure_statistics/procedure_statistics_view_model.dart';
import '../features/quick_reassignments/quick_reassignments_dialog.dart';
import '../features/quick_reassignments/quick_reassignments_view_model.dart';
import '../features/quick_reassignments/ipc_quick_reassignments_operations.dart';
import '../features/free_time/free_time_view_model.dart';
import '../features/free_time/free_time_dialog.dart';
import '../features/free_time/ipc_free_time_operations.dart';
import '../features/workdays/ipc_workdays_operations.dart';
import '../features/workdays/workday_form_content.dart';
import '../features/workdays/workdays_content.dart';
import '../features/workdays/workdays_view_model.dart';

enum DesktopWindowKind {
  main,
  procedureStatistics,
  procedureSession,
  freeTime,
  quickReassignments,
  participants,
  assistants,
  procedureKinds,
  workdays,
  procedureKindEditor,
  workdayEditor,
}

typedef DirectoryChangedCallback = Future<void> Function(String directory);
typedef DesktopWindowFeatureMethodHandler = Future<dynamic> Function(
  MethodCall call,
);
typedef DesktopWindowCloseRequestHandler = Future<bool> Function();
typedef CascadeCloseTimeoutHandler = Future<void> Function();
typedef MainWindowClosingHandler = Future<void> Function();
typedef DesktopWindowFocusOperation = Future<void> Function(String windowId);
typedef DesktopWindowVisibilityNotifier = Future<void> Function(bool visible);

CascadeCloseTimeoutHandler? _cascadeCloseTimeoutHandler;
MainWindowClosingHandler? _mainWindowClosingHandler;

/// Registers the main-window UI used when a real cascade close times out.
void setCascadeCloseTimeoutHandler(CascadeCloseTimeoutHandler? handler) {
  _cascadeCloseTimeoutHandler = handler;
}

const _mainChannel = WindowMethodChannel(
  'bochki_schedule/main_window',
  mode: ChannelMode.unidirectional,
);

/// Applies the immutable startup scale to a child engine and its dialogs.
class DesktopWindowUiScale extends StatelessWidget {
  const DesktopWindowUiScale({
    required this.child,
    required this.uiScale,
    super.key,
  });

  final Widget child;
  final double uiScale;

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(uiScale),
        ),
        child: child,
      );
}

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

bool shouldHideOnOrdinaryClose({
  required DesktopWindowKind kind,
  required bool cascade,
}) =>
    kind != DesktopWindowKind.main && !cascade;

enum DesktopChildWindowState { opening, visible, hidden, closing }

bool isBlockingDesktopChildState(DesktopChildWindowState state) =>
    state == DesktopChildWindowState.opening ||
    state == DesktopChildWindowState.visible;

/// Main-engine-owned lifecycle state for reusable child windows.
///
/// Native presence is deliberately not represented here: a hidden reusable
/// engine remains present in `WindowController.getAll()`.
final class DesktopChildWindowStateStore {
  final _states = <DesktopWindowKind, DesktopChildWindowState>{};

  DesktopChildWindowState? operator [](DesktopWindowKind kind) => _states[kind];

  bool get hasBlockingWindow => _states.values.any(isBlockingDesktopChildState);

  Iterable<DesktopWindowKind> get blockingKinds => _states.entries
      .where((entry) => isBlockingDesktopChildState(entry.value))
      .map((entry) => entry.key);

  void update(DesktopWindowKind kind, DesktopChildWindowState state) {
    _states[kind] = state;
  }

  void remove(DesktopWindowKind kind) {
    _states.remove(kind);
  }

  void markAllClosing() {
    for (final kind in _states.keys.toList(growable: false)) {
      _states[kind] = DesktopChildWindowState.closing;
    }
  }
}

/// Coalesces concurrent work for the same child kind.
///
/// The completer is stored before [operation] is called, so even an operation
/// that reaches an `await` immediately has already reserved its singleton.
final class DesktopWindowOpenGate<T> {
  final _inFlight = <DesktopWindowKind, Future<T>>{};

  bool isOpening(DesktopWindowKind kind) => _inFlight.containsKey(kind);

  Future<T> run(
    DesktopWindowKind kind,
    Future<T> Function() operation,
  ) {
    final existing = _inFlight[kind];
    if (existing != null) return existing;

    final completer = Completer<T>();
    final future = completer.future;
    _inFlight[kind] = future;
    try {
      operation().then(
        completer.complete,
        onError: completer.completeError,
      );
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
    void removeReservation() {
      if (identical(_inFlight[kind], future)) {
        _inFlight.remove(kind);
      }
    }

    unawaited(future.then<void>(
      (_) => removeReservation(),
      onError: (Object _, StackTrace __) => removeReservation(),
    ));
    return future;
  }
}

final class DesktopWindowContext {
  const DesktopWindowContext({
    required this.kind,
    this.parentWindowId,
    this.ancestorWindowIds = const [],
    this.ancestorWindowKinds = const [],
    this.entryId,
    this.uiScale = 1.1,
  });

  final DesktopWindowKind kind;
  final String? parentWindowId;
  final List<String> ancestorWindowIds;
  final List<DesktopWindowKind> ancestorWindowKinds;
  final String? entryId;
  final double uiScale;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (parentWindowId != null) 'parentWindowId': parentWindowId,
        'ancestorWindowIds': ancestorWindowIds,
        'ancestorWindowKinds':
            ancestorWindowKinds.map((kind) => kind.name).toList(),
        if (entryId != null) 'entryId': entryId,
        'uiScale': uiScale,
      };
}

typedef DesktopWindowDescriptor = DesktopWindowContext;

DesktopWindowDescriptor windowDescriptorFromArguments(String value) {
  try {
    final values = Map<String, dynamic>.from(jsonDecode(value) as Map);
    return DesktopWindowContext(
      kind: DesktopWindowKind.values.byName(values['kind'] as String),
      parentWindowId: values['parentWindowId'] as String?,
      ancestorWindowIds: List<String>.from(
        values['ancestorWindowIds'] as List? ?? const [],
      ),
      ancestorWindowKinds: (values['ancestorWindowKinds'] as List? ?? const [])
          .map((value) => DesktopWindowKind.values.byName(value as String))
          .toList(),
      entryId: values['entryId'] as String?,
      uiScale: (values['uiScale'] as num?)?.toDouble() ?? 1.1,
    );
  } catch (_) {
    return const DesktopWindowContext(kind: DesktopWindowKind.main);
  }
}

bool hasWindowAncestor(
  DesktopWindowContext descriptor,
  DesktopWindowKind kind,
) =>
    descriptor.ancestorWindowKinds.contains(kind);

/// Shows and focuses the first still-present visible direct child.
///
/// A window can disappear between a visibility notification and a native focus
/// event. In that case, or when activation fails, the caller deliberately
/// keeps focus on the current window instead of selecting another child.
Future<void> focusFirstVisibleDirectChildWindow({
  required Iterable<String> visibleChildWindowIds,
  required Iterable<String> availableWindowIds,
  required DesktopWindowFocusOperation show,
  required DesktopWindowFocusOperation focus,
}) async {
  final availableIds = availableWindowIds.toSet();
  final targetId =
      visibleChildWindowIds.where(availableIds.contains).firstOrNull;
  if (targetId == null) return;
  try {
    await show(targetId);
    await focus(targetId);
  } catch (_) {
    // The target can close while the native focus request is in flight.
  }
}

/// Clears the parent-visible state before a native hide can focus that parent.
///
/// The ordering prevents the parent's focus listener from immediately showing
/// the child again. A failed native hide restores the visible state.
Future<void> hideNativeWindowAfterReportingHidden({
  required DesktopWindowVisibilityNotifier notifyVisibility,
  required Future<void> Function() hideNativeWindow,
}) async {
  await notifyVisibility(false);
  try {
    await hideNativeWindow();
  } catch (_) {
    await notifyVisibility(true);
    rethrow;
  }
}

/// The sole production gateway for creating child engines.
final class DesktopWindowPlatform {
  const DesktopWindowPlatform();

  Future<WindowController> current() => WindowController.fromCurrentEngine();
  Future<List<WindowController>> all() => WindowController.getAll();
  Future<WindowController> create(DesktopWindowContext context) =>
      WindowController.create(
          childWindowConfiguration(jsonEncode(context.toJson())));
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

/// Waits until all [descendantWindowIds] disappear, without allowing a hung
/// native window-list request to extend the overall timeout.
Future<bool> waitForDescendantWindowsToClose({
  required Set<String> descendantWindowIds,
  required Future<Iterable<String>> Function() listWindowIds,
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  if (descendantWindowIds.isEmpty) return true;
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    final remainingTime = timeout - stopwatch.elapsed;
    Iterable<String> currentWindowIds;
    try {
      currentWindowIds = await listWindowIds().timeout(remainingTime);
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
    if (currentWindowIds.every(
      (windowId) => !descendantWindowIds.contains(windowId),
    )) {
      return true;
    }
    final delay = timeout - stopwatch.elapsed < pollInterval
        ? timeout - stopwatch.elapsed
        : pollInterval;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }
  return false;
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

/// A scoped registration for methods owned by the feature rendered in a child
/// window. System window methods remain owned by [DesktopWindowLifecycle].
final class DesktopWindowFeatureHandlerRegistration {
  DesktopWindowFeatureHandlerRegistration._(this._dispatcher, this._handler);

  final DesktopWindowFeatureMethodDispatcher _dispatcher;
  final DesktopWindowFeatureMethodHandler _handler;
  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _dispatcher.unregister(_handler);
  }
}

/// A scoped registration that can postpone an ordinary native-window close.
///
/// Returning `false` keeps the reusable child window visible. This is used by
/// inline editors to save (or report validation errors) before the window is
/// hidden.
final class DesktopWindowCloseRequestHandlerRegistration {
  DesktopWindowCloseRequestHandlerRegistration._(
      this._lifecycle, this._handler);

  final DesktopWindowLifecycle _lifecycle;
  final DesktopWindowCloseRequestHandler _handler;
  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _lifecycle._unregisterCloseRequestHandler(_handler);
  }
}

/// Routes feature-specific calls without allowing them to replace the native
/// window method handler installed by [DesktopWindowLifecycle].
final class DesktopWindowFeatureMethodDispatcher {
  DesktopWindowFeatureMethodHandler? _handler;

  bool get hasHandler => _handler != null;

  DesktopWindowFeatureHandlerRegistration register(
    DesktopWindowFeatureMethodHandler handler,
  ) {
    final existing = _handler;
    if (existing != null && !identical(existing, handler)) {
      throw StateError(
        'A feature method handler is already registered for this window.',
      );
    }
    _handler = handler;
    return DesktopWindowFeatureHandlerRegistration._(this, handler);
  }

  void unregister(DesktopWindowFeatureMethodHandler handler) {
    if (identical(_handler, handler)) {
      _handler = null;
    }
  }

  Future<dynamic> dispatch(MethodCall call) {
    final handler = _handler;
    if (handler == null) {
      throw MissingPluginException('Unknown window method ${call.method}');
    }
    return handler(call);
  }
}

Future<void> initializeDesktopWindowLifecycle() async {
  _windowLifecycle ??= DesktopWindowLifecycle();
  await _windowLifecycle!.initialize();
}

Future<void> closeCurrentDesktopWindow({bool cascade = false}) async {
  final lifecycle = _windowLifecycle;
  if (lifecycle == null) return windowManager.close();
  await lifecycle.close(cascade: cascade, source: 'application');
}

DesktopWindowFeatureHandlerRegistration
    registerCurrentDesktopWindowFeatureHandler(
  DesktopWindowFeatureMethodHandler handler,
) {
  final lifecycle = _windowLifecycle;
  if (lifecycle == null) {
    throw StateError('Desktop window lifecycle has not been initialized.');
  }
  return lifecycle.registerFeatureMethodHandler(handler);
}

DesktopWindowCloseRequestHandlerRegistration
    registerCurrentDesktopWindowCloseRequestHandler(
  DesktopWindowCloseRequestHandler handler,
) {
  final lifecycle = _windowLifecycle;
  if (lifecycle == null) {
    throw StateError('Desktop window lifecycle has not been initialized.');
  }
  return lifecycle.registerCloseRequestHandler(handler);
}

/// Hides a reusable child window without destroying its Flutter engine.
Future<void> hideCurrentDesktopWindow() async {
  final current = await WindowController.fromCurrentEngine();
  final descriptor = windowDescriptorFromArguments(current.arguments);
  await windowManager.hide();
  try {
    await _mainChannel.invokeMethod<void>(
      'childWindowVisibilityChanged',
      {
        'windowId': current.windowId,
        'kind': descriptor.kind.name,
        'parentWindowId': descriptor.parentWindowId,
        'visible': false,
      },
    );
  } catch (_) {
    // The main window may already be closing.
  }
}

/// Kept as a compatibility name for the procedure form's close callback.
Future<void> hideCurrentProcedureSessionWindow() => hideCurrentDesktopWindow();

Future<void> openProcedureSessionFromCurrentWindow([
  Map<String, dynamic> arguments = const {},
]) async {
  final current = await WindowController.fromCurrentEngine();
  await _mainChannel.invokeMethod<void>('openProcedureSession', {
    ...arguments,
    'parentWindowId': current.windowId,
  });
}

Future<void> openProcedureStatisticsFromCurrentWindow() async {
  final current = await WindowController.fromCurrentEngine();
  await _mainChannel.invokeMethod<void>('openProcedureStatistics', {
    'parentWindowId': current.windowId,
  });
}

/// Coordinates native close events in one Flutter engine.  The window list and
/// `parentWindowId` arguments are the shared source of truth across engines.
final class DesktopWindowLifecycle with WindowListener {
  WindowController? _current;
  DesktopWindowContext? _descriptor;
  bool _initialized = false;
  bool _closing = false;
  bool _savingGeometry = false;
  bool _geometrySavePending = false;
  DesktopWindowCloseRequestHandler? _closeRequestHandler;
  final _visibleDirectChildWindowIds = <String>{};
  final _featureMethodDispatcher = DesktopWindowFeatureMethodDispatcher();

  Future<void> initialize() async {
    if (_initialized) return;
    _current = await WindowController.fromCurrentEngine();
    _descriptor = windowDescriptorFromArguments(_current!.arguments);
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
        final cascade = (call.arguments as Map?)?['cascade'] == true;
        await close(cascade: cascade, source: 'ipc-window_close');
        return;
      case 'window_hide':
        await _hide(activateParent: false);
        return;
      case 'window_reopen':
        _updateDescriptorFromReopen(call.arguments);
        await _handleFeatureCall(call);
        await windowManager.show();
        await windowManager.focus();
        await _notifyVisibility(true);
        return;
      case 'window_bounds':
        return currentWindowBoundsMap();
      case 'window_visible':
        return windowManager.isVisible();
      case 'child_visibility_changed':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final windowId = values['windowId'] as String?;
        if (windowId != null) {
          if (values['visible'] == true) {
            _visibleDirectChildWindowIds.add(windowId);
          } else {
            _visibleDirectChildWindowIds.remove(windowId);
          }
        }
        return _featureMethodDispatcher.hasHandler
            ? _handleFeatureCall(call)
            : null;
      default:
        return _handleFeatureCall(call);
    }
  }

  void _updateDescriptorFromReopen(dynamic arguments) {
    final current = _descriptor;
    if (current == null || arguments is! Map) return;
    final values = Map<String, dynamic>.from(arguments);
    _descriptor = DesktopWindowContext(
      kind: current.kind,
      parentWindowId: values.containsKey('parentWindowId')
          ? values['parentWindowId'] as String?
          : current.parentWindowId,
      ancestorWindowIds: values.containsKey('ancestorWindowIds')
          ? List<String>.from(values['ancestorWindowIds'] as List)
          : current.ancestorWindowIds,
      ancestorWindowKinds: values.containsKey('ancestorWindowKinds')
          ? (values['ancestorWindowKinds'] as List)
              .map((value) => DesktopWindowKind.values.byName(value as String))
              .toList()
          : current.ancestorWindowKinds,
      entryId: values.containsKey('entryId')
          ? values['entryId'] as String?
          : current.entryId,
      uiScale: current.uiScale,
    );
  }

  DesktopWindowFeatureHandlerRegistration registerFeatureMethodHandler(
    DesktopWindowFeatureMethodHandler handler,
  ) =>
      _featureMethodDispatcher.register(handler);

  DesktopWindowCloseRequestHandlerRegistration registerCloseRequestHandler(
    DesktopWindowCloseRequestHandler handler,
  ) {
    final existing = _closeRequestHandler;
    if (existing != null && !identical(existing, handler)) {
      throw StateError(
        'A close request handler is already registered for this window.',
      );
    }
    _closeRequestHandler = handler;
    return DesktopWindowCloseRequestHandlerRegistration._(this, handler);
  }

  void _unregisterCloseRequestHandler(
    DesktopWindowCloseRequestHandler handler,
  ) {
    if (identical(_closeRequestHandler, handler)) {
      _closeRequestHandler = null;
    }
  }

  Future<dynamic> _handleFeatureCall(MethodCall call) async {
    try {
      return await _featureMethodDispatcher.dispatch(call);
    } catch (error, stackTrace) {
      final current = _current;
      final descriptor = current == null ? null : _descriptor;
      developer.log(
        'Feature window method failed: method=${call.method} '
        'windowId=${current?.windowId} kind=${descriptor?.kind.name}',
        name: 'bochki_schedule.desktop_windows',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  @override
  void onWindowClose() {
    unawaited(close(source: 'native-window-close'));
  }

  @override
  void onWindowFocus() {
    unawaited(_focusVisibleDirectChild());
  }

  Future<void> _focusVisibleDirectChild() async {
    try {
      final windows = await WindowController.getAll();
      final byId = {for (final window in windows) window.windowId: window};
      await focusFirstVisibleDirectChildWindow(
        visibleChildWindowIds: _visibleDirectChildWindowIds,
        availableWindowIds: byId.keys,
        show: (windowId) => byId[windowId]!.show(),
        focus: (windowId) => byId[windowId]!.invokeMethod<void>('window_focus'),
      );
    } catch (_) {
      // Focus redirection is best-effort while windows are being destroyed.
    }
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
        final descriptor =
            _descriptor ?? windowDescriptorFromArguments(current.arguments);
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

  Future<void> close({
    bool cascade = false,
    required String source,
  }) async {
    if (_closing) return;
    _closing = true;
    try {
      final current = _current;
      final descriptor = current == null ? null : _descriptor;
      if (descriptor != null &&
          shouldHideOnOrdinaryClose(kind: descriptor.kind, cascade: cascade)) {
        if (!await _canCloseOrdinaryWindow()) {
          _closing = false;
          return;
        }
        await _hide(activateParent: true);
        _closing = false;
        return;
      }
      if (descriptor?.kind == DesktopWindowKind.main && current != null) {
        await _mainWindowClosingHandler?.call();
        final closed = await _cascadeCloseAndWait(current.windowId);
        if (!closed) {
          developer.log(
            'Timed out waiting for child windows to close; continuing main close.',
            name: 'bochki_schedule.desktop_windows',
            level: 1000,
          );
          try {
            await _cascadeCloseTimeoutHandler?.call();
          } catch (error, stackTrace) {
            _reportCleanupError(
              error,
              stackTrace,
              context: 'while showing the cascade-close timeout alert',
            );
          }
        }
        await _closeNativeWindow();
        return;
      }
      developer.log(
        'Closing desktop window: source=$source windowId=${current?.windowId} '
        'kind=${descriptor?.kind.name} parentId=${descriptor?.parentWindowId} '
        'cascade=$cascade',
        name: 'bochki_schedule.desktop_windows',
      );
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

  Future<bool> _canCloseOrdinaryWindow() async {
    final handler = _closeRequestHandler;
    if (handler == null) return true;
    try {
      return await handler();
    } catch (error, stackTrace) {
      developer.log(
        'Close request handler failed; keeping window open.',
        name: 'bochki_schedule.desktop_windows',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  Future<void> _hide({required bool activateParent}) async {
    final current = _current;
    if (current == null) return;
    final windows = await WindowController.getAll();
    final byId = {for (final window in windows) window.windowId: window};
    final parentIds = {
      for (final window in windows)
        if (windowDescriptorFromArguments(window.arguments).parentWindowId
            case final parentId?)
          window.windowId: parentId,
    };
    final descendantIds = descendantWindowIdsInCloseOrder(
      parentWindowId: current.windowId,
      parentWindowIds: parentIds,
    );
    for (final windowId in _visibleDirectChildWindowIds) {
      if (!descendantIds.contains(windowId) && byId.containsKey(windowId)) {
        descendantIds.add(windowId);
      }
    }
    requestDescendantWindowCloses(
      windowIds: descendantIds,
      requestClose: (id) => byId[id]!.invokeMethod<void>('window_hide'),
      onError: (windowId, error, stackTrace) => _reportCleanupError(
        error,
        stackTrace,
        context: 'while requesting hide for descendant window $windowId',
      ),
    );
    await hideNativeWindowAfterReportingHidden(
      notifyVisibility: _notifyVisibility,
      hideNativeWindow: windowManager.hide,
    );
    if (activateParent) await _activateParent(current.windowId);
  }

  Future<bool> _cascadeCloseAndWait(String parentWindowId) async {
    late final List<WindowController> windows;
    try {
      windows = await WindowController.getAll();
    } catch (error, stackTrace) {
      _reportCleanupError(
        error,
        stackTrace,
        context: 'while listing descendants for cascade close',
      );
      return false;
    }
    final byId = {for (final window in windows) window.windowId: window};
    final parentIds = {
      for (final window in windows)
        if (windowDescriptorFromArguments(window.arguments).parentWindowId
            case final parentId?)
          window.windowId: parentId,
    };
    final descendants = descendantWindowIdsInCloseOrder(
      parentWindowId: parentWindowId,
      parentWindowIds: parentIds,
    );
    requestDescendantWindowCloses(
      windowIds: descendants,
      requestClose: (id) =>
          byId[id]!.invokeMethod<void>('window_close', {'cascade': true}),
      onError: (windowId, error, stackTrace) => _reportCleanupError(
        error,
        stackTrace,
        context: 'while requesting cascade close for descendant $windowId',
      ),
    );
    return waitForDescendantWindowsToClose(
      descendantWindowIds: descendants.toSet(),
      listWindowIds: () async =>
          (await WindowController.getAll()).map((window) => window.windowId),
    );
  }

  Future<void> _notifyVisibility(bool visible) async {
    final current = _current;
    if (current == null) return;
    final descriptor =
        _descriptor ?? windowDescriptorFromArguments(current.arguments);
    try {
      await _mainChannel.invokeMethod<void>('childWindowVisibilityChanged', {
        'windowId': current.windowId,
        'kind': descriptor.kind.name,
        'parentWindowId': descriptor.parentWindowId,
        'visible': visible,
      });
    } catch (_) {
      // The main window can be gone during a cascade close.
    }
  }

  Future<void> _closeNativeWindow() async {
    try {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      developer.log(
        'Native desktop close requested successfully.',
        name: 'bochki_schedule.desktop_windows',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Native desktop close request failed.',
        name: 'bochki_schedule.desktop_windows',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
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
    final descriptor = currentWindowId == _current?.windowId
        ? _descriptor
        : current == null
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
    required Future<void> Function() onQuickReassignmentsClosed,
    required ValueChanged<bool> onBlockingStateChanged,
    DesktopWindowPlatform platform = const DesktopWindowPlatform(),
  })  : _platform = platform,
        _services = services,
        _statistics = statistics,
        _scheduleGaps = scheduleGaps,
        _sessions = sessions,
        _onDirectoryChanged = onDirectoryChanged,
        _onQuickReassignmentsClosed = onQuickReassignmentsClosed,
        _onBlockingStateChanged = onBlockingStateChanged;

  final AppServices _services;
  final DesktopWindowPlatform _platform;
  final BuildProcedureStatisticsTableUseCase _statistics;
  final BuildScheduleGapsUseCase _scheduleGaps;
  final ProcedureSessionsViewModel _sessions;
  final DirectoryChangedCallback _onDirectoryChanged;
  final Future<void> Function() _onQuickReassignmentsClosed;
  final ValueChanged<bool> _onBlockingStateChanged;
  final _childWindowGeometry = ChildWindowGeometryStore();
  final _windowStates = DesktopChildWindowStateStore();
  final _openGate = DesktopWindowOpenGate<void>();
  final _controllersByKind = <DesktopWindowKind, WindowController>{};
  final _contextsByKind = <DesktopWindowKind, DesktopWindowContext>{};
  final _readyByKind = <DesktopWindowKind, Completer<void>>{};
  final _parentNotificationTails = <String, Future<void>>{};
  ProcedureSessionRaw? _sessionDraft;
  String? _mainWindowId;
  MainWindowClosingHandler? _registeredMainWindowClosingHandler;
  bool _lastBlockingState = false;
  late final double _startupUiScale;

  bool get isProcedureSessionVisible =>
      _windowStates[DesktopWindowKind.procedureSession] ==
      DesktopChildWindowState.visible;

  bool get hasBlockingChildWindow => _windowStates.hasBlockingWindow;

  Future<void> start() async {
    _startupUiScale = _services.uiSettingsRepository.settings.uiScale;
    _mainWindowId = (await _platform.current()).windowId;
    await _mainChannel.setMethodCallHandler(_handleCall);
    final closingHandler = _handleMainWindowClosing;
    _registeredMainWindowClosingHandler = closingHandler;
    _mainWindowClosingHandler = closingHandler;
    _emitBlockingState();
  }

  Future<void> dispose() async {
    if (identical(
      _mainWindowClosingHandler,
      _registeredMainWindowClosingHandler,
    )) {
      _mainWindowClosingHandler = null;
    }
    await _mainChannel.setMethodCallHandler(null);
  }

  Future<void> openStatistics({String? parentWindowId}) async {
    await _sessions.load();
    await _open(DesktopWindowKind.procedureStatistics,
        parentWindowId: parentWindowId);
  }

  Future<void> openSession({
    ProcedureSessionRaw? initialValue,
    String? parentWindowId,
  }) async {
    await _sessions.load();
    _sessionDraft = initialValue;
    await _open(
      DesktopWindowKind.procedureSession,
      parentWindowId: parentWindowId,
    );
  }

  Future<void> openFreeTime() async {
    await _sessions.load();
    await _open(DesktopWindowKind.freeTime);
  }

  Future<void> openQuickReassignments() async {
    await _sessions.load();
    await _open(DesktopWindowKind.quickReassignments);
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
  }) {
    final resolvedParentWindowId = parentWindowId ?? _mainWindowId;
    return _openGate
        .run(
            kind,
            () => _openReserved(
                  kind,
                  entryId: entryId,
                  parentWindowId: resolvedParentWindowId,
                ))
        .then<void>((_) {});
  }

  Future<void> _openReserved(
    DesktopWindowKind kind, {
    required String? entryId,
    required String? parentWindowId,
  }) async {
    final conflictingKind = _conflictingActiveWindowKind(
      requestedKind: kind,
      parentWindowId: parentWindowId,
    );
    if (conflictingKind != null) {
      await _focusWindow(conflictingKind);
      return;
    }
    _setWindowState(kind, DesktopChildWindowState.opening);
    unawaited(_notifyParentBlockingState(
      parentWindowId: parentWindowId,
      kind: kind,
      active: true,
    ));
    try {
      final existing = _controllersByKind[kind] ??
          (await _platform.all())
              .where(
                (controller) =>
                    windowKindFromArguments(controller.arguments) == kind,
              )
              .firstOrNull;
      if (existing != null) {
        final context = await _windowContext(
          kind: kind,
          entryId: entryId,
          parentWindowId: parentWindowId,
        );
        _rememberWindow(existing, context);
        await existing.invokeMethod<void>('window_reopen', {
          'parentWindowId': context.parentWindowId,
          'ancestorWindowIds': context.ancestorWindowIds,
          'ancestorWindowKinds':
              context.ancestorWindowKinds.map((kind) => kind.name).toList(),
          if (entryId != null) 'entryId': entryId,
        });
        _setWindowState(kind, DesktopChildWindowState.visible);
        return;
      }
      final context = await _windowContext(
        kind: kind,
        entryId: entryId,
        parentWindowId: parentWindowId,
      );
      _contextsByKind[kind] = context;
      final ready = Completer<void>();
      _readyByKind[kind] = ready;
      final created = await _platform.create(context);
      _rememberWindow(created, context);
      await ready.future.timeout(const Duration(seconds: 10));
      _setWindowState(kind, DesktopChildWindowState.visible);
      return;
    } catch (_) {
      _controllersByKind.remove(kind);
      _contextsByKind.remove(kind);
      _readyByKind.remove(kind);
      _windowStates.remove(kind);
      _emitBlockingState();
      unawaited(_notifyParentBlockingState(
        parentWindowId: parentWindowId,
        kind: kind,
        active: false,
      ));
      rethrow;
    }
  }

  DesktopWindowKind? _conflictingActiveWindowKind({
    required DesktopWindowKind requestedKind,
    required String? parentWindowId,
  }) {
    final parentKind = _controllersByKind.entries
        .where((entry) => entry.value.windowId == parentWindowId)
        .map((entry) => entry.key)
        .firstOrNull;
    final allowedActiveWindowIds = {
      if (parentWindowId != null) parentWindowId,
      if (parentKind != null)
        ...?_contextsByKind[parentKind]?.ancestorWindowIds,
    };
    final conflicts = _windowStates.blockingKinds
        .where((kind) => kind != requestedKind)
        .where((kind) => !allowedActiveWindowIds
            .contains(_controllersByKind[kind]?.windowId))
        .toList(growable: false)
      ..sort((left, right) =>
          (_contextsByKind[right]?.ancestorWindowIds.length ?? 0).compareTo(
            _contextsByKind[left]?.ancestorWindowIds.length ?? 0,
          ));
    return conflicts.firstOrNull;
  }

  Future<void> _focusWindow(DesktopWindowKind kind) async {
    final controller = _controllersByKind[kind];
    if (controller != null) {
      try {
        await controller.show();
        await controller.invokeMethod<void>('window_focus');
      } catch (_) {
        // The coordinator state will be corrected by the close notification.
      }
    }
  }

  Future<DesktopWindowContext> _windowContext({
    required DesktopWindowKind kind,
    required String? entryId,
    required String? parentWindowId,
  }) async {
    final parent = parentWindowId == null
        ? null
        : (await _platform.all())
            .where((window) => window.windowId == parentWindowId)
            .firstOrNull;
    final parentDescriptor =
        parent == null ? null : windowDescriptorFromArguments(parent.arguments);
    final ancestors = parentDescriptor?.ancestorWindowIds ?? const <String>[];
    return DesktopWindowContext(
      kind: kind,
      parentWindowId: parentWindowId,
      ancestorWindowIds: [
        if (parentWindowId != null) parentWindowId,
        ...ancestors,
      ],
      ancestorWindowKinds: [
        if (parentDescriptor != null) parentDescriptor.kind,
        ...?parentDescriptor?.ancestorWindowKinds,
      ],
      entryId: entryId,
      uiScale: _startupUiScale,
    );
  }

  void _rememberWindow(
    WindowController controller,
    DesktopWindowContext context,
  ) {
    _controllersByKind[context.kind] = controller;
    _contextsByKind[context.kind] = context;
  }

  void _setWindowState(
    DesktopWindowKind kind,
    DesktopChildWindowState state,
  ) {
    _windowStates.update(kind, state);
    _emitBlockingState();
  }

  void _emitBlockingState() {
    final value = _windowStates.hasBlockingWindow;
    if (_lastBlockingState == value) return;
    _lastBlockingState = value;
    _onBlockingStateChanged(value);
  }

  Future<void> _handleMainWindowClosing() async {
    _windowStates.markAllClosing();
    _emitBlockingState();
    await _services.uiSettingsRepository.flush();
  }

  Future<void> _notifyParentBlockingState({
    required String? parentWindowId,
    required DesktopWindowKind kind,
    required bool active,
    String? windowId,
  }) {
    if (parentWindowId == null) {
      return Future<void>.value();
    }
    final previous =
        _parentNotificationTails[parentWindowId] ?? Future<void>.value();
    late final Future<void> notification;
    notification = previous.then((_) => _deliverParentBlockingState(
          parentWindowId: parentWindowId,
          kind: kind,
          active: active,
          windowId: windowId,
        ));
    _parentNotificationTails[parentWindowId] = notification;
    return notification.whenComplete(() {
      if (identical(_parentNotificationTails[parentWindowId], notification)) {
        _parentNotificationTails.remove(parentWindowId);
      }
    });
  }

  Future<void> _deliverParentBlockingState({
    required String parentWindowId,
    required DesktopWindowKind kind,
    required bool active,
    required String? windowId,
  }) async {
    try {
      final windows = await _platform.all();
      final parent = windows
          .where((window) => window.windowId == parentWindowId)
          .firstOrNull;
      if (parent != null) {
        await parent.invokeMethod<void>('child_visibility_changed', {
          if (windowId != null) 'windowId': windowId,
          'kind': kind.name,
          'parentWindowId': parentWindowId,
          'visible': active,
        });
      }
    } catch (_) {
      // A parent can disappear or close while its child changes state.
    }
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
        final dayId = values?['dayId'];
        final participantId = values?['participantId'];
        final startTime = values?['startTime'];
        final hasDraftValues =
            dayId is String && participantId is String && startTime is String;
        await openSession(
          parentWindowId: values?['parentWindowId'] as String?,
          initialValue: !hasDraftValues
              ? null
              : _sessions.createDraft().copyWith(
                    dayId: dayId,
                    participantId: participantId,
                    startTime: startTime,
                  ),
        );
        return null;
      case 'openProcedureStatistics':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        await openStatistics(
            parentWindowId: values['parentWindowId'] as String?);
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
      case 'quickReassignmentsSnapshot':
        return {
          ..._sessionSnapshot(),
          'quickReassignmentsColumnWidths': _services
              .uiSettingsRepository.settings.quickReassignmentsColumnWidths,
        };
      case 'quickReassignmentsMutate':
        final replacements =
            _maps(call.arguments).map(_sessionFromMap).toList(growable: false);
        await _services.quickReassignmentsUseCase!.execute(replacements);
        await _sessions.load();
        return null;
      case 'updateQuickReassignmentsColumnWidths':
        final widths = (call.arguments as List)
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
        await _services.uiSettingsRepository.update(
          _services.uiSettingsRepository.settings.copyWith(
            quickReassignmentsColumnWidths: widths,
          ),
        );
        return null;
      case 'procedureSessionSnapshot':
        return _sessionSnapshot();
      case 'directorySnapshot':
        return _directorySnapshot(call.arguments as String);
      case 'updateProcedureKindsColumnWidths':
        final widths = (call.arguments as List)
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
        await _services.uiSettingsRepository.update(
          _services.uiSettingsRepository.settings.copyWith(
            procedureKindsColumnWidths: widths,
          ),
        );
        return null;
      case 'updateWorkdaysColumnWidths':
        final widths = (call.arguments as List)
            .whereType<num>()
            .map((width) => width.toDouble())
            .toList(growable: false);
        await _services.uiSettingsRepository.update(
          _services.uiSettingsRepository.settings.copyWith(
            workdaysColumnWidths: widths,
          ),
        );
        return null;
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
        final storedSize =
            _services.uiSettingsRepository.settings.windowSizes[kind.name];
        return bounds == null
            ? storedSize == null
                ? null
                : {
                    'left': 0.0,
                    'top': 0.0,
                    'width': storedSize['width'],
                    'height': storedSize['height'],
                  }
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
        final kind = values['kind'] as String;
        final bounds = values['bounds'] as Map;
        final sizes = Map<String, Map<String, double>>.from(
          _services.uiSettingsRepository.settings.windowSizes,
        );
        sizes[kind] = {
          'width': (bounds['width'] as num).toDouble(),
          'height': (bounds['height'] as num).toDouble(),
        };
        unawaited(_services.uiSettingsRepository.update(
          _services.uiSettingsRepository.settings.copyWith(windowSizes: sizes),
        ));
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
        final visible = call.arguments as bool;
        _setWindowState(
          DesktopWindowKind.procedureSession,
          visible
              ? DesktopChildWindowState.visible
              : DesktopChildWindowState.hidden,
        );
        if (!visible) await _focusMainWindow();
        return null;
      case 'childWindowVisibilityChanged':
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final kind = DesktopWindowKind.values.byName(values['kind'] as String);
        final visible = values['visible'] as bool;
        if (visible) {
          final ready = _readyByKind.remove(kind);
          if (ready != null && !ready.isCompleted) ready.complete();
        }
        _setWindowState(
          kind,
          visible
              ? DesktopChildWindowState.visible
              : DesktopChildWindowState.hidden,
        );
        if (!visible && kind == DesktopWindowKind.quickReassignments) {
          unawaited(_onQuickReassignmentsClosed());
        }
        final context = _contextsByKind[kind];
        await _notifyParentBlockingState(
          parentWindowId:
              context?.parentWindowId ?? values['parentWindowId'] as String?,
          kind: kind,
          active: visible,
          windowId: values['windowId'] as String?,
        );
        return null;
      default:
        throw MissingPluginException(
            'Unknown main-window method ${call.method}');
    }
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
        'procedureSessions':
            _sessions.allProcedureSessions.map(_sessionMap).toList(),
        'settings': {
          'minimumTime': _sessions.programSettings.minimumTime.toJson(),
          'maximumTime': _sessions.programSettings.maximumTime.toJson(),
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
              .toList(),
          'procedureKindsColumnWidths': _services
              .uiSettingsRepository.settings.procedureKindsColumnWidths,
        };
      case 'workdays':
        return {
          'entries': (await _services.listWorkdaysUseCase.execute())
              .map(_workdayMap)
              .toList(),
          'workdaysColumnWidths':
              _services.uiSettingsRepository.settings.workdaysColumnWidths,
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
      Map<String, dynamic>? savedEntry;
      switch (directory) {
        case 'participants':
          if (action == 'delete')
            await _services.deleteParticipantUseCase
                .execute(values['id'] as String);
          if (action == 'create') {
            final saved = await _services.createParticipantUseCase
                .execute(entry['name'] as String);
            savedEntry = {'id': saved.id, 'name': saved.name};
          }
          if (action == 'update') {
            final saved = await _services.updateParticipantUseCase.execute(
                participantId: values['id'] as String,
                rawName: entry['name'] as String);
            savedEntry = {'id': saved.id, 'name': saved.name};
          }
          break;
        case 'assistants':
          if (action == 'delete')
            await _services.deleteAssistantUseCase
                .execute(values['id'] as String);
          if (action == 'create') {
            final saved = await _services.createAssistantUseCase.execute(
              entry['name'] as String,
            );
            savedEntry = {
              'id': saved.id,
              'name': saved.name,
              'shortName': saved.shortName
            };
          }
          if (action == 'update') {
            final saved = await _services.updateAssistantUseCase.execute(
              assistantId: values['id'] as String,
              rawName: entry['name'] as String,
            );
            savedEntry = {
              'id': saved.id,
              'name': saved.name,
              'shortName': saved.shortName
            };
          }
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
            savedEntry =
                _workdayMap(await _services.createWorkdayUseCase.execute(day));
          } else if (action == 'update') {
            final day = _workdayFromMap(
              {...entry, 'id': values['id'] as String},
            );
            savedEntry =
                _workdayMap(await _services.updateWorkdayUseCase.execute(day));
          }
          break;
        default:
          throw ArgumentError.value(directory, 'directory');
      }
      await _notifyDirectoryChanged(directory);
      return {'ok': true, if (savedEntry != null) 'entry': savedEntry};
    } on ParticipantsValidationException catch (error) {
      return {'ok': false, 'error': error.message, 'validation': true};
    } on AssistantsValidationException catch (error) {
      return {'ok': false, 'error': error.message, 'validation': true};
    } on WorkdaysValidationException catch (error) {
      return {'ok': false, 'error': error.message, 'validation': true};
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
  final current = await WindowController.fromCurrentEngine();
  final uiScale = windowDescriptorFromArguments(current.arguments).uiScale;
  Size scaled(Size size) => Size(size.width * uiScale, size.height * uiScale);
  final isStatistics = kind == DesktopWindowKind.procedureStatistics;
  final isFreeTime = kind == DesktopWindowKind.freeTime;
  final title = switch (kind) {
    DesktopWindowKind.procedureStatistics => 'Статистика процедур',
    DesktopWindowKind.freeTime => 'Свободное время',
    DesktopWindowKind.quickReassignments => 'Быстрые перестановки',
    DesktopWindowKind.procedureSession => 'Назначенная процедура',
    DesktopWindowKind.participants => 'Участники',
    DesktopWindowKind.assistants => 'Сопровождающие',
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
    size: kind == DesktopWindowKind.quickReassignments
        ? const Size(1000, 600)
        : isStatistics || isFreeTime
            ? const Size(1080, 514)
            : isDirectory
                ? const Size(920, 640)
                : kind == DesktopWindowKind.procedureKindEditor
                    ? scaled(const Size(820, 560))
                    : isEditor
                        ? const Size(650, 500)
                        : const Size(900, 680),
    minimumSize: kind == DesktopWindowKind.quickReassignments
        ? const Size(700, 500)
        : isStatistics || isFreeTime
            ? const Size(1080, 420)
            : kind == DesktopWindowKind.procedureKindEditor
                ? scaled(const Size(760, 480))
                : isEditor
                    ? const Size(600, 420)
                    : const Size(700, 500),
    center: false,
  );
  final savedBounds = await _savedChildWindowBounds(kind);
  final displays = await screenRetriever.getAllDisplays();
  final restoredBounds = savedBounds;
  final canRestorePosition = savedBounds != null &&
      windowBoundsFitAnyDisplay(bounds: savedBounds, displays: displays);
  final minimumSize = options.minimumSize!;
  await windowManager.waitUntilReadyToShow(options, () async {
    if (restoredBounds != null) {
      await windowManager.setSize(Size(
        restoredBounds.size.width < minimumSize.width
            ? minimumSize.width
            : restoredBounds.size.width,
        restoredBounds.size.height < minimumSize.height
            ? minimumSize.height
            : restoredBounds.size.height,
      ));
      if (canRestorePosition) {
        await windowManager.setPosition(restoredBounds.topLeft);
      } else {
        await windowManager.setPosition(
          await childWindowPositionOnParentDisplay(options.size!),
        );
      }
    } else {
      await windowManager.setPosition(
        await childWindowPositionOnParentDisplay(options.size!),
      );
    }
    await windowManager.show();
    await windowManager.focus();
  });
  final descriptor = windowDescriptorFromArguments(current.arguments);
  try {
    await _mainChannel.invokeMethod<void>('childWindowVisibilityChanged', {
      'windowId': current.windowId,
      'kind': kind.name,
      'parentWindowId': descriptor.parentWindowId,
      'visible': true,
    });
  } catch (_) {
    // The main engine can disappear while a child is being configured.
  }
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
  late final ProcedureStatisticsViewModel _viewModel;
  bool _hasModalChild = false;
  var _openedFromProcedureSession = false;
  DesktopWindowFeatureHandlerRegistration? _handlerRegistration;

  @override
  void initState() {
    super.initState();
    _viewModel = ProcedureStatisticsViewModel.fromOperations(
      IpcProcedureStatisticsOperations(
        (method, arguments) => _mainChannel.invokeMethod(method, arguments),
      ),
    );
    _listenForChanges();
    _loadWindowContext();
    _load();
  }

  Future<void> _loadWindowContext() async {
    final current = await WindowController.fromCurrentEngine();
    if (!mounted) return;
    setState(() => _openedFromProcedureSession = hasWindowAncestor(
        windowDescriptorFromArguments(current.arguments),
        DesktopWindowKind.procedureSession));
  }

  void _updateWindowContext(Map<dynamic, dynamic>? values) {
    final kinds = values?['ancestorWindowKinds'] as List?;
    if (kinds == null || !mounted) return;
    setState(() => _openedFromProcedureSession =
        kinds.contains(DesktopWindowKind.procedureSession.name));
  }

  Future<void> _listenForChanges() async {
    final registration =
        registerCurrentDesktopWindowFeatureHandler((call) async {
      switch (call.method) {
        case 'statistics_changed':
        case 'directory_changed':
        case 'window_reopen':
          _updateWindowContext(call.arguments as Map?);
          await _load();
          return null;
        case 'child_visibility_changed':
          final values = Map<String, dynamic>.from(call.arguments as Map);
          final active = values['visible'] as bool;
          if (mounted && active != _hasModalChild) {
            setState(() => _hasModalChild = active);
          }
          return null;
        default:
          throw MissingPluginException('Unknown statistics-window method');
      }
    });
    if (!mounted) {
      registration.dispose();
      return;
    }
    _handlerRegistration = registration;
  }

  @override
  void dispose() {
    _handlerRegistration?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _load() => _viewModel.load();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(tooltipTheme: AppTooltips.theme),
        home: Scaffold(
          body: AbsorbPointer(
              absorbing: _hasModalChild,
              child: ProcedureStatisticsView(
                viewModel: _viewModel,
                onAdd: _openedFromProcedureSession
                    ? null
                    : openProcedureSessionFromCurrentWindow,
              )),
        ),
      );
}

class FreeTimeWindow extends StatefulWidget {
  const FreeTimeWindow({super.key});
  @override
  State<FreeTimeWindow> createState() => _FreeTimeWindowState();
}

class _FreeTimeWindowState extends State<FreeTimeWindow> {
  bool _hasModalChild = false;
  late final FreeTimeViewModel _viewModel;
  DesktopWindowFeatureHandlerRegistration? _handlerRegistration;

  @override
  void initState() {
    super.initState();
    _viewModel = FreeTimeViewModel.fromOperations(
      IpcFreeTimeOperations(
        (method, arguments) => _mainChannel.invokeMethod(method, arguments),
      ),
    );
    _listen();
    _load();
  }

  Future<void> _listen() async {
    final registration =
        registerCurrentDesktopWindowFeatureHandler((call) async {
      if (call.method == 'free_time_changed' ||
          call.method == 'directory_changed' ||
          call.method == 'window_reopen') {
        await _load();
        return null;
      }
      if (call.method == 'child_visibility_changed') {
        final values = Map<String, dynamic>.from(call.arguments as Map);
        final active = values['visible'] as bool;
        if (mounted && active != _hasModalChild) {
          setState(() => _hasModalChild = active);
        }
        return null;
      }
      throw MissingPluginException('Unknown free-time-window method');
    });
    if (!mounted) {
      registration.dispose();
      return;
    }
    _handlerRegistration = registration;
  }

  @override
  void dispose() {
    _handlerRegistration?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _load() => _viewModel.load();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(tooltipTheme: AppTooltips.theme),
        home: Scaffold(
          body: AbsorbPointer(
            absorbing: _hasModalChild,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FreeTimeContent(
                viewModel: _viewModel,
                onOccupy: (gap) => openProcedureSessionFromCurrentWindow({
                  'dayId': gap.workday.id,
                  'participantId': gap.human.id,
                  'startTime': gap.startTime,
                }),
              ),
            ),
          ),
        ),
      );
}

class QuickReassignmentsWindow extends StatefulWidget {
  const QuickReassignmentsWindow({super.key});

  @override
  State<QuickReassignmentsWindow> createState() =>
      _QuickReassignmentsWindowState();
}

class _QuickReassignmentsWindowState extends State<QuickReassignmentsWindow> {
  QuickReassignmentsViewModel? _viewModel;
  DesktopWindowFeatureHandlerRegistration? _handlerRegistration;

  @override
  void initState() {
    super.initState();
    _viewModel = QuickReassignmentsViewModel(
      operations: IpcQuickReassignmentsOperations(
        (method, arguments) => _mainChannel.invokeMethod(method, arguments),
      ),
    );
    _listen();
    unawaited(_viewModel!.load());
  }

  Future<void> _listen() async {
    final registration =
        registerCurrentDesktopWindowFeatureHandler((call) async {
      switch (call.method) {
        case 'window_reopen':
        case 'directory_changed':
          await _viewModel?.load();
          return null;
        default:
          throw MissingPluginException('Unknown quick-reassignments method');
      }
    });
    if (!mounted) {
      registration.dispose();
      return;
    }
    _handlerRegistration = registration;
  }

  @override
  void dispose() {
    _handlerRegistration?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, tooltipTheme: AppTooltips.theme),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(children: [
            Expanded(
              child: AnimatedBuilder(
                animation: viewModel,
                builder: (_, __) => QuickReassignmentsContent(
                  viewModel: viewModel,
                  columnWidths: viewModel.columnWidths,
                  onColumnWidthsChanged: viewModel.saveColumnWidths,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: () => unawaited(closeCurrentDesktopWindow()),
                child: const Text('Закрыть'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
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
  ProcedureSessionEditorViewModel? _editor;
  var _formVersion = 0;
  var _openedFromProcedureStatistics = false;
  DesktopWindowFeatureHandlerRegistration? _handlerRegistration;
  @override
  void initState() {
    super.initState();
    _listen();
    _loadWindowContext();
    _load();
  }

  Future<void> _loadWindowContext() async {
    final current = await WindowController.fromCurrentEngine();
    if (!mounted) return;
    setState(() => _openedFromProcedureStatistics = hasWindowAncestor(
        windowDescriptorFromArguments(current.arguments),
        DesktopWindowKind.procedureStatistics));
  }

  Future<void> _listen() async {
    final registration =
        registerCurrentDesktopWindowFeatureHandler(_handleWindowMethod);
    if (!mounted) {
      registration.dispose();
      return;
    }
    _handlerRegistration = registration;
  }

  Future<dynamic> _handleWindowMethod(MethodCall call) async {
    if (call.method == 'directory_changed') {
      await _load();
      return null;
    }
    if (call.method == 'procedure_session_show' ||
        call.method == 'window_reopen') {
      if (call.method == 'window_reopen') {
        final values = call.arguments as Map?;
        final kinds = values?['ancestorWindowKinds'] as List?;
        if (kinds != null && mounted) {
          setState(() => _openedFromProcedureStatistics =
              kinds.contains(DesktopWindowKind.procedureStatistics.name));
        }
      }
      await _load();
      return null;
    }
    throw MissingPluginException('Unknown procedure-session-window method');
  }

  @override
  void dispose() {
    _handlerRegistration?.dispose();
    _editor?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final operations = IpcProcedureSessionEditorOperations(
      (method, arguments) => _mainChannel.invokeMethod(method, arguments),
    );
    final snapshot = await operations.loadSnapshot();
    if (!mounted) return;
    final editor = ProcedureSessionEditorViewModel.fromSnapshot(
      snapshot: snapshot,
      operations: operations,
    );
    final previous = _editor;
    setState(() {
      _editor = editor;
      _formVersion += 1;
    });
    previous?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = _editor;
    if (editor == null) {
      return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(tooltipTheme: AppTooltips.theme),
        home: Scaffold(
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ProcedureSessionEditorContent(
                      key: ValueKey(_formVersion),
                      viewModel: editor,
                      initialValue: editor.createDraft(),
                      onClose: closeCurrentDesktopWindow,
                      onOpenStatistics:
                          openProcedureStatisticsFromCurrentWindow,
                      isStatisticsOpeningAllowed:
                          !_openedFromProcedureStatistics,
                    )))));
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
      'useCapacityRestriction': k.useCapacityRestriction,
      'participantBusyTime': k.participantBusyTime,
      'assistantBusyTime': k.assistantBusyTime,
      'resourceBusyTime': k.resourceBusyTime
    };
ProcedureKind _kindFromMap(Map<String, dynamic> m) => ProcedureKind(
    id: m['id'] as String,
    patternId: m['patternId'] as String,
    name: m['name'] as String,
    shortName: m['shortName'] as String,
    capacity: m['capacity'] as int?,
    useCapacityRestriction: m['useCapacityRestriction'] as bool? ?? true,
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
        theme: ThemeData(useMaterial3: true, tooltipTheme: AppTooltips.theme),
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
  int _procedureKindFormSession = 0;
  int _workdayFormSession = 0;
  List<double> _procedureKindsColumnWidths = const [];
  List<double> _workdaysColumnWidths = const [];
  bool _loading = true;
  bool _hasModalChild = false;
  ProcedureKindsViewModel? _procedureKindsViewModel;
  WorkdaysViewModel? _workdaysViewModel;
  ParticipantsViewModel? _participantsViewModel;
  AssistantsViewModel? _assistantsViewModel;
  DesktopWindowFeatureHandlerRegistration? _handlerRegistration;
  DesktopWindowCloseRequestHandlerRegistration? _closeRequestRegistration;
  final _participantsContentKey = GlobalKey<ParticipantsContentState>();
  final _assistantsContentKey = GlobalKey<AssistantsContentState>();

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
  }

  Future<void> _initialize() async {
    final controller = await WindowController.fromCurrentEngine();
    final args =
        Map<String, dynamic>.from(jsonDecode(controller.arguments) as Map);
    _kind = DesktopWindowKind.values.byName(args['kind'] as String);
    _entryId = args['entryId'] as String?;
    if (_kind == DesktopWindowKind.participants) {
      _participantsViewModel = ParticipantsViewModel.fromOperations(
        IpcParticipantsOperations(
          (method, arguments) => _mainChannel.invokeMethod(method, arguments),
        ),
      );
    }
    if (_kind == DesktopWindowKind.assistants) {
      _assistantsViewModel = AssistantsViewModel.fromOperations(
        IpcAssistantsOperations(
          (method, arguments) => _mainChannel.invokeMethod(method, arguments),
        ),
      );
    }
    if (_kind == DesktopWindowKind.procedureKinds ||
        _kind == DesktopWindowKind.procedureKindEditor) {
      _procedureKindsViewModel = ProcedureKindsViewModel(
        operations: IpcProcedureKindsOperations(
          (method, arguments) => _mainChannel.invokeMethod(method, arguments),
        ),
      );
    }
    if (_kind == DesktopWindowKind.workdays ||
        _kind == DesktopWindowKind.workdayEditor) {
      _workdaysViewModel = WorkdaysViewModel.fromOperations(
        IpcWorkdaysOperations(
          (method, arguments) => _mainChannel.invokeMethod(method, arguments),
        ),
      );
    }
    final registration =
        registerCurrentDesktopWindowFeatureHandler((call) async {
      switch (call.method) {
        case 'directory_changed':
          if ((_workdaysViewModel?.isSaving ?? false) ||
              (_procedureKindsViewModel?.isSaving ?? false)) {
            return null;
          }
          if (_participantsViewModel case final viewModel?) {
            if (!viewModel.isSaving) await viewModel.loadParticipants();
            return null;
          }
          if (_assistantsViewModel case final viewModel?) {
            if (!viewModel.isSaving) await viewModel.loadAssistants();
            return null;
          }
          if (_procedureKindsViewModel case final viewModel?) {
            await viewModel.loadProcedureKinds();
          }
          await _load();
          return null;
        case 'window_reopen':
          final values = Map<String, dynamic>.from(call.arguments as Map);
          _entryId = values['entryId'] as String?;
          if (_kind == DesktopWindowKind.procedureKindEditor) {
            _procedureKindFormSession += 1;
            _procedureKindsViewModel?.clearFormError();
          }
          if (_kind == DesktopWindowKind.workdayEditor) {
            _workdayFormSession += 1;
            _workdaysViewModel?.clearFormError();
          }
          await _load();
          return null;
        case 'child_visibility_changed':
          final values = Map<String, dynamic>.from(call.arguments as Map);
          final active = values['visible'] as bool;
          if (mounted && active != _hasModalChild) {
            setState(() => _hasModalChild = active);
          }
          return null;
        default:
          throw MissingPluginException('Unknown directory-window method');
      }
    });
    if (!mounted) {
      registration.dispose();
      return;
    }
    _handlerRegistration = registration;
    if (_isPeopleDirectory) {
      _closeRequestRegistration =
          registerCurrentDesktopWindowCloseRequestHandler(
        _requestPeopleDirectoryClose,
      );
    }
    await _load();
  }

  Future<void> _load() async {
    if (_kind == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final result = Map<String, dynamic>.from(await _mainChannel.invokeMethod(
          'directorySnapshot', _directory) as Map);
      _procedureKindsColumnWidths =
          (result['procedureKindsColumnWidths'] as List? ?? const [])
              .whereType<num>()
              .map((width) => width.toDouble())
              .toList(growable: false);
      _workdaysColumnWidths =
          (result['workdaysColumnWidths'] as List? ?? const [])
              .whereType<num>()
              .map((width) => width.toDouble())
              .toList(growable: false);
      if (_procedureKindsViewModel case final viewModel?) {
        await viewModel.loadProcedureKinds();
      }
      if (_workdaysViewModel case final viewModel?) {
        await viewModel.loadWorkdays();
      }
      if (_participantsViewModel case final viewModel?) {
        await viewModel.loadParticipants();
      }
      if (_assistantsViewModel case final viewModel?) {
        await viewModel.loadAssistants();
      }
    } catch (_) {
      // The child keeps its current state when the main window is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProcedureKindsColumnWidths(List<double> widths) {
    _procedureKindsColumnWidths = widths;
    return _mainChannel.invokeMethod<void>(
      'updateProcedureKindsColumnWidths',
      widths,
    );
  }

  Future<void> _saveWorkdaysColumnWidths(List<double> widths) {
    _workdaysColumnWidths = widths;
    return _mainChannel.invokeMethod<void>(
        'updateWorkdaysColumnWidths', widths);
  }

  @override
  void dispose() {
    _handlerRegistration?.dispose();
    _closeRequestRegistration?.dispose();
    _procedureKindsViewModel?.dispose();
    _workdaysViewModel?.dispose();
    _participantsViewModel?.dispose();
    _assistantsViewModel?.dispose();
    super.dispose();
  }

  Future<bool> _requestPeopleDirectoryClose() async {
    if (_kind == DesktopWindowKind.participants) {
      return await _participantsContentKey.currentState?.requestClose() ?? true;
    }
    if (_kind == DesktopWindowKind.assistants) {
      return await _assistantsContentKey.currentState?.requestClose() ?? true;
    }
    return true;
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
  Widget build(BuildContext context) {
    if (_kind == null || _loading)
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return DirectoryChildWindowScaffold(
      title: _title,
      absorbing: _hasModalChild,
      builder: (contentContext) {
        if (_kind == DesktopWindowKind.procedureKindEditor) {
          return ProcedureKindFormContent(
            viewModel: _procedureKindsViewModel!,
            procedureKinds: _procedureKindsViewModel!.procedureKinds,
            initialProcedureKind: _entryId == null
                ? null
                : _procedureKindsViewModel!.procedureKinds
                    .where((entry) => entry.id == _entryId)
                    .firstOrNull,
            onSaved: (_) => closeCurrentDesktopWindow(),
            onCancel: () => unawaited(closeCurrentDesktopWindow()),
            formSession: _procedureKindFormSession,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _kind == DesktopWindowKind.procedureKinds
              ? ProcedureKindsContent(
                  viewModel: _procedureKindsViewModel!,
                  columnWidths: _procedureKindsColumnWidths,
                  onColumnWidthsChanged: _saveProcedureKindsColumnWidths,
                  onOpenCreate: () =>
                      _openEditor(DesktopWindowKind.procedureKindEditor.name),
                  onOpenEdit: (procedureKind) => _openEditor(
                    DesktopWindowKind.procedureKindEditor.name,
                    procedureKind.id,
                  ),
                )
              : _isEditor
                  ? _editor(contentContext)
                  : _directoryList(contentContext),
        );
      },
    );
  }

  String get _title => switch (_kind) {
        DesktopWindowKind.participants => 'Участники',
        DesktopWindowKind.assistants => 'Сопровождающие',
        DesktopWindowKind.procedureKinds => 'Процедуры',
        DesktopWindowKind.workdays => 'Дни',
        DesktopWindowKind.procedureKindEditor =>
          _entryId == null ? 'Новая процедура' : 'Редактирование процедуры',
        DesktopWindowKind.workdayEditor =>
          _entryId == null ? 'Новый день' : 'Редактирование дня',
        _ => '',
      };

  Widget _directoryList(BuildContext contentContext) {
    if (_kind == DesktopWindowKind.participants) {
      return ParticipantsContent(
        key: _participantsContentKey,
        viewModel: _participantsViewModel!,
        config: ParticipantsDialog.participantConfig,
        windowMode: true,
        onClose: closeCurrentDesktopWindow,
      );
    }
    if (_kind == DesktopWindowKind.assistants) {
      return AssistantsContent(
        key: _assistantsContentKey,
        viewModel: _assistantsViewModel!,
        config: AssistantsDialog.assistantConfig,
        windowMode: true,
        onClose: closeCurrentDesktopWindow,
      );
    }
    if (_isWorkdaysDirectory) return _workdaysList(contentContext);
    throw StateError('Unsupported directory window kind: $_kind');
  }

  Widget _workdaysList(BuildContext contentContext) => WorkdaysContent(
        viewModel: _workdaysViewModel!,
        columnWidths: _workdaysColumnWidths,
        onColumnWidthsChanged: _saveWorkdaysColumnWidths,
        onOpenCreate: () =>
            unawaited(_openEditor(DesktopWindowKind.workdayEditor.name)),
        onOpenEdit: (workday) => unawaited(
            _openEditor(DesktopWindowKind.workdayEditor.name, workday.id)),
        onOpenReorder: (workday) => unawaited(showDialog<void>(
          context: contentContext,
          builder: (context) => AlertDialog(
            key: const Key('workday_reorder_dialog'),
            title: Text('Перестановки: ${workday.name}'),
            content: const Text(
                'Заглушка. Здесь позже будет управление перестановками строк расписания.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'))
            ],
          ),
        )),
      );

  Widget _editor(BuildContext contentContext) {
    final viewModel = _workdaysViewModel!;
    final entry = _entryId == null
        ? viewModel.suggestDraftWorkday()
        : viewModel.workdays.firstWhere((workday) => workday.id == _entryId);
    return WorkdayFormContent(
      key: ValueKey(_workdayFormSession),
      viewModel: viewModel,
      initialWorkday: entry,
      isEditing: _entryId != null,
      onSaved: (_) => unawaited(closeCurrentDesktopWindow()),
      onCancel: () => unawaited(closeCurrentDesktopWindow()),
    );
  }
}
