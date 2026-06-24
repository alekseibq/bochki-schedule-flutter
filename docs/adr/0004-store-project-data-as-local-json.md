# ADR 0004: Store Project Data As Local JSON

## Context

There is no backend, no sync, and no multi-user workflow. Project data is expected to stay small.

## Decision

Store project data as local JSON documents on the file system.

## Consequences

- A project file is easy to copy, archive, and exchange.
- The system needs explicit schema versioning and safe-write behavior.
- Data migration remains the application's responsibility when the schema evolves.
