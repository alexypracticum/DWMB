# TODO

## Текущий статус: v0.4.0

### Приоритет 1: Критичные пробелы

- [x] CRUD для OntologyModel через UI
- [x] CRUD для EntityKind через UI
- [x] Синхронизация CRUD с сущностями
- [x] Мультиязычные переводы (ru/en)
- [x] REST API для kinds, fields, categories
- [x] Безопасность для GitHub (.env, .gitignore)

### Приоритет 2: Важные функции

- [x] Редактор связей в UI
  - [x] Список исходящих/входящих связей
  - [x] Модальное окно добавления связи
  - [x] Поиск сущности через AJAX
  - [x] Удаление связей
  - [ ] Выбор нескольких связей одновременно

- [ ] Импорт из внешних источников
  - [ ] Wikipedia API
  - [ ] MusicBrainz API
  - [ ] Автоматическое заполнение полей

- [ ] Rate limiting
  - [ ] Middleware для ограничения запросов
  - [ ] Конфигурация лимитов

- [x] Онтологии как сущности
  - [x] Типы ontology_model/ontology_template
  - [x] Конвертация данных
  - [x] Синхронизация CRUD

### Приоритет 3: Продвинутые функции

- [ ] Визуализация связей
  - [ ] D3.js / Cytoscape.js
  - [ ] Графовое представление
  - [ ] Фильтрация по типам

- [ ] AI: Автоматическая генерация связей
  - [ ] Анализ текста
  - [ ] Предложение связей
  - [ ] Автосоздание

- [ ] Плагины
  - [ ] Архитектура плагинов
  - [ ] Интерфейс подключения

### Приоритет 4: Инфраструктура

- [ ] Микросервисы
- [ ] GraphQL
- [ ] RLS (Row-Level Security)

### Исправления багов

- [x] Internal Server Error при /entities?kind=movie
- [x] Синхронизация схем kind ↔ template
- [x] Тип ENUM для language_preference
- [x] Потеря datetime в api_update_entity_field
- [x] FK violation при загрузке изображений
- [x] Дедупликация загрузок по хешу
- [x] Ключ poster_url → poster
- [x] Дублирование name="poster" в edit
- [x] UUID() → uuid.uuid4() в add-projection
- [x] Импорт EntityProjection/ProjectionState
- [x] Модель model_code → entity_code синхронизация
