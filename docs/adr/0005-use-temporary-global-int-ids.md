# ADR 0005: Use Temporary Global Int IDs

## Context

The preferred long-term strategy would be stable opaque IDs, but the current project phase prioritizes simplicity and fast iteration.

## Decision

Use a single sequential global `int` ID generator for early project versions.

## Consequences

- The implementation is simple and easy to inspect.
- Array indexes are still avoided as identifiers.
- A future migration away from sequential `int` IDs is explicitly accepted as a project risk.
