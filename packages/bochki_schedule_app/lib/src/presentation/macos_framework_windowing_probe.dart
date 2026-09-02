// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

Future<void> runMacosFrameworkWindowingProbe() async {
  final result = Completer<bool>();
  runApp(_FrameworkWindowingProbe(onComplete: result.complete));
  unawaited(Future<void>.delayed(const Duration(seconds: 10), () {
    if (!result.isCompleted) result.complete(false);
  }));

  if (await result.future) {
    debugPrintSynchronously(
        '[framework-windowing-probe] PASS child first frame reached main');
    exit(0);
  }
  debugPrintSynchronously(
      '[framework-windowing-probe] FAIL child first frame was not delivered');
  exit(1);
}

class _FrameworkWindowingProbe extends StatefulWidget {
  const _FrameworkWindowingProbe({required this.onComplete});

  final void Function(bool) onComplete;

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
              home: _ProbeMainWindow(onComplete: widget.onComplete),
            ),
          ),
        ],
      );
}

class _ProbeMainWindow extends StatefulWidget {
  const _ProbeMainWindow({required this.onComplete});

  final void Function(bool) onComplete;

  @override
  State<_ProbeMainWindow> createState() => _ProbeMainWindowState();
}

class _ProbeMainWindowState extends State<_ProbeMainWindow> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openChild());
  }

  void _openChild() {
    if (_opened || !mounted) return;
    _opened = true;
    final registry = WindowRegistry.of(context);
    late final WindowEntry entry;
    final controller = WindowController(
      title: 'Framework child',
      size: const Size(320, 180),
      delegate: _ProbeWindowDelegate(
        onDestroyed: () => registry.unregister(entry),
      ),
    );
    entry = WindowEntry(
      controller: controller,
      builder: (context) => _ProbeChild(
        onFirstFrame: () => widget.onComplete(true),
      ),
    );
    registry.register(entry);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _openChild,
            child: const Text('Open framework child'),
          ),
        ),
      );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFirstFrame());
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Framework child window')),
        ),
      );
}

class _ProbeWindowDelegate with WindowControllerDelegate {
  _ProbeWindowDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}
