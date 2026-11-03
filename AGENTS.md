# Repository context for AI

## Context selection

Перед проектированием или изменением функциональности прочитай
[`docs/implementation-playbook.md`](docs/implementation-playbook.md), определи
vertical slice и ближайший типовой образец, затем прочитай все документы,
на которые этот образец ссылается. Зафиксируй применимые инварианты в плане и
не вводи новый паттерн, если образец покрывает задачу. Бизнес-термины и правила
из playbook (в частности, роли людей и групповые процедуры) применяй только
для релевантного slice; не дублируй их в этом файле.

## Universal invariants

- Сохраняй слоистую цепочку `Widget -> ViewModel -> UseCase -> repository
  port -> data adapter`; widget не работает с JSON, файлами или persistence, а
  бизнес-правило не находится в widget. Собирай зависимости только в
  `AppBootstrap`/`AppServices`. Источник:
  [`ARCHITECTURE.md`](ARCHITECTURE.md) и
  [playbook](docs/implementation-playbook.md). Проверка: unit/widget-тесты
  затронутого slice и `melos run analyze`.
- Данные проекта изменяются через repository и его
  `ProjectDocumentSyncPart`; сохранение выполняет
  `ProjectDocumentSyncCoordinator` и атомарный writer. Не записывай
  `project.json` напрямую из feature. Для новой части документа добавь
  backward-compatible чтение, bootstrap-нормализацию, регистрацию sync part и
  тесты. Источник: [playbook](docs/implementation-playbook.md) и
  [ADR 0004](docs/adr/0004-store-project-data-as-local-json.md). Проверка:
  tests `ProjectDocument`, data/repository и sync.
- UI-настройки не являются проектными данными: храни их в соседнем
  `ui_settings.json` через `UiSettingsRepository`, а не в `ProjectDocument`.
  Источник: [playbook](docs/implementation-playbook.md). Проверка: tests
  `UiSettingsRepository`.
- Идентификаторы — сохранённые глобальные последовательные `int`; не
  используй индекс списка как идентификатор. Источник:
  [ADR 0005](docs/adr/0005-use-temporary-global-int-ids.md) и
  [playbook](docs/implementation-playbook.md). Проверка: domain/data tests
  изменённой сущности.
- Для дочернего desktop-окна production-путь идёт через
  `DesktopWindowCoordinator`: один `DesktopWindowKind` соответствует одному
  engine, обычное закрытие скрывает и переиспользует окно, закрытие главного
  окна каскадно уничтожает children. Источник:
  [desktop-window-lifecycle](docs/desktop-window-lifecycle.md) и
  [ADR 0007](docs/adr/0007-reuse-child-desktop-windows.md). Проверка:
  `desktop_windows_test.dart` и native smoke из [testing](docs/testing.md).
- Для feature с дочерним desktop-окном обязателен один общий `...Content` /
  `...FormContent` и feature-specific ViewModel/operations-контракт; native
  host и fallback Dialog только размещают content с IPC/direct adapter. Не
  создавай независимые UI или бизнес-логику для путей. Источник:
  [ADR 0008](docs/adr/0008-feature-content-for-desktop-and-fallback.md).
  Проверка: feature content, direct/IPC adapter tests.

# Command approvals

Do not request `require_escalated` or separate confirmation for commands that
are already allowed by a `prefix_rule` in `~/.codex/rules/default.rules` when
the action is explicitly within the user's requested task.

For such commands, execute them directly: do not pass
`sandbox_permissions: "require_escalated"` or a `justification` parameter.

In particular, when the user has explicitly requested the workflow, execute
without additional confirmation: `gh issue comment`, `gh pr create`, `gh pr
edit`, `gh pr checks`, `gh pr merge`, `gh run watch`, `git add`, `git commit`,
`git push`, `git pull`, and `git checkout`.

Request confirmation only for actions outside the requested scope, destructive
operations, or commands without an allow rule.
