# Local changes

This is a source copy of `desktop_multi_window` 0.3.1, retained under its
Apache-2.0 license. It is used as a path dependency so desktop builds are
reproducible.

On Windows, `DartProject.set_ui_thread_policy` is omitted because it is not
available in the application's Flutter 3.24.5 embedder. Closed child-window
Flutter engines are removed after the current
native message has finished dispatching. Previously they remained owned by the
manager until another child window was created. That left an engine receiving
Vsync after its native window had gone away, which could log
`FlutterEngineOnVsync ... kInternalInconsistency` and occasionally crash the
application. The deferred cleanup is drained by the application message loop;
it is intentionally not performed from `WM_DESTROY`, where it would delete an
object while its `OnDestroy` method is still running.
