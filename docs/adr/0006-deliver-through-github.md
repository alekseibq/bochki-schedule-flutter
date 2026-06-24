# ADR 0006: Deliver Through GitHub

## Context

The repository, CI, and artifact exchange all flow through GitHub.

## Decision

Use GitHub as the canonical channel for source code, pull requests, CI, and build artifacts.

## Consequences

- Branch protection and PR checks can enforce the agreed workflow.
- macOS desktop artifacts can be produced and shared through GitHub Actions.
- Release automation can be added later without changing the distribution channel.
