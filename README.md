# ПО Расписание Бочки

Локальное desktop-приложение на Flutter для ручного составления расписания multi-day тренинга.

На текущем этапе репозиторий готовит baseline под desktop-first приложение для `macOS` и `Windows`.
`Linux` используется как вспомогательная среда разработки и CI.

## Почему Flutter

Вариант `Electron + Vue3` был отменен после проблем с запуском на `macOS`.
Текущий проект строится на Flutter как на более предсказуемом desktop stack для поставки пользователю на Mac.

## Структура монорепо

```text
.
├── melos.yaml
├── packages
│   ├── bochki_schedule_app
│   ├── bochki_schedule_domain
│   └── bochki_schedule_infra
└── .github
```

Пакеты:

- `bochki_schedule_app` - будущий desktop application shell.
- `bochki_schedule_domain` - доменные модели и правила.
- `bochki_schedule_infra` - файловая и системная инфраструктура.

Архитектурные решения фиксируются в [`docs/adr`](docs/adr).

## Текущая архитектура

Сейчас редактирование справочника `Участники` уже разложено по явным слоям и используется в коде.
Рефакторинг выполнен в рамках issue [`#17`](https://github.com/alekseibq/bochki-schedule-flutter/issues/17) и опирается на ADR про layered architecture и local JSON storage:

- [`docs/adr/0003-use-layered-lasagna-architecture.md`](docs/adr/0003-use-layered-lasagna-architecture.md)
- [`docs/adr/0004-store-project-data-as-local-json.md`](docs/adr/0004-store-project-data-as-local-json.md)

Цепочка сейчас такая:

```text
UI
  -> ParticipantsDirectoryDialog
  -> ParticipantsDirectoryUseCase
  -> ProjectDocumentRepository
  -> JsonProjectDocumentRepository
  -> project.json
```

В терминах слоёв:

```text
Presentation -> Application -> Domain Port -> Infrastructure -> File
```

Роли на текущий момент:

- `BochkiShell` загружает `ProjectDocument` и открывает диалог участников.
- `ParticipantsDirectoryDialog` отвечает только за presentation-state.
- `ParticipantsDirectoryUseCase` содержит бизнес-логику участников.
- `ProjectDocumentRepository` определяет контракт загрузки и сохранения документа.
- `JsonProjectDocumentRepository` пишет локальный JSON атомарно через `AtomicFileWriter`.

## Требования

- `git`
- `FVM`
- Flutter SDK версии из `.fvmrc`
- `melos`
- для Linux desktop integration: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

## Подготовка окружения

1. Установить `FVM`.
2. Установить Flutter SDK через `FVM`.
3. Выполнить `dart pub get` в корне репозитория.
4. Активировать `melos`.

Пример локального workflow:

```bash
fvm install
fvm use
dart pub get
dart pub global activate melos
```

Если `melos` установлен глобально, убедитесь, что он доступен в `PATH`.
Альтернатива без глобальной установки: `dart run melos <command>`.

## Команды workspace

```bash
melos bootstrap
melos run analyze
melos run test
melos run format-check
melos run app-test-integration-linux
make windows-release
```

Отдельные manual smoke шаги для desktop baseline описаны в [`docs/testing.md`](docs/testing.md).

Смысл команд:

- `bootstrap` - подтянуть зависимости по всем пакетам.
- `analyze` - прогнать статический анализ по всем пакетам.
- `test` - прогнать тесты по всем пакетам.
- `format-check` - проверить форматирование без автоматической правки.
- `app-test-integration-linux` - прогнать integration test shell на Linux desktop runner.
- `make windows-release` - собрать Windows release и упаковать его в ZIP на Windows-машине.

## Процесс разработки

- Все изменения идут через feature branches и Pull Request.
- Merge в `main` - только через PR.
- Для коммитов используем Conventional Commits.
- Весь код пишет Codex, архитектурные и спорные решения обсуждаются отдельно и фиксируются в документации.

## CI

Основной pipeline запускается в GitHub Actions и состоит из таких проверок:

- `pr-title` - проверка названия PR по Conventional Commits.
- `linux-checks` - `bootstrap`, `format-check`, `analyze`, unit/widget tests и Linux desktop integration test.
- `windows-desktop` - Windows release build, desktop integration test и публикация ZIP artifact.
- `macos-release` - macOS release build и публикация артефакта приложения.

Для merge в `main` должны быть зелеными все обязательные checks.
macOS артефакт на текущем этапе неподписан и не notarized.

## Troubleshooting

- Если `melos bootstrap` падает, сначала выполните `dart pub get` в корне репозитория.
- Если Linux desktop integration test не стартует локально, проверьте наличие `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`.
- Если `window_manager` требует desktop target, убедитесь, что нужная платформа включена через `flutter config`.

## Следующие шаги

Текущий baseline уже включает:

- монорепо и workspace tooling,
- архитектурный фундамент и ADR,
- desktop shell,
- базовые UI-проверки,
- GitHub Actions pipeline.

Следующие инкременты добавят предметный функционал:

- document workflow (`New/Open/Save`),
- реальные справочники `Тренеры` и `Участники`,
- модель расписания и операции редактирования,
- печать и экспорт.

## Текущие архитектурные оговорки

- Стратегия идентификаторов пока временная: используется глобальный последовательный `int` generator.
- Формат данных проектируется под локальный JSON-документ с обязательным `schemaVersion`.
