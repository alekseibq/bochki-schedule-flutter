# Changelog

## v0.3.0

Release date: 2026-07-08

### Highlights

- Added CRUD for the `ProcedureKind` directory in the desktop app.
- Introduced `ProcedureKindPattern` variants with pattern-aware validation and UI behavior.
- Persisted procedure kinds in the project document and covered the new flows with tests.

### Details

- `feat(app): add procedure kinds CRUD`

## v0.2.4

Release date: 2026-07-05

### Highlights

- Split macOS release publishing into Intel and Apple Silicon artifacts.
- Kept macOS release artifact generation on release triggers only.

### Details

- `ci: split macOS release artifacts by architecture`

## v0.2.3

Release date: 2026-07-05

### Highlights

- Made project data portable by storing `project.json` and `logs/app.log` beside the launched desktop binary by default.
- Added `--app-data-dir` for CI and local smoke runs that need an explicit temp directory.

### Details

- `fix: store project data beside launch binary`

## v0.2.2

Release date: 2026-07-05

### Highlights

- Fixed macOS startup by not awaiting `windowManager.waitUntilReadyToShow` before `runApp`.
- Kept the new GitHub Release asset publishing flow in CI.

### Details

- `fix(app): do not await macos window readiness before runApp`

## v0.2.1

Release date: 2026-07-05

### Highlights

- Published the macOS release archive directly to the GitHub Release page.
- Added a manual `workflow_dispatch` path to backfill release assets for a specific tag.
- Kept the existing CI checks for PRs and `main` pushes unchanged.

### Details

- `ci: publish macos release assets`

## v0.2.0

Release date: 2026-07-05

### Highlights

- Added the trainers directory scaffold and aligned it with the shared directory UI.
- Introduced asynchronous project document persistence.
- Reworked participants editing flows, including the table state machine and UX fixes.
- Added Windows release packaging support and startup instructions.
- Stabilized desktop integration tests and dialog assertions.

### Details

- `feat: add participants directory dialog (#16)`
- `refactor: introduce participants use case and repository (#18)`
- `refactor(participants): layer participants CRUD architecture (#19)`
- `feat(app): redesign participants dialog editing UI (#20)`
- `feat(app): improve participants grid editing ux`
- `fix(app): polish participants dialog ux`
- `feat(participants): model table interactions as state machine`
- `fix(app): make participant row selection instant`
- `feat(app): async project document persistence (#30)`
- `feat(app): add trainers directory on shared scaffold`
- `style(app): format shared directory changes`
- `fix(app): stabilize desktop integration menu opening`
- `fix(app): scope desktop integration dialog assertion`
- `docs: add Windows startup instructions (#32)`
- `feat: add windows release artifact (#14)`

## v0.1.0

Initial release baseline.
