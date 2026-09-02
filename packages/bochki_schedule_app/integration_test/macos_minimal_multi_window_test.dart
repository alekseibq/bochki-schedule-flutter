import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

const _childArgument = 'macos-minimal-child';
const _controlChannel = WindowMethodChannel(
  'bochki_schedule/macos_minimal_child',
  mode: ChannelMode.unidirectional,
);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final currentWindow = await WindowController.fromCurrentEngine();
  if (currentWindow.arguments == _childArgument) {
    await _startChildWindow();
    return;
  }

  testWidgets('opens, closes, and keeps the main window interactive',
      (tester) async {
    await tester.pumpWidget(const _MinimalMainWindow());

    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 1'), findsOneWidget);

    final child = await WindowController.create(
      const WindowConfiguration(
        arguments: _childArgument,
        hiddenAtLaunch: false,
      ),
    );
    await _waitForChild(child);
    await _controlChannel.invokeMethod<void>('close');
    await _waitForChildToClose(child.windowId);

    await tester.tap(find.byKey(const Key('main_increment')));
    await tester.pump();
    expect(find.text('Main counter: 2'), findsOneWidget);
  });
}

Future<void> _startChildWindow() async {
  await windowManager.ensureInitialized();
  await _controlChannel.setMethodCallHandler((call) async {
    if (call.method == 'ready') return true;
    if (call.method == 'close') {
      await windowManager.close();
      return null;
    }
    throw UnsupportedError('Unknown minimal child command: ${call.method}');
  });
  runApp(const _MinimalChildWindow());
}

Future<void> _waitForChild(WindowController child) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    try {
      if (await _controlChannel.invokeMethod<bool>('ready') == true) return;
    } on WindowChannelException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  throw StateError('Timed out waiting for minimal child ${child.windowId}');
}

Future<void> _waitForChildToClose(String windowId) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final windows = await WindowController.getAll();
    if (windows.every((window) => window.windowId != windowId)) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw StateError('Timed out closing minimal child $windowId');
}

class _MinimalMainWindow extends StatefulWidget {
  const _MinimalMainWindow();

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
                  onPressed: () => setState(() => _counter += 1),
                  child: const Text('Increment main counter'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MinimalChildWindow extends StatelessWidget {
  const _MinimalChildWindow();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Minimal child window')),
        ),
      );
}
