import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const macosMinimalChildArgument = 'macos-minimal-child';
const macosMinimalChildControlChannel = WindowMethodChannel(
  'bochki_schedule/macos_minimal_child_control',
  mode: ChannelMode.unidirectional,
);
const macosMinimalChildReadyChannel = WindowMethodChannel(
  'bochki_schedule/macos_minimal_child_ready',
  mode: ChannelMode.bidirectional,
);

Future<void> startMacosMinimalChild(String windowId) async {
  macosMinimalTrace('child bootstrap begins windowId=$windowId');
  await windowManager.ensureInitialized();
  macosMinimalTrace('child windowManager initialized windowId=$windowId');
  await macosMinimalChildControlChannel.setMethodCallHandler((call) async {
    macosMinimalTrace('child control ${call.method} windowId=$windowId');
    if (call.method == 'bootstrapReady') return true;
    if (call.method == 'close') {
      await windowManager.close();
      return null;
    }
    throw UnsupportedError('Unknown minimal child command: ${call.method}');
  });
  await macosMinimalChildReadyChannel.setMethodCallHandler((call) async {
    macosMinimalTrace(
        'child unexpectedly received ${call.method} windowId=$windowId');
    throw UnsupportedError(
        'Unknown command on child ready channel: ${call.method}');
  });
  macosMinimalTrace('child IPC handlers registered windowId=$windowId');
  runApp(_MacosMinimalChildWindow(
    onFirstFrame: () => _announceMacosMinimalChildReady(windowId),
  ));
}

Future<void> _announceMacosMinimalChildReady(String windowId) async {
  macosMinimalTrace('child first frame rendered windowId=$windowId');
  for (var attempt = 0; attempt < 100; attempt += 1) {
    try {
      await macosMinimalChildReadyChannel
          .invokeMethod<bool>('ready', {'windowId': windowId});
      macosMinimalTrace('child ready delivered windowId=$windowId');
      return;
    } on WindowChannelException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  throw StateError('Timed out delivering minimal child ready for $windowId');
}

void macosMinimalTrace(String message) {
  debugPrintSynchronously('[macos-minimal] $message');
}

class _MacosMinimalChildWindow extends StatelessWidget {
  const _MacosMinimalChildWindow({required this.onFirstFrame});

  final Future<void> Function() onFirstFrame;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: _MacosMinimalChildContent(onFirstFrame: onFirstFrame),
      );
}

class _MacosMinimalChildContent extends StatefulWidget {
  const _MacosMinimalChildContent({required this.onFirstFrame});

  final Future<void> Function() onFirstFrame;

  @override
  State<_MacosMinimalChildContent> createState() =>
      _MacosMinimalChildContentState();
}

class _MacosMinimalChildContentState extends State<_MacosMinimalChildContent> {
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
