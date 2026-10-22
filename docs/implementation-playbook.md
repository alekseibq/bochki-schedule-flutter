# Implementation playbook

Краткий практический конспект для работы над issue. Перед проектированием
изменения найдите в этом документе ближайший существующий образец и развивайте
его, а не вводите новый паттерн. Этот документ описывает текущую реализацию;
причины ключевых решений и их история остаются в [ADR](adr).

## Перед началом задачи

1. Определите vertical slice и затронутые данные, UI и окна.
2. Найдите ближайший образец в разделе «Типовые задачи» и сначала изучите его
   код и тесты.
3. Проверьте связанные ADR. Для дочерних окон обязательно прочитайте
   [жизненный цикл окон](desktop-window-lifecycle.md).
4. Если решение меняет устойчивую архитектурную границу или инвариант, сначала
   обсудите его и добавьте ADR; не маскируйте такое решение под локальный
   рефакторинг.

## Карта кода и зависимости

Репозиторий — Melos-монорепо с тремя пакетами.

| Пакет/каталог | Ответственность |
| --- | --- |
| `bochki_schedule_domain` | Общий проектный документ, его schema version, ID и контракты файловой инфраструктуры. Не зависит от Flutter. |
| `bochki_schedule_infra` | Файловая инфраструктура: `JsonProjectDocumentRepository`, безопасная атомарная запись, пути и логирование. Может зависеть от `domain`. |
| `bochki_schedule_app/lib/src/domain/<feature>` | Прикладной домен: entity, repository port, use case, validator и доменные исключения конкретной функции. |
| `bochki_schedule_app/lib/src/data/<feature>` | Адаптеры портов над текущим `ProjectDocument` в памяти и DTO. |
| `bochki_schedule_app/lib/src/features/<feature>` | Flutter UI и `ChangeNotifier` ViewModel. |
| `bochki_schedule_app/lib/src/presentation` | Запуск приложения, shell и межоконная координация. |

Обычная цепочка зависимости: `Widget -> ViewModel -> UseCase -> repository
port -> data adapter -> ProjectDocument sync -> project.json`. Виджеты не
работают с JSON, файлами и persistence напрямую; Flutter не попадает в domain.

`AppBootstrap` — composition root: здесь создаются реализации, use cases и
все связи. `AppServices` — уже собранный набор зависимостей для presentation.
Новый сервис или use case подключается здесь, а не создаётся внутри widget.

## Принятые решения и инварианты

- Данные проекта хранятся в одном локальном `project.json`. Изменение
  репозитория меняет in-memory состояние, помечает свой
  `ProjectDocumentSyncPart` dirty и вызывает coordinator; JSON напрямую из
  feature не записывается. `ProjectDocumentSyncCoordinator` debounce-ит и
  сериализует сохранения, а `AtomicFileWriter` выполняет запись через
  временный файл.
- UI-настройки не являются данными проекта: они лежат рядом с `project.json` в
  отдельном `ui_settings.json`, которым владеет `UiSettingsRepository`. Туда
  относятся масштаб UI, размеры окон и ширины колонок; не добавляйте их в
  `ProjectDocument`.
- `ProjectDocument` — версия совместимого JSON-формата. Новые поля должны
  иметь безопасное чтение старых документов; нормализация/миграция выполняется
  при bootstrap и сохраняется через coordinator.
- ID пока глобальные последовательные `int`, сохранённые и передаваемые в
  app как строки. Не использовать индекс списка как идентификатор.
- `humans` — единая физическая коллекция. Семинарная роль —
  `SeminarRole.participant` или `SeminarRole.assistant`; доступные роли в
  назначенной процедуре — `ProcedureRole.client` и `ProcedureRole.companion`.
  Удаление человека — soft delete; use case проверяет ссылки на него.
- Нормализация, проверка уникальности, ссылочная целостность и бизнес-правила
  живут в use case/validator, а не в widget и не в DTO/data adapter.
- Для каждого `DesktopWindowKind` допустим один дочерний engine. Обычное
  закрытие скрывает и сохраняет engine для повторного открытия; закрытие
  главного окна каскадно уничтожает дочерние окна. Полный контракт — в
  [desktop-window-lifecycle.md](desktop-window-lifecycle.md).
- В production UI, вынесенный в дочернее окно, открывается через
  `DesktopWindowCoordinator`. Dialog-вариант такого flow — только fallback для
  widget-тестов; не добавляйте его как альтернативный production-путь.

## Терминология

Один и тот же человек может иметь разные роли в разных контекстах. Всегда
уточняйте контекст задачи и называйте поле/правило по нему.

| Контекст | Термин в коде | Значение |
| --- | --- | --- |
| Весь семинар, запись в справочнике `humans` | `participant` / `assistant` | Семинарная роль человека (`SeminarRole`). В старых задачах и текстах `assistant` может обозначаться словом «сопровождающий». |
| Одна назначенная процедура | `client` / `companion` | Роль человека именно в этой процедуре (`ProcedureRole`). «Участник» процедуры — client, «сопровождающий» процедуры — companion. |

Следствие: семинарный сопровождающий может быть участником (client) конкретной
процедуры, а участника этой процедуры может сопровождать другой человек. Не
сводите эти две оси ролей к одному флагу и не меняйте терминологию в старом
JSON без миграции.

## Типовые задачи и образцы

| Задача | Делать так | Основные образцы |
| --- | --- | --- |
| Новый простой именованный справочник | Переиспользовать generic named-directory CRUD: entity/port/use cases, feature ViewModel и конфигурацию диалога. | `domain/named_directory/`, `features/directory/`, `participants/`, `assistants/` |
| Справочник с собственной формой и полями | Создать feature-specific entity, validator, use cases и `Operations`-порт UI; не пытаться втиснуть поля в generic name-only экран. | `procedure_kinds/` |
| Новый день и проверка зависимых назначений | Валидировать в use case, считать ссылки при удалении, хранить через sync-part. | `workdays/` |
| Назначенная процедура или правило с несколькими сущностями | Держать целостность в feature use case/validator; для отображения использовать rich/projection модели, не раздувать Widget запросами. | `domain/procedure_sessions/`, `features/procedure_sessions/` |
| Новая часть `project.json` | Добавить поле в `ProjectDocument`, DTO/репозиторий с `ProjectDocumentSyncPart`, зарегистрировать part в `AppBootstrap`, добавить backward-compatible чтение и тесты. | `data/project_document/`, `data/workdays/`, `domain/project_document_test.dart` |
| Изменение UI-настроек | Менять `UiSettings`/`UiSettingsRepository`; это отдельный файл рядом с проектом. | `data/ui_settings/ui_settings_repository.dart` |
| Экспорт документа | Сначала build use case создаёт domain document, затем exporter-port и data adapter пишут DOCX атомарно; открытие файла — отдельный use case. | `domain/print_schedule/`, `data/print_schedule/`, `procedure_statistics/` |
| Новое дочернее окно или его поведение | Регистрировать kind и протокол в `DesktopWindowCoordinator`/lifecycle, сохранять singleton/reopen/cascade semantics. | `presentation/desktop_windows.dart`, `docs/desktop-window-lifecycle.md` |
| Подключение новой функции | Собрать зависимости только в `AppBootstrap`, выдать нужный use case через `AppServices`, затем создать ViewModel в presentation. | `app_bootstrap.dart`, `app_services.dart`, `presentation/shell/bochki_shell.dart` |

## Тесты и проверка

- Бизнес-правило или use case: unit-тест рядом с feature в `test/domain`.
- DTO/repository/sync: test в `test/data`, включая сериализацию, порядок и
  dirty/flush поведение при необходимости.
- ViewModel или widget: test в `test/features`; fallback Dialog допустим именно
  здесь, когда desktop channel недоступен.
- Межоконное изменение: unit-тесты `test/presentation/desktop_windows_test.dart`
  и manual/native smoke на Windows и macOS по [testing.md](testing.md).
- Перед PR запустить релевантные тесты, затем по возможности workspace checks:
  `melos run format-check`, `melos run analyze`, `melos run test`.

## Коротко: чего не делать

Не обходить существующий vertical slice, coordinator сохранения или оконный
coordinator; не дублировать generic CRUD; не помещать бизнес-правило в widget;
не смешивать данные проекта с UI-настройками; не создавать новую терминологию
для уже существующих ролей без явной миграции.

## Связанные документы

- [Architecture](../ARCHITECTURE.md) — краткая карта и границы.
- [ADR](adr) — мотивы архитектурных решений.
- [Desktop window lifecycle](desktop-window-lifecycle.md) — обязательный
  протокол дочерних окон.
- [Testing](testing.md) — команды и native smoke-сценарии.
