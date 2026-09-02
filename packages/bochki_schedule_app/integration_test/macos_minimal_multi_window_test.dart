import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

const _childArgument = 'macos-minimal-child';
const _childControlChannel = WindowMethodChannel(
  'bochki_schedule/macos_minimal_child_control',
  mode: ChannelMode.unidirectional,
);
const _readyChannel = WindowMethodChannel(
  'bochki_schedule/macos_minimal_child_ready',
  mode: ChannelMode.bidirectional,
);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final currentWindow = await WindowController.fromCurrentEngine();
  _trace('entrypoint windowId=${currentWindow.windowId} '
      'arguments=${currentWindow.arguments}');
  if (currentWindow.arguments == _childArgument) {
    await _startChildWindow(currentWindow.windowId);
    return;
  }

  testWidgets('opens, closes, and keeps the main window interactive',
      (tester) async {
    var childCreated = Completer<WindowController>();
    var childReady = Completer<void>();
    await _readyChannel.setMethodCallHandler((call) async {
      _trace('main received ${call.method} arguments=${call.arguments}');
      if (call.method != 'ready') {
        throw UnsupportedError('Unknown minimal child event: ${call.method}');
      }
      if (!childReady.isCompleted) childReady.complete();
      return true;
    });
    _trace('main ready receiver registered');

    await tester.pumpWidget(_MinimalMainWindow(
      onOpenChild: () async {
        _trace('main creating child window');
        final child = await WindowController.create(
          const WindowConfiguration(
            arguments: _childArgument,
            hiddenAtLaunch: false,
          ),
        );
        _trace('main createWindow returned windowId=${child.windowId}');
        childCreated.complete(child);
      },
    ));

    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 1'), findsOneWidget);

    final child = await childCreated.future;
    await _waitForChildBootstrap(child);
    await childReady.future.timeout(const Duration(seconds: 5));
    _trace('main received child ready after first frame');
    await _childControlChannel.invokeMethod<void>('close');
    await _waitForChildToClose(child.windowId);

    childCreated = Completer<WindowController>();
    childReady = Completer<void>();
    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 2'), findsOneWidget);

    final reopenedChild = await childCreated.future;
    await _waitForChildBootstrap(reopenedChild);
    await childReady.future.timeout(const Duration(seconds: 5));
    _trace('main received reopened child ready after first frame');
    await _childControlChannel.invokeMethod<void>('close');
    await _waitForChildToClose(reopenedChild.windowId);
  });
}

Future<void> _startChildWindow(String windowId) async {
  _trace('child bootstrap begins windowId=$windowId');
  await windowManager.ensureInitialized();
  _trace('child windowManager initialized windowId=$windowId');
  await _childControlChannel.setMethodCallHandler((call) async {
    _trace('child control ${call.method} windowId=$windowId');
    if (call.method == 'bootstrapReady') return true;
    if (call.method == 'close') {
      await windowManager.close();
      return null;
    }
    throw UnsupportedError('Unknown minimal child command: ${call.method}');
  });
  await _readyChannel.setMethodCallHandler((call) async {
    _trace('child unexpectedly received ${call.method} windowId=$windowId');
    throw UnsupportedError(
        'Unknown command on child ready channel: ${call.method}');
  });
  _trace('child IPC handlers registered windowId=$windowId');
  runApp(_MinimalChildWindow(
    onFirstFrame: () => _announceReady(windowId),
  ));
}

Future<void> _announceReady(String windowId) async {
  _trace('child first frame rendered windowId=$windowId');
  for (var attempt = 0; attempt < 100; attempt += 1) {
    try {
      await _readyChannel.invokeMethod<bool>('ready', {'windowId': windowId});
      _trace('child ready delivered windowId=$windowId');
      return;
    } on WindowChannelException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  throw StateError('Timed out delivering minimal child ready for $windowId');
}

Future<void> _waitForChildBootstrap(WindowController child) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    try {
      if (await _childControlChannel.invokeMethod<bool>('bootstrapReady') ==
          true) {
        _trace('main confirmed child bootstrap windowId=${child.windowId}');
        return;
      }
    } on WindowChannelException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  throw StateError(
      'Timed out waiting for minimal child bootstrap ${child.windowId}');
}

Future<void> _waitForChildToClose(String windowId) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final windows = await WindowController.getAll();
    if (windows.every((window) => window.windowId != windowId)) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw StateError('Timed out closing minimal child $windowId');
}

void _trace(String message) {
  debugPrintSynchronously('[macos-minimal] $message');
}

class _MinimalMainWindow extends StatefulWidget {
  const _MinimalMainWindow({required this.onOpenChild});

  final Future<void> Function() onOpenChild;

  @override
  State<_MinimalMainWindow> createState() => _MinimalMainWindowState();
}

class _MinimalMainWindowState extends State<_MinimalMainWindow> {
  var _counter = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Main counter: $_counter'),
                ElevatedButton(
                  key: const Key('main_increment'),
                  onPressed: () {
                    setState(() => _counter += 1);
                    unawaited(widget.onOpenChild());
                  },
                  child: const Text('Open child and increment counter'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MinimalChildWindow extends StatelessWidget {
  const _MinimalChildWindow({required this.onFirstFrame});

  final Future<void> Function() onFirstFrame;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: _MinimalChildContent(onFirstFrame: onFirstFrame),
      );
}

class _MinimalChildContent extends StatefulWidget {
  const _MinimalChildContent({required this.onFirstFrame});

  final Future<void> Function() onFirstFrame;

  @override
  State<_MinimalChildContent> createState() => _MinimalChildContentState();
}

class _MinimalChildContentState extends State<_MinimalChildContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.onFirstFrame());
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Minimal child window')),
      );
}
