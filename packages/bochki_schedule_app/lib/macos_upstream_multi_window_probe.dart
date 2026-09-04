import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = jsonDecode(args[2]) as Map<String, dynamic>;
    final windowName = arguments['name'] as String;
    _trace('child entrypoint windowId=$windowId name=$windowName');
    runApp(_UpstreamChildWindow(
      windowId: windowId,
      windowName: windowName,
    ));
    return;
  }

  await _runProbe();
}

Future<void> _runProbe() async {
  final childReady = Completer<int>();
  DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
    _trace('main received ${call.method} from=$fromWindowId');
    if (call.method != 'ready') {
      throw UnsupportedError('Unknown main method ${call.method}');
    }
    if (!childReady.isCompleted) childReady.complete(fromWindowId);
    return true;
  });

  runApp(_UpstreamMainWindow(
    onFirstFrame: () => _exerciseChildLifecycle(childReady),
  ));
}

Future<void> _exerciseChildLifecycle(Completer<int> childReady) async {
  try {
    _trace('main creating upstream child window');
    final child = await DesktopMultiWindow.createWindow(
      jsonEncode({'name': 'Upstream minimal child'}),
    );
    await child.setFrame(const Rect.fromLTWH(100, 100, 800, 600));
    await child.setTitle('Upstream minimal child');
    await child.show();
    _trace('main createWindow returned windowId=${child.windowId}');

    final childId = await childReady.future.timeout(const Duration(seconds: 5));
    if (childId != child.windowId) {
      throw StateError('ready came from $childId, expected ${child.windowId}');
    }
    final reply = await DesktopMultiWindow.invokeMethod(
      child.windowId,
      'message_from_main',
      'Hello from the main window',
    );
    if (reply != 'Message received by child ${child.windowId}') {
      throw StateError('unexpected child reply: $reply');
    }
    await child.close();
    _trace('PASS upstream child lifecycle and message exchange');
    exit(0);
  } catch (error, stackTrace) {
    _trace('FAIL $error\n$stackTrace');
    exit(1);
  }
}

void _trace(String message) {
  debugPrintSynchronously('[macos-upstream-0.2.1] $message');
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

  final int windowId;
  final String windowName;

  @override
  State<_UpstreamChildWindow> createState() => _UpstreamChildWindowState();
}

class _UpstreamChildWindowState extends State<_UpstreamChildWindow> {
  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      _trace('child received ${call.method} from=$fromWindowId');
      if (call.method == 'message_from_main') {
        return 'Message received by child ${widget.windowId}';
      }
      throw UnsupportedError('Unknown child method ${call.method}');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DesktopMultiWindow.invokeMethod(
        0,
        'ready',
        {'windowId': widget.windowId},
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
