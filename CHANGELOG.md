# Changelog

## v0.13.0

Release date: 2026-08-25

### Highlights

- Improved the procedure-kind form and unified procedure roles for people.
- Refined schedule reassignment, template loading, free-time results, and workday date selection.
- Updated DOCX schedule exports to match the established print layout.

### Details

- `feat(print): match legacy DOCX layout (#139)`
- `feat: improve procedure kind form (#131)`
- `feat(domain): unify human procedure roles (#122)`
- `fix(directories): clear procedure references on person deletion (#120)`
- `fix(workdays): select calendar dates (#123)`
- `fix(procedure-kinds): block deletion with assignments`
- `fix(free-time): fit filters and scroll results`
- `fix: handle cancelled template loads and stale quick assignments`
- `fix: stabilize nested desktop windows (#138)`
- `fix(ci): fail workspace tests on package errors (#136)`

## v0.12.0

Release date: 2026-08-24

### Highlights

- Added an action to clear the schedule.
- Added separate desktop windows for directory management and active-record counts in the Directories menu.
- Added minute-level precision to program time limits.

### Details

- `feat(schedule): add schedule clearing (#114)`
- `feat(directories): open CRUD in desktop windows (#113)`
- `feat(directories): show active record counts in menu (#111)`
- `feat: add minute precision to program time limits (#115)`
- `fix(directories): restore people table CRUD (#117)`
- `fix(directories): refresh menu counts after mutations (#119)`
- `fix(templates): rebuild runtime after loading (#110)`
- `fix(schedule): retain confirmation state through dialog close`

## v0.11.0

Release date: 2026-08-15

### Highlights

- Added saved schedule templates for reusing common scheduling setups.
- Added quick reassignment actions and a free-time report.
- Added desktop windows and documents for procedure tools and statistics.

### Details

- `feat: add saved schedule templates (#102)`
- `feat: add quick reassignment dialog (#101)`
- `feat(reports): add free time report (#100)`
- `feat(app): open procedure tools in desktop windows (#97)`
- `feat(app): add procedure statistics dialog (#95)`
- `feat(reports): render accompaniment statistics cells`
- `fix(schedule): allow assistants as procedure participants`
- `fix(directory): save inline edits when confirming dialog`

## v0.10.0

Release date: 2026-07-21

### Highlights

- Added procedure-assignment summary tooltips for participants and assistants.
- Made the Directories menu appear and close instantly.

### Details

- `feat(schedule): add person summary tooltips (#76)`
- `fix(ui): show directories menu instantly (#77)`

## v0.9.0

Release date: 2026-07-21

### Highlights

- Made the procedure sessions table more compact for a clearer scheduling workflow.

### Details

- `feat(ui): compact procedure sessions table (#75)`

## v0.8.0

Release date: 2026-07-21

### Highlights

- Added a startup diagnostics screen with a clear recovery path for initialization problems.
- Refined the procedure-session filters layout for a more usable scheduling workflow.

### Details

- `feat(app): add startup diagnostics screen (#73)`
- `feat(ui): refine procedure session filters layout (#71)`

## v0.7.1

Release date: 2026-07-20

### Highlights

- Fixed macOS startup in the sandboxed application environment.
- Added a user-facing startup error screen for recoverable initialization failures.

### Details

- `fix(app): support sandboxed macOS startup`

## v0.7.0

Release date: 2026-07-20

### Highlights

- Added print preset configuration for schedule exports.
- Added DOCX export for print schedules.
- Added desktop flows for saving and opening exported schedule documents.

### Details

- `feat(app): add print preset dialog`
- `feat(app): export print schedules to docx (#66)`

## v0.6.0

Release date: 2026-07-15

### Highlights

- Added editable program settings in the desktop app.
- Applied program settings to procedure session scheduling logic.
- Added procedure session conflict detection and improved row selection responsiveness.

### Details

- `feat(app): add editable program settings`
- `fix(procedure-sessions): apply program settings to schedule logic`
- `fix(app): make procedure session row selection instant`
- `feat: add procedure session conflict detection (#62)`

## v0.5.0

Release date: 2026-07-11

### Highlights

- Added the procedure sessions workflow in the desktop app, including create, edit, and filtering flows.
- Unified assistants and participants under shared human storage in the project document.
- Renamed the trainer terminology to assistants across the product and tests.

### Details

- `feat(app): add procedure sessions workflow`
- `feat(app): unify participant and assistant storage`
- `refactor: rename trainers to assistants`

## v0.4.0

Release date: 2026-07-10

### Highlights

- Added CRUD for the `Workday` directory in the desktop app.
- Added project document persistence and test coverage for workdays.
- Refined the procedure kind form layout and corrected default capacity behavior.

### Details

- `feat(app): add workday directory CRUD (#47)`
- `fix(app): default procedure kind capacity to 1 (#45)`
- `fix(ui): update procedure kinds table headers`
- `feat(app): refine procedure kind form layout`

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

- Added the assistants directory scaffold and aligned it with the shared directory UI.
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
- `feat(app): add assistants directory on shared scaffold`
- `style(app): format shared directory changes`
- `fix(app): stabilize desktop integration menu opening`
- `fix(app): scope desktop integration dialog assertion`
- `docs: add Windows startup instructions (#32)`
- `feat: add windows release artifact (#14)`

## v0.1.0

Initial release baseline.
