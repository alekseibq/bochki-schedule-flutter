import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const _probeChannel = WindowMethodChannel(
  'bochki_schedule/upstream_multi_window_probe',
  mode: ChannelMode.unidirectional,
);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final current = await WindowController.fromCurrentEngine();
  if (current.arguments.isNotEmpty) {
    final arguments = jsonDecode(current.arguments) as Map<String, dynamic>;
    final windowName = arguments['name'] as String;
    _trace('child entrypoint windowId=${current.windowId} name=$windowName');
    await windowManager.ensureInitialized();
    await current.setWindowMethodHandler((call) async {
      _trace('child received ${call.method}');
      if (call.method == 'window_close') {
        unawaited(windowManager.close());
        return null;
      }
      if (call.method == 'window_hide') {
        await windowManager.hide();
        return null;
      }
      if (call.method == 'window_reopen') {
        await windowManager.show();
        await windowManager.focus();
        return null;
      }
      if (call.method == 'message_from_main') {
        return 'Message received by child ${current.windowId}';
      }
      throw UnsupportedError('Unknown child method ${call.method}');
    });
    runApp(_UpstreamChildWindow(
      windowId: current.windowId,
      windowName: windowName,
    ));
    return;
  }

  await _runProbe();
}

Future<void> _runProbe() async {
  const smokeOnly = bool.fromEnvironment('UPSTREAM_MULTI_WINDOW_SMOKE');
  final childReady = _ChildReadySignal();
  await _probeChannel.setMethodCallHandler((call) async {
    _trace('main received ${call.method}');
    if (call.method != 'ready') {
      throw UnsupportedError('Unknown main method ${call.method}');
    }
    childReady.complete(call.arguments as String);
    return true;
  });
  runApp(_UpstreamMainWindow(
    onFirstFrame: () => _exerciseChildLifecycle(
      childReady,
      smokeOnly: smokeOnly,
    ),
  ));
}

Future<void> _exerciseChildLifecycle(
  _ChildReadySignal childReady, {
  required bool smokeOnly,
}) async {
  try {
    const kinds = [
      'procedureStatistics',
      'procedureSession',
      'freeTime',
      'participants',
      'assistants',
      'procedureKinds',
      'workdays',
      'procedureKindEditor',
      'workdayEditor',
    ];
    final children = <WindowController>[];
    for (final name in kinds) {
      _trace('main creating reusable child window kind=$name');
      final child = await WindowController.create(
        WindowConfiguration(
          arguments: jsonEncode({'name': name}),
          hiddenAtLaunch: true,
        ),
      );
      _trace('main createWindow returned windowId=${child.windowId}');
      final childId =
          await childReady.future.timeout(const Duration(seconds: 5));
      if (childId != child.windowId) {
        throw StateError(
            'ready came from $childId, expected ${child.windowId}');
      }
      children.add(child);
      childReady.reset();
    }
    for (final child in children) {
      await child.show();
      await child.invokeMethod<void>('window_hide');
      await child.invokeMethod<void>('window_reopen');
      if (!smokeOnly) {
        final reply = await child.invokeMethod<String>(
          'message_from_main',
          'Hello from the main window',
        );
        if (reply != 'Message received by child ${child.windowId}') {
          throw StateError('unexpected child reply: $reply');
        }
      }
    }
    // Dispatch the complete cascade deepest-first without awaiting individual
    // IPC responses. On Windows an engine can disappear while its response is
    // being delivered, so one stale response must not prevent the remaining
    // children from receiving their close request.
    for (final child in children.reversed) {
      unawaited(
          child.invokeMethod<void>('window_close', {'cascade': true}).then(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          _trace('close request failed windowId=${child.windowId}: $error');
        },
      ));
    }
    await _waitForChildrenClose(
        children.map((child) => child.windowId).toSet());
    if (smokeOnly) {
      _trace('PASS reusable child smoke lifecycle');
    } else {
      _trace('PASS reusable child lifecycle and message exchange');
    }
    exit(0);
  } catch (error, stackTrace) {
    _trace('FAIL $error\n$stackTrace');
    exit(1);
  }
}

class _ChildReadySignal {
  var _current = Completer<String>();

  Future<String> get future => _current.future;

  void complete(String windowId) {
    if (!_current.isCompleted) _current.complete(windowId);
  }

  void reset() => _current = Completer<String>();
}

Future<void> _waitForChildrenClose(Set<String> windowIds) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final remainingTime = deadline.difference(DateTime.now());
    final windows = await WindowController.getAll().timeout(remainingTime);
    if (windows.every((window) => !windowIds.contains(window.windowId))) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('timed out closing children $windowIds');
}

void _trace(String message) {
  debugPrintSynchronously('[macos-upstream-0.3.1] $message');
}

class _UpstreamMainWindow extends StatefulWidget {
  const _UpstreamMainWindow({required this.onFirstFrame});

  final Future<void> Function() onFirstFrame;

  @override
  State<_UpstreamMainWindow> createState() => _UpstreamMainWindowState();
}

class _UpstreamMainWindowState extends State<_UpstreamMainWindow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.onFirstFrame());
    });
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Upstream multi-window probe main')),
        ),
      );
}

class _UpstreamChildWindow extends StatefulWidget {
  const _UpstreamChildWindow({
    required this.windowId,
    required this.windowName,
  });

  final String windowId;
  final String windowName;

  @override
  State<_UpstreamChildWindow> createState() => _UpstreamChildWindowState();
}

class _UpstreamChildWindowState extends State<_UpstreamChildWindow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_probeChannel.invokeMethod(
        'ready',
        widget.windowId,
      ));
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text(widget.windowName)),
        ),
      );
}
