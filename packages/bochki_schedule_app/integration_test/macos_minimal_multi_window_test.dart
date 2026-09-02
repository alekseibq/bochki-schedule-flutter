import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    _trace('child entrypoint windowId=$windowId');
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      _trace('child received ${call.method} from=$fromWindowId');
      if (call.method == 'close') {
        return WindowController.fromWindowId(windowId).close();
      }
      throw UnsupportedError('Unknown child method ${call.method}');
    });
    runApp(_UpstreamChildWindow(windowId: windowId));
    return;
  }

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'opens an upstream child window and receives its first-frame ready signal',
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
        child = await DesktopMultiWindow.createWindow('upstream-minimal-child');
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
  const _UpstreamChildWindow({required this.windowId});

  final int windowId;

  @override
  State<_UpstreamChildWindow> createState() => _UpstreamChildWindowState();
}

class _UpstreamChildWindowState extends State<_UpstreamChildWindow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DesktopMultiWindow.invokeMethod(
        0,
        'ready',
        {'windowId': widget.windowId},
      ));
    });
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Upstream minimal child window')),
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
