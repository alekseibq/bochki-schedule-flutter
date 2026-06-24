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

## Требования

- `git`
- `FVM`
- Flutter SDK версии из `.fvmrc`
- `melos`

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

## Команды workspace

```bash
melos bootstrap
melos run analyze
melos run test
melos run format-check
```

Смысл команд:

- `bootstrap` - подтянуть зависимости по всем пакетам.
- `analyze` - прогнать статический анализ по всем пакетам.
- `test` - прогнать тесты по всем пакетам.
- `format-check` - проверить форматирование без автоматической правки.

## Процесс разработки

- Все изменения идут через feature branches и Pull Request.
- Merge в `main` - только через PR.
- Для коммитов используем Conventional Commits.
- Весь код пишет Codex, архитектурные и спорные решения обсуждаются отдельно и фиксируются в документации.

## Следующие шаги

Текущий baseline покрывает только структуру монорепо и workspace tooling.
Следующие инкременты добавят:

- архитектурный фундамент и ADR,
- desktop shell,
- тесты UI,
- GitHub Actions pipeline.

## Текущие архитектурные оговорки

- Стратегия идентификаторов пока временная: используется глобальный последовательный `int` generator.
- Формат данных проектируется под локальный JSON-документ с обязательным `schemaVersion`.
