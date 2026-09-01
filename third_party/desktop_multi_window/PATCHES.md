# Local changes

This is a source copy of `desktop_multi_window` 0.3.0, retained under its
Apache-2.0 license. It is used as a path dependency so desktop builds are
reproducible.

The macOS implementation keeps windows with `hiddenAtLaunch: true` out of the
window compositor until Dart explicitly calls `show()`. Upstream called
`orderFront(nil)` before honoring that flag, causing a visible frame at the
default origin before the final size and position were configured.

The Windows source documents the matching hidden-start contract.

On Windows, closed child-window Flutter engines are removed after the current
native message has finished dispatching. Previously they remained owned by the
manager until another child window was created. That left an engine receiving
Vsync after its native window had gone away, which could log
`FlutterEngineOnVsync ... kInternalInconsistency` and occasionally crash the
application. The deferred cleanup is drained by the application message loop;
it is intentionally not performed from `WM_DESTROY`, where it would delete an
object while its `OnDestroy` method is still running.
