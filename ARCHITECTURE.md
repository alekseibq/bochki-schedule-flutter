# Architecture

Проект использует простую слоистую структуру для vertical slice `participants`:

- `UI/View`: Flutter widgets только отображают состояние и вызывают команды ViewModel.
- `ViewModel`: `ChangeNotifier` хранит состояние экрана участников, вызывает use cases и преобразует ошибки в UI-friendly сообщения.
- `Domain/UseCases`: entity `Participant`, интерфейс `ParticipantsRepository` и use cases для list/create/update/delete. Бизнес-правила и validation живут здесь.
- `Repository`: data-слой реализует `ParticipantsRepository` и скрывает текущий способ хранения.
- `Data layer`: adapter поверх `ProjectDocumentRepository` читает и сохраняет участников в текущий JSON `ProjectDocument`.

Правила:

- widgets не работают напрямую с persistence, JSON, файлами или storage;
- business rules не живут в widgets;
- domain layer не зависит от Flutter UI;
- новый функционал лучше добавлять vertical slice-ами с явными границами UI -> ViewModel -> UseCases -> Repository -> Storage.
