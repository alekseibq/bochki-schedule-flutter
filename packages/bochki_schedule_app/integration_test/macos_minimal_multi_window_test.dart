import 'dart:async';

import 'package:bochki_schedule_app/src/presentation/macos_minimal_child.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final currentWindow = await WindowController.fromCurrentEngine();
  _trace('entrypoint windowId=${currentWindow.windowId} '
      'arguments=${currentWindow.arguments}');
  if (currentWindow.arguments == macosMinimalChildArgument) {
    await startMacosMinimalChild(currentWindow.windowId);
    return;
  }

  testWidgets('opens, closes, and keeps the main window interactive',
      (tester) async {
    var childCreated = Completer<WindowController>();
    var childReady = Completer<void>();
    await macosMinimalChildReadyChannel.setMethodCallHandler((call) async {
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
            arguments: macosMinimalChildArgument,
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
    await macosMinimalChildControlChannel.invokeMethod<void>('close');
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
    await macosMinimalChildControlChannel.invokeMethod<void>('close');
    await _waitForChildToClose(reopenedChild.windowId);
  });
}

Future<void> _waitForChildBootstrap(WindowController child) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    try {
      if (await macosMinimalChildControlChannel
              .invokeMethod<bool>('bootstrapReady') ==
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
