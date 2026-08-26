# Local patches

## Windows multi-window event routing

`window_manager` 0.4.3 stored its method channel in a process-global variable.
Desktop multi-window applications create one plugin instance per Flutter engine,
so creating a child window replaced the channel used by existing windows. Native
events such as `WM_CLOSE` were then delivered to the newest child, and destroying
that child cleared the channel for every remaining window.

The Windows plugin now owns its method channel per `WindowManagerPlugin`
instance. This keeps each window's `WM_CLOSE` event in its own Flutter engine.
