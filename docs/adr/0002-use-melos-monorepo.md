# ADR 0002: Use Melos Monorepo

## Context

The project is expected to grow into multiple layers with separate responsibilities: application shell, domain logic, and infrastructure.

## Decision

Organize the repository as a monorepo managed by Melos.

## Consequences

- Shared commands for bootstrap, analysis, tests, and formatting are centralized.
- Package boundaries are visible early and can be preserved as the application grows.
- CI can run the same workspace commands as local development.
