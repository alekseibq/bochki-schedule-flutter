# ADR 0007: Reuse Child Desktop Windows

## Status

Accepted experimentally.

## Context

Destroying a Flutter engine for every ordinary child-window close makes
reopening slow and makes lifecycle behaviour differ by window type.

## Decision

Every child `DesktopWindowKind` is a singleton for the lifetime of the main
window engine. An ordinary close hides the child and preserves its engine.
Reopening the same kind reuses that engine, restores/focuses its window and
refreshes its data. A close of a parent hides its whole descendant chain.

Closing the main window is the exception: it cascade-closes descendants for
real. The main window waits up to ten seconds for them. On timeout it records
the failure, asks the user to confirm, and then continues closing.

This is an experiment. Reconsider it at the first failure involving a child
window chain.

## Consequences

- Hidden windows must not keep their parent UI disabled.
- Geometry is retained per window kind for the current application session.
- Child IPC handlers must support a reopen request and fresh input state.
- Native smoke coverage is required on macOS and Windows.
