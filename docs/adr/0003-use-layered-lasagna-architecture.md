# ADR 0003: Use Simple Layered Architecture

## Context

The application is local-only and relatively small, but it still needs testable boundaries and a clear place for infrastructure concerns.

## Decision

Use a simple layered "lasagna" architecture with three main packages:

- `bochki_schedule_app`
- `bochki_schedule_domain`
- `bochki_schedule_infra`

## Consequences

- `domain` stays independent from UI and infrastructure.
- `infra` can depend on `domain`.
- `app` composes the system without introducing heavyweight patterns too early.
