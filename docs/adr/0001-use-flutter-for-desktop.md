# ADR 0001: Use Flutter For Desktop

## Context

The project needs a local desktop application that is developed from Ubuntu over SSH, can be manually checked on Windows, and is delivered to a macOS customer through GitHub artifacts.

Electron was evaluated first and rejected after runtime issues on macOS before application code execution.

## Decision

Use Flutter as the primary desktop stack for the project.

## Consequences

- The codebase is centered around Dart and Flutter tooling.
- Desktop targets can be built for Windows and macOS from one stack.
- The team accepts Flutter-specific setup work in CI and local environments.
