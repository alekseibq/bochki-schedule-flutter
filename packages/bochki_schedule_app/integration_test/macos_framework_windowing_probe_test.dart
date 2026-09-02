// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates a child view in the main Flutter engine',
      (tester) async {
    final childReadyCount = ValueNotifier<int>(0);
    await tester.pumpWidget(_FrameworkWindowingProbe(
      childReadyCount: childReadyCount,
    ));

    await tester.tap(find.byKey(const Key('open_framework_child')));
    await tester.pumpAndSettle();

    expect(find.text('Main child-ready count: 1'), findsOneWidget);
  });
}

class _FrameworkWindowingProbe extends StatefulWidget {
  const _FrameworkWindowingProbe({required this.childReadyCount});

  final ValueNotifier<int> childReadyCount;

  @override
  State<_FrameworkWindowingProbe> createState() =>
      _FrameworkWindowingProbeState();
}

class _FrameworkWindowingProbeState extends State<_FrameworkWindowingProbe> {
  late final WindowController _mainController;

  @override
  void initState() {
    super.initState();
    _mainController = WindowController(
      size: const Size(640, 480),
      title: 'Framework windowing probe',
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WindowManager(
        initialWindows: [
          WindowEntry(
            controller: _mainController,
            builder: (context) => MaterialApp(
              home: _ProbeMainWindow(childReadyCount: widget.childReadyCount),
            ),
          ),
        ],
      );
}

class _ProbeMainWindow extends StatelessWidget {
  const _ProbeMainWindow({required this.childReadyCount});

  final ValueNotifier<int> childReadyCount;

  @override
  Widget build(BuildContext context) {
    final registry = WindowRegistry.of(context);
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: childReadyCount,
          builder: (context, readyCount, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Main child-ready count: $readyCount'),
              ElevatedButton(
                key: const Key('open_framework_child'),
                onPressed: () {
                  late final WindowEntry entry;
                  final controller = WindowController(
                    title: 'Framework child',
                    size: const Size(320, 180),
                    delegate: CallbackWindowControllerDelegate(
                      onDestroyed: () => registry.unregister(entry),
                    ),
                  );
                  entry = WindowEntry(
                    controller: controller,
                    builder: (context) => _ProbeChild(
                      onFirstFrame: () => childReadyCount.value += 1,
                    ),
                  );
                  registry.register(entry);
                },
                child: const Text('Open framework child'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProbeChild extends StatefulWidget {
  const _ProbeChild({required this.onFirstFrame});

  final VoidCallback onFirstFrame;

  @override
  State<_ProbeChild> createState() => _ProbeChildState();
}

class _ProbeChildState extends State<_ProbeChild> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFirstFrame();
    });
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Framework child window')),
        ),
      );
}

class CallbackWindowControllerDelegate with WindowControllerDelegate {
  CallbackWindowControllerDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}
