# Local changes

This is a source copy of `desktop_multi_window` 0.3.0, retained under its
Apache-2.0 license. It is used as a path dependency so desktop builds are
reproducible.

The macOS implementation keeps windows with `hiddenAtLaunch: true` out of the
window compositor until Dart explicitly calls `show()`. Upstream called
`orderFront(nil)` before honoring that flag, causing a visible frame at the
default origin before the final size and position were configured.

The Windows source documents the matching hidden-start contract.
