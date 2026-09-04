# Local changes

This source copy is retained under the Apache-2.0 license and is used as a
path dependency so desktop builds are reproducible.

For the #183 macOS experiment, `macos/desktop_multi_window/Sources` is the
hosted `desktop_multi_window` 0.3.1 implementation. Its only local change is
in `FlutterMultiWindowPlugin.CreateWindow`: a child with
`hiddenAtLaunch: true` is not ordered front until Dart explicitly calls
`show()`. This is the macOS hidden-start anti-flicker patch under test.

On Windows, closed child-window Flutter engines are removed after the current
native message has finished dispatching. Previously they remained owned by the
manager until another child window was created. That left an engine receiving
Vsync after its native window had gone away, which could log
`FlutterEngineOnVsync ... kInternalInconsistency` and occasionally crash the
application. The deferred cleanup is drained by the application message loop;
it is intentionally not performed from `WM_DESTROY`, where it would delete an
object while its `OnDestroy` method is still running.
