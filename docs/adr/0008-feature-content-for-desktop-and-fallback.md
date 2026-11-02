# 0008. Один feature content для child window и fallback dialog

## Контекст

Flutter child engine не разделяет состояние с главным engine. Ранее часть
функций поддерживала два независимых UI: native child window и fallback dialog.
Из-за этого изменение одного пути не попадало в другой.

## Решение

Каждая функция, которая может открываться как дочернее desktop-окно, содержит
один `...Content` (и при необходимости `...FormContent`) и один
feature-specific ViewModel/operations-контракт. Native host и fallback dialog
только размещают этот content и создают одинаковый ViewModel с разными
operations-адаптерами:

- direct adapter вызывает use cases и UI settings в главном engine;
- IPC adapter вызывает coordinator в child engine.

Production открывает child windows только через `DesktopWindowCoordinator`.
Dialog является fallback для widget-тестов и сред без coordinator, а не вторым
production-маршрутом. Lifecycle, singleton policy, hide/reopen и cascade-close
остаются ответственностью coordinator и не переносятся в feature UI.

## Последствия

- feature UI не зависит от `desktop_multi_window` и IPC;
- отдельные features не объединяются в UI только из-за общей data-модели;
- новые изменения формы и валидации автоматически применяются в обоих host-ах;
- IPC adapter и direct adapter покрываются отдельными тестами.
