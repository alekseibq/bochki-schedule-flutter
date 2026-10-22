# Architecture

Проект — Flutter desktop-приложение в Melos-монорепо с простой слоистой
архитектурой и vertical slices. Практические правила, рабочие рецепты и ссылки
на образцы находятся в [Implementation playbook](docs/implementation-playbook.md).

```text
Flutter Widget
  -> ChangeNotifier ViewModel
  -> feature UseCase / Validator
  -> repository port
  -> data adapter
  -> ProjectDocumentSyncCoordinator
  -> ProjectDocument -> project.json
```

## Границы пакетов

- `bochki_schedule_domain` — независимые от Flutter модели project document,
  schema version, ID и базовые контракты.
- `bochki_schedule_infra` — файловая инфраструктура, JSON repository,
  атомарная запись, пути и логирование; может зависеть от `domain`.
- `bochki_schedule_app` — feature domain/use cases, data adapters, Flutter UI,
  bootstrap и desktop presentation.

В `app` новый предметный функционал добавляется vertical slice-ом:
`domain/<feature>`, `data/<feature>`, `features/<feature>` и тесты рядом с
соответствующим слоем. `AppBootstrap` — единственный composition root,
`AppServices` передаёт собранные зависимости в presentation.

## Основные правила

- Widgets не обращаются напрямую к JSON, файлам и persistence; бизнес-правила
  не размещаются в widgets.
- Репозитории меняют in-memory document через sync parts, а сохранение
  координирует `ProjectDocumentSyncCoordinator`; прямой save из feature не
  допускается.
- Данные проекта хранятся в `project.json`; UI-настройки — в отдельном
  соседнем `ui_settings.json`.
- Дочерние production-окна создаёт и переоткрывает
  `DesktopWindowCoordinator`; их детальный контракт описан в
  [desktop-window-lifecycle.md](docs/desktop-window-lifecycle.md).

Архитектурные мотивы и долгосрочные решения фиксируются в [ADR](docs/adr).
