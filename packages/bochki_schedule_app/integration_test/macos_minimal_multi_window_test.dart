import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main(List<String> args) async {
  if (args.firstOrNull == 'multi_window') {
    WidgetsFlutterBinding.ensureInitialized();
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

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'runs the upstream example child-window lifecycle and message exchange',
      (tester) async {
    final childReady = Completer<int>();
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      _trace('main received ${call.method} from=$fromWindowId');
      if (call.method != 'ready') {
        throw UnsupportedError('Unknown main method ${call.method}');
      }
      if (!childReady.isCompleted) childReady.complete(fromWindowId);
      return true;
    });

    late WindowController child;
    await tester.pumpWidget(_MinimalMainWindow(
      onOpenChild: () async {
        _trace('main creating upstream child window');
        child = await DesktopMultiWindow.createWindow(
          jsonEncode({'name': 'Upstream minimal child'}),
        );
        await child.setFrame(const Rect.fromLTWH(100, 100, 800, 600));
        await child.setTitle('Upstream minimal child');
        await child.show();
        _trace('main createWindow returned windowId=${child.windowId}');
      },
    ));

    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 1'), findsOneWidget);

    final childId = await childReady.future.timeout(const Duration(seconds: 5));
    expect(childId, child.windowId);
    _trace('main received child ready windowId=$childId');
    final reply = await DesktopMultiWindow.invokeMethod(
      child.windowId,
      'message_from_main',
      'Hello from the main window',
    );
    expect(reply, 'Message received by child ${child.windowId}');
    await child.close();

    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 2'), findsOneWidget);
  });
}

void _trace(String message) {
  debugPrintSynchronously('[macos-upstream-0.2.1] $message');
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
